@bootstrapParser
module rascal::checker::CheckWithConstraints

import IO;
import List;
import Set;
import Message;
import Map;
import Relation;
import ParseTree;
import Reflective;
import String;

import rascal::checker::ListUtils;
import rascal::checker::Types;
import rascal::checker::SubTypes;
import rascal::checker::SymbolTable;
import rascal::checker::Signature;
import rascal::checker::TypeRules;
import rascal::checker::Namespace;
import rascal::checker::TreeUtils;

import rascal::syntax::RascalRascal;

// TODO: the type checker should:
//   -- DONE: annotate expressions and statements with their type
//   -- DONE: infer types for untyped local variables
//   -- DONE: annotate patterns with their type
//   -- check type consistency for:
//           -- DONE: function calls
//           -- DONE: case patterns (i.e. for switch it should be the same as the expression that is switched on)
//           -- DONE: case rules (left-hand side equal to right-hand side
//           -- DONE: rewrite rules (idem)
//   -- filter ambiguous Rascal due to concrete syntax, by:
//          -- type-checking each alternative and filtering type incorrect ones
//          -- counting the size of concrete fragments and minimizing the number of characters in concrete fragments
//          -- comparing the chain rules at the top of fragments, and minimizing those
//          -- balancing left and right-hand side of rules and patterns with replacement by type equality
//   -- check additional static constraints
//          -- DONE: across ||, --> and <--> conditional composition, all pattern matches introduce the same set of variables 
//          -- PARTIAL: all variables have been both declared and initialized in all control flow paths UPDATE: currently
//			   checks to ensure declared, not yet checking to ensure initialized
//          -- switch either implements a default case, or deals with all declared alternatives
//
// More TODOs
//
// 1. [DONE: YES] Do we want to go back and assign the inferred types to names?
//
// 2. For statement types and (in general) blocks, how should we handle types assigned to the blocks? Currently, if
//     you have x = block, and block throws, x is undefined. If we want to continue allowing this we need to decide
//     on a type for x that is safe (i.e., would int x = 3; x = { throw "Help!"; 5; } be a type error or not?
//
// 3. Add solve for the reducer to determine the type -- uses a conservative value now, but can make this more precise
//
// 4. [DONE] Handle polymorphic type variables
//
// 5. Need to set up a large number of test cases!
//
// 6. Add checking for tags
//
// 7. Handle embedded TODOs below and in other files; these are generally less common type checking cases that we
//    still need to handle.
//
// 8. Do we allow interpolation in pattern strings? If so, what does this mean?
//
// 9. For constraints, need to define a "within" constraint for insert, append, etc -- i.e., constructs that
//    must be used inside another construct. This should allow us to link up the constraint to the surrounding
//    construct to get the type information we need to check it correctly.
//

private str getTypeString(Name n) {
    if ( hasRType(globalSymbolTable, n@\loc) )
        return "TYPE: " + prettyPrintType(getTypeForName(globalSymbolTable, convertName(n), n@\loc));
    else
        return "TYPE unavailable";
}
 
public Name setUpName(Name n) {
    if ( hasRType(globalSymbolTable, n@\loc) ) {
        n = n[@rtype = getTypeForName(globalSymbolTable, convertName(n), n@\loc)]; 
    }
    n = n[@doc = getTypeString(n)];
    return n;
}

//
// Gather type constraints over the tree. Note that this pass doesn't update the
// tree, since we need to solve the constraints first (including solving binds
// introduced by patterns and assignments).
//
public Tree check(Tree t) {
    return visit(t) {
        case `<Expression e>` : {
            // Now, check the expression, using the updated value above
            RType expType = checkExpression(e); 

            if (`<Expression e1> ( <{Expression ","}* el> )` := e && !isFailType(expType)) {
                e = updateOverloadedCall(e,expType);
            }

            // Tag the type of it expressions
            if (e@\loc in globalSymbolTable.itBinder) 
                updateInferredTypeMappings(globalSymbolTable.itBinder[e@\loc], expType);

            // Handle types for functions and constructors, which are the function or constructor
            // type; we need to extract the return/result type and save the function or constructor
            // type for later use
            if (`<Expression e1> ( <{Expression ","}* el> )` := e) {
                if (isConstructorType(expType)) {
                    insert e[@rtype = getConstructorResultType(expType)][@fctype = expType];
                } else if (isFunctionType(expType)) { 
                    insert e[@rtype = getFunctionReturnType(expType)][@fctype = expType];
                } else {
                    insert e[@rtype = expType]; // Probably a failure type
                }
            } else {
                insert e[@rtype = expType];
            } 
        }
        
        case `<Pattern p>` : {
            RType patType = checkPattern(p);

            if (`<Pattern p1> ( <{Pattern ","}* pl> )` := p && !isFailType(patType)) {
                p = updateOverloadedCall(p,patType);
            }

            if (`<Pattern p1> ( <{Pattern ","}* pl> )` := p) {
                if (isConstructorType(patType)) {
                    insert p[@rtype = getConstructorResultType(patType)][@fctype = patType];
                } else {
                    insert p[@rtype = patType]; // Probably a failure type
                }
            } else {
                insert(p[@rtype = patType]);
	        }    
        }
        
        case `<Statement s>` => s[@rtype = checkStatement(s)]

        case `<Assignable a>` => a[@rtype = checkAssignable(a)]

        case `<Catch c>` => c[@rtype = checkCatch(c)]

        case `<DataTarget dt>` => dt[@rtype = checkDataTarget(dt)]

        case `<Target t>` => t[@rtype = checkTarget(t)]

        case `<PatternWithAction pwa>` => pwa[@rtype = checkPatternWithAction(pwa)]

        case `<Visit v>` => v[@rtype = checkVisit(v)]

        case `<Label l>` => l[@rtype = checkLabel(l)]

        case `<Variable v>` => v[@rtype = checkVariable(v)]

        case `<FunctionBody fb>` => fb[@rtype = checkFunctionBody(fb)]

        case `<Toplevel t>` => t[@rtype = checkToplevel(t)]

        case `<Body b>` => b[@rtype = checkModuleBody(b)]

        case `<Module m>` => m[@rtype = checkModule(m)]
        
        case `<Case c>` => c[@rtype = checkCase(c)]

        case `<StringTemplate s>` => s[@rtype = checkStringTemplate(s)]
    } 
}

private set[RType] gatherFailTypes(set[RType] checkTypes) {
	return { ct | ct <- checkTypes, isFailType(ct) };
}

private bool checkForFail(set[RType] checkTypes) {
	return size(gatherFailTypes(checkTypes)) > 0;
}

private RType propagateFailOr(set[RType] checkTypes, RType newType) {
	set[RType] ts = gatherFailTypes(checkTypes);
	if (size(ts) > 0) 
		return collapseFailTypes(ts);
	else
		return newType;
}

//
// To check a module, we propagate up any errors in the module body, as well as adding any errors
// determined during the building of the symbol table. These are stored in the scopeErrorMap of
// the symbol table, keyed on the location of the module.
//
public RType checkModule(Module m) {
	if ((Module) `<Header h> <Body b>` := m) {
		set[str] scopeErrors = (m@\loc in globalSymbolTable.scopeErrorMap) ? symbolTable.scopeErrorMap[m@\loc] : { };
	 	if (size(scopeErrors) > 0) {
	 		return collapseFailTypes({ makeFailType(s,m@\loc) | s <- scopeErrors } + b@rtype);
	 	} else {
	 		return b@rtype;
	 	}
	}
	throw "checkModule: unexpected module syntax";
}

//
// Since checking is a bottom-up process, checking the module body just consists of propagating 
// any errors that have occured inside the module body up.
//
public RType checkModuleBody(Body b) {
	set[RType] modItemTypes = { };
	if ((Body)`<Toplevel* ts>` := b) modItemTypes = { t@rtype | t <- ts, ( (t@rtype)?) };
	if (size(modItemTypes) > 0 && checkForFail(modItemTypes)) return collapseFailTypes(modItemTypes);
	return makeVoidType();
}

//
// Checking the toplevel items involves propagating up any failures detected in the items.
//
public RType checkToplevel(Toplevel t) {
	switch(t) {
		// Variable declaration
		case (Toplevel) `<Tags tgs> <Visibility v> <Type typ> <{Variable ","}+ vs> ;` : { 
			return checkVarItems(tgs, v, typ, vs);
		}

		// Abstract (i.e., without a body) function declaration
		case (Toplevel) `<Tags tgs> <Visibility v> <Signature s> ;` : { 
			return checkAbstractFunction(tgs, v, s);
		}
 
		// Concrete (i.e., with a body) function declaration
		case (Toplevel) `<Tags tgs> <Visibility v> <Signature s> <FunctionBody fb>` : {
			return checkFunction(tgs, v, s, fb);
		}
			
		// Annotation declaration
		case (Toplevel) `<Tags tgs> <Visibility v> anno <Type typ> <Type otyp> @ <Name n> ;` : {
			return checkAnnotationDeclaration(tgs, v, typ, otyp, n);
		}
								
		// Tag declaration
		case (Toplevel) `<Tags tgs> <Visibility v> tag <Kind k> <Name n> on <{Type ","}+ typs> ;` : {
			return checkTagDeclaration(tgs, v, k, n, typs);
		}
			
		// Rule declaration
		case (Toplevel) `<Tags tgs> rule <Name n> <PatternWithAction pwa> ;` : {
			return checkRuleDeclaration(tgs, n, pwa);
		}
			
		// Test
		case (Toplevel) `<Test tst> ;` : {
			return checkTestDeclaration(tst);
		}
							
		// ADT without variants
		case (Toplevel) `<Tags tgs> <Visibility v> data <UserType typ> ;` : {
			return checkAbstractADT(tgs, v, typ);
		}
			
		// ADT with variants
		case (Toplevel) `<Tags tgs> <Visibility v> data <UserType typ> = <{Variant "|"}+ vars> ;` : {
			return checkADT(tgs, v, typ, vars);
		}

		// Alias
		case (Toplevel) `<Tags tgs> <Visibility v> alias <UserType typ> = <Type btyp> ;` : {
			return checkAlias(tgs, v, typ, btyp);
		}
							
		// View
		case (Toplevel) `<Tags tgs> <Visibility v> view <Name n> <: <Name sn> = <{Alternative "|"}+ alts> ;` : {
			return checkView(tgs, v, n, sn, alts);
		}
	}
	throw "checkToplevel: Unhandled toplevel item <t>";
}

//
// checkVarItems checks for failure types assigned to the variables, either returning
// these or a void type. Failures would come from duplicate use of a variable name
// or other possible scoping errors as well as from errors in the init expression.
//
public RType checkVarItems(Tags ts, Visibility vis, Type t, {Variable ","}+ vs) {
	set[RType] varTypes = { v@rtype | v <- vs };
	if (checkForFail( varTypes )) return collapseFailTypes( varTypes );
	return makeVoidType();
}

//
// checkVariable checks the correctness of the assignment where the variable is of the
// form n = e and also returns either a failure type of the type assigned to the name.
//
public RType checkVariable(Variable v) {
	switch(v) {
		case (Variable) `<Name n>` : {
			return getTypeForName(globalSymbolTable, convertName(n), n@\loc);
		}
		
		case (Variable) `<Name n> = <Expression e>` : {
		        // NOTE: The only variable declarations are typed variable declarations. Declarations
			// of the form x = 5 are assignables. So, here we want to make sure the assignment
			// doesn't cause a failure, but beyond that we just return the type of the name,
			// which should be the same as, or a supertype of, the expression.
			RType nType = getTypeForName(globalSymbolTable, convertName(n), n@\loc);
			if (checkForFail( { nType, e@rtype })) return collapseFailTypes({ nType, e@rtype });
			if (subtypeOf(e@rtype, nType)) return nType;
			return makeFailType("Type of <e>, <prettyPrintType(e@rtype)>, must be a subtype of the type of <n>, <prettyPrintType(nType)>", v@\loc);
		}
	}
	throw "checkVariable: unhandled variable case <v>";
}

//
// The type of a function is fail if the parameters have fail types, else it is based on the
// return and parameter types assigned to function name n.
//
// TODO: Add checking of throws, if needed (for instance, to make sure type names exist -- this
// may already be done in Namespace when building the symbol table)
//
public RType checkAbstractFunction(Tags ts, Visibility v, Signature s) {
	switch(s) {
		case `<Type t> <FunctionModifiers ns> <Name n> <Parameters ps>` : 
			return checkForFail(toSet(getParameterTypes(ps))) ? collapseFailTypes(toSet(getParameterTypes(ps))) : getTypeForName(globalSymbolTable, convertName(n), n@\loc);
		case `<Type t> <FunctionModifiers ns> <Name n> <Parameters ps> throws <{Type ","}+ thrs> ` : 
			return checkForFail(toSet(getParameterTypes(ps))) ? collapseFailTypes(toSet(getParameterTypes(ps))) : getTypeForName(globalSymbolTable, convertName(n), n@\loc);
	}
	throw "checkAbstractFunction: unhandled signature <s>";
}

//
// The type of a function is fail if the body or parameters have fail types, else it is
// based on the return and parameter types (and is already assigned to n, the function name).
//
// TODO: Add checking of throws, if needed (for instance, to make sure type names exist -- this
// may already be done in Namespace when building the symbol table)
//
public RType checkFunction(Tags ts, Visibility v, Signature s, FunctionBody b) {
	switch(s) {
		case `<Type t> <FunctionModifiers ns> <Name n> <Parameters ps>` : 
			return checkForFail(toSet(getParameterTypes(ps)) + b@rtype) ? collapseFailTypes(toSet(getParameterTypes(ps)) + b@rtype) : getTypeForName(globalSymbolTable, convertName(n), n@\loc);
		case `<Type t> <FunctionModifiers ns> <Name n> <Parameters ps> throws <{Type ","}+ thrs> ` : 
			return checkForFail(toSet(getParameterTypes(ps)) + b@rtype) ? collapseFailTypes(toSet(getParameterTypes(ps)) + b@rtype) : getTypeForName(globalSymbolTable, convertName(n), n@\loc);
	}
	throw "checkFunction: unhandled signature <s>";
}

//
// The type of the function body is a failure if any of the statements is a failure type,
// else it is just void. Function bodies don't have types based on the computed results.
//
public RType checkFunctionBody(FunctionBody fb) {
	if (`{ <Statement* ss> }` := fb) {
		set[RType] bodyTypes = { getInternalStatementType(s@rtype) | s <- ss };
		if (checkForFail(bodyTypes)) return collapseFailTypes(bodyTypes);
		return makeVoidType();
	}
	throw "checkFunctionBody: Unexpected syntax for function body <fb>";
}

//
// If the name has a type annotation, return it, else just return a void type. A type
// on the name would most likely indicate a scope error.
//
public RType checkAnnotationDeclaration(Tags t, Visibility v, Type t, Type ot, Name n) {
	if ( hasRType(globalSymbolTable,n@\loc) ) return getTypeForName(globalSymbolTable, convertName(n), n@\loc); else return makeVoidType();
}

//
// If the name has a type annotation, return it, else just return a void type. A type
// on the name would most likely indicate a scope error.
//
public RType checkTagDeclaration(Tags t, Visibility v, Kind k, Name n, {Type ","}+ ts) {
	if ( hasRType(globalSymbolTable,n@\loc) ) return getTypeForName(globalSymbolTable, convertName(n), n@\loc); else return makeVoidType();
}
	
//
// The type of the rule is the failure type on the name of pattern if either is a
// failure type, else it is the type of the pattern (i.e., the type of the term
// rewritten by the rule).
//							
public RType checkRuleDeclaration(Tags t, Name n, PatternWithAction p) {
	if ( hasRType(globalSymbolTable, n@\loc )) {
		if (checkForFail({ getTypeForName(globalSymbolTable, convertName(n), n@\loc), p@rtype })) 
                        return collapseFailTypes({getTypeForName(globalSymbolTable, convertName(n), n@\loc), p@rtype});
	} 
	return p@rtype;
}

//
// The type of the test is either a failure type, if the expression has a failure type, or void.
//
public RType checkTestDeclaration(Test t) {
        if (`<Tags tgs> test <Expression exp>` := t || `<Tags tgs> test <Expression exp> : <StringLiteral sl>` := t) {
	        if (isFailType(exp@rtype)) return exp@rtype; else return makeVoidType();
        }
        throw "Unexpected syntax for test: <t>";
}

//
// The only possible error is on the ADT name itself, so check that for failures.
//
public RType checkAbstractADT(Tags ts, Visibility v, UserType adtType) {
	Name adtn = getUserTypeRawName(adtType);
	if (hasRType(globalSymbolTable, adtn@\loc))
		return getTypeForName(globalSymbolTable, convertName(adtn), adtn@\loc);
	return makeVoidType();
}

//
// Propagate upwards any errors registered on the ADT name or on the variants.
//
public RType checkADT(Tags ts, Visibility v, UserType adtType, {Variant "|"}+ vars) {
	set[RType] adtTypes = { };

	Name adtn = getUserTypeRawName(adtType);
	if (hasRType(globalSymbolTable,adtn@\loc))
		adtTypes = adtTypes + getTypeForName(globalSymbolTable, convertName(adtn), adtn@\loc);

	for (`<Name n> ( <{TypeArg ","}* args> )` <- vars) {
		if (hasRType(globalSymbolTable, n@\loc))
			adtTypes = adtTypes + getTypeForName(globalSymbolTable, convertName(n), n@\loc);
	}

	if (checkForFail(adtTypes)) return collapseFailTypes(adtTypes);
	return makeVoidType();
}

//
// Return any type registered on the alias name, else return a void type. Types on the name
// most likely represent a scoping error.
//
public RType checkAlias(Tags ts, Visibility v, UserType aliasType, Type aliasedType) {
	Name aliasRawName = getUserTypeRawName(aliasType);
	if (hasRType(globalSymbolTable, aliasRawName@\loc)) {
		return getTypeForName(globalSymbolTable, convertName(aliasRawName), aliasRawName@\loc);
	}
	return makeVoidType();
}

//
// TODO: Implement once views are available in Rascal
//
public SymbolTable checkView(Tags ts, Visibility v, Name n, Name sn, {Alternative "|"}+ alts) {
	throw "checkView not yet implemented";
}

//
// START OF STATEMENT CHECKING LOGIC
//

//
// Check the solve statement
//
public Constraints checkSolveStatement(Constraints cs, Statement sp, {QualifiedName ","}+ vars, Bound b, Statement body) {
        <cs, l1> = makeFreshTypes(cs,1); t1 = l1[0]; 
	Constraint c1 = makeIsTypeConstraint(sp,t1);
	Constraint c2 = makeIsTypeConstraint(t1,makeStatementType(makeVoidType())); // The type of the solve statement is void, i.e., it is not assignable
	cs.constraints = cs.constraints + { c1, c2 };

	for (v <- vars) {
	        <cs, l2> = makeFreshTypes(cs,1); t3 = l2[0];
		Constraint c3 = makeIsTypeConstraint(v,t3);
		Constraint c4 = DefinedBy(t3,v@nameIds);
		cs.constraints = cs.constraints + { c3, c4 };
	}

	if (`; <Expression e>` := b) {
	        <cs, l3> = makeFreshTypes(cs,1); t5 = l3[1];
		Constraint c6 = makeIsTypeConstraint(e,t5);
		Constraint c7 = makeIsTypeConstraint(t5,makeIntType());
		cs.constraints = cs.constraints + { c6, c7 };
	}

	return cs;
}

//
// Check the for statement
//
public Constraints checkForStatement(Constraints cs, Statement sp, Label l, {Expression ","}+ exps, Statement body) {
        <cs, l1> = makeFreshTypes(cs,1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(sp,t1);
	Constraint c2 = makeIsTypeConstraint(t1,makeStatementType(makeListType(makeVoidType()))); // The best we can get for the body, the loop may not execute
	cs.constraints = cs.constraints + { c1, c2 };

	for (e <- exps) {
	        <cs, l2> = makeFreshTypes(cs,1); t2 = l2[0];
		Constraint c3 = makeIsTypeConstraint(e,t2);
		Constraint c4 = makeIsTypeConstraint(t2,makeBoolType());
		cs.constraints = cs.constraints + { c3, c4 };
	}

	return cs;
}  

//
// Check the while statement
//
public Constraints checkWhileStatement(Constraints cs, Statement sp, Label l, {Expression ","}+ exps, Statement body) {
        <cs, l1> = makeFreshTypes(cs,1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(sp,t1);
	Constraint c2 = makeIsTypeConstraint(t1,makeStatementType(makeListType(makeVoidType()))); // The best we can get for the body, the loop may not execute
	cs.constraints = cs.constraints + { c1, c2 };

	for (e <- exps) {
	        <cs, l2> = makeFreshTypes(cs,1); t2 = l2[0];
		Constraint c3 = makeIsTypeConstraint(e,t2);
		Constraint c4 = makeIsTypeConstraint(t2,makeBoolType());
		cs.constraints = cs.constraints + { c3, c4 };
	}

	return cs;
}

//
// Check the do while statement
//
public Constraints checkDoWhileStatement(Constraints cs, Statement sp, Label l, Statement body, Expression e) {
        <cs, l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1];
	Constraint c1 = makeIsTypeConstraint(sp,t1);
	Constraint c2 = makeIsTypeConstraint(t1,makeStatementType(makeListType(makeVoidType()))); // The best we can get for the body, the loop may not execute
	Constraint c3 = makeIsTypeConstraint(e,t2);
	Constraint c4 = makeIsTypeConstraint(t2,makeBoolType());
	cs.constraints = cs.constraints + { c1, c2, c3, c4 };
	return cs;
}

//
// Check the if/then/else statement.
//
//    e1 : bool, ..., en : bool,  tb : stmt[t1], tf : stmt[t2]
// -------------------------------------------------------------
//    if (e1,...,en) then tb else tf : stmt[lub(tb,tf)]
//
public Constraints checkIfThenElseStatement(Constraints cs, Statement sp, Label l, {Expression ","}+ exps, Statement trueBody, Statement falseBody) {
    <cs, l1> = makeFreshTypes(cs,6); t1 = l1[0]; t2 = l1[1]; t3 = l1[2]; t4 = l1[3]; t5 = l1[4]; t6 = l1[5];

    Constraint c1 = makeIsTypeConstraint(sp, t1);
    Constraint c2 = makeIsTypeConstraint(trueBody, t2);
    Constraint c3 = makeIsTypeConstraint(falseBody, t4);

    // Each branch should be of type stmt[t], where t is an arbitrary type
    Constraint c4 = makeIsTypeConstraint(t2,makeStatementType(t3));
    Constraint c5 = makeIsTypeConstraint(t4,makeStatementType(t5));
    
    // The type of the statement is a statement type based on the lub of the branch types
    Constraint c6 = LubOf([t3,t5],t6);
    Constraint c7 = makeIsTypeConstraint(t1, makeStatementType(t6));
    
    cs = addConstraints(cs, { c1, c2, c3, c4, c5, c6, c7 });

	for (e <- exps) {
        <cs, l2> = makeFreshTypes(cs,1); t7 = l2[0];
        
        // Each expression should type as bool
        Constraint c8 = makeIsTypeConstraint(e,t7);
        Constraint c9 = makeIsTypeConstraint(t7,makeBoolType());
        
        cs = addConstraints(cs, { c8, c9 });
	}

    return cs;
}

//
// Check the if/then statement.
//
//    e1 : bool, ..., en : bool,  tb : stmt[t1]
// -----------------------------------------------
//    if (e1,...,en) then tb : stmt[void]
//
public Constraints checkIfThenStatement(Constraints cs, Statement sp, Label l, {Expression ","}+ exps, Statement trueBody) {
    <cs, l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
    
    // The overall statement type is stmt[void], since we don't know statically if the true branch is taken.
    Constraint c1 = makeIsTypeConstraint(sp, t1);
    Constraint c2 = makeIsTypeConstraint(t1, makeStatementType(makeVoidType()));

    // The true body should be some statement type.
    Constraint c3 = makeIsTypeConstraint(trueBody, t2);
    Constraint c4 = makeIsTypeConstraint(t2,makeStatementType(t3));
    
    cs = addConstraints(cs, { c1, c2, c3, c4 });

    for (e <- exps) {
        <cs, l2> = makeFreshTypes(cs,1); t4 = l2[0];

        // Each expression should type as bool
        Constraint c5 = makeIsTypeConstraint(e,t4);
        Constraint c6 = makeIsTypeConstraint(t4,makeBoolType());

        cs = addConstraints(cs, { c5, c6 });
    }

    return cs;
}

//
// Calculate the type of a switch statement.
//
public Constraints checkSwitchStatement (Constraints cs, Statement sp, Label l, Expression e, Case+ cases) {
    <cs, l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
    Constraint c1 = makeIsTypeConstraint(sp, t1);
    Constraint c2 = makeIsTypeConstraint(e, t2);
    Constraint c3 = makeIsTypeConstraint(t2, makeBoolType());
    cs = addConstraints(cs, { c1, c2, c3 });

    list[RType] caseTypes = [ ];
    for (c <- cases) {
        <cs, l2> = makeFreshTypes(cs,1); t4 = l2[0];
        Constraint c4 = makeIsTypeConstraint(c,t4);
        cs = addConstraint(cs,c4);
        caseTypes += t4;
    }

    Constraint c5 = LubOf(caseTypes,makeStatementType(t1));
    cs = addConstraint(cs,c5);
    return cs;
} 

//
// Calculate the type of the visit statement.
//
// TODO: Fill in type rule
//
public Constraints checkVisitStatement(Constraints cs, Statement sp, Label l, Visit v) {
    <cs, l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1];
    Constraint c1 = makeIsTypeConstraint(sp,t1);
    Constraint c2 = makeIsTypeConstraint(v,t2);
    Constraint c3 = makeIsTypeConstraint(t1,makeStatementType(t2));
    cs = addConstraints(cs, { c1, c2, c3 });
    return cs;
}			

//
// Check the expression statement
//
//            e : t1
// --------------------------------------
//           e ; : stmt[t1]
//
public Constraints checkExpressionStatement(Constraints cs, Statement sp, Expression e) {
    <cs, l1> = makeFreshTypes(cs, 2); t1 = l1[0]; t2 = l1[1];
    Constraint c1 = makeIsTypeConstraint(sp, t1);
    Constraint c2 = makeIsTypeConstraint(e, t2);
    Constraint c3 = makeIsTypeConstraint(t1, makeStatementType(t2));
    cs = addConstraints(cs, { c1, c2, c3 });
    return cs;
}

public Constraint makeIsTypeConstraint(Tree t, RType rt) {
    Constraint c = makeIsTypeConstraint(t,rt);
    return c[@at=t@\loc];
}

public Constraint makeIsTypeConstraint(RType rt1, RType rt2) {
    Constraint c = makeIsTypeConstraint(rt1,rt2);
    return c;
}

public Constraints addConstraints(Constraints cs, set[Constraint] toAdd) {
    cs.constraints = cs.constraints + toAdd;
    return cs;
}

public Constraints addConstraints(Constraints cs, Constraint toAdd) {
    cs.constraints = cs.constraints + toAdd;
    return cs;
}


//
// Type checks the various cases for assignment statements. Note that this assumes that the
// assignable and the statement have themselves already been checked and assigned types.
//
public RType checkAssignmentStatement(Statement sp, Assignable a, Assignment op, Statement s) {
	RType stmtType = getInternalStatementType(s@rtype);

	if (checkForFail({ a@rtype, stmtType })) {
		return makeStatementType(collapseFailTypes({ a@rtype, getInternalStatementType(s@rtype) }));
	}

	RType partType = getPartType(a@rtype);
	RType wholeType = getWholeType(a@rtype);

	// Special case: name += value, where name is a list/set/map of void and value is a list/set/map or
	// an element.
	// TODO: This is a terrible hack, and needs to be removed, but at least it lets things pass the checker
	// that otherwise would generate noise (or require explicit type declarations).
	if (isListType(wholeType) && isVoidType(getListElementType(wholeType)) && RAAddition() := convertAssignmentOp(op)) {
	        if (isListType(stmtType)) {
		        return makeStatementType(bindInferredTypesToAssignable(stmtType, a));
		} else {
		        return makeStatementType(bindInferredTypesToAssignable(makeListType(stmtType), a));
		}
	} else if (isSetType(wholeType) && isVoidType(getSetElementType(wholeType)) && RAAddition() := convertAssignmentOp(op)) {
	        if (isSetType(stmtType)) {
		        return makeStatementType(bindInferredTypesToAssignable(stmtType, a));
		} else {
		        return makeStatementType(bindInferredTypesToAssignable(makeSetType(stmtType), a));
		}
	} else if (isMapType(wholeType) && isVoidType(getMapDomainType(wholeType)) && isVoidType(getMapRangeType(wholeType)) && RAAddition() := convertAssignmentOp(op)) {
	        if (isMapType(stmtType)) {
		        return makeStatementType(bindInferredTypesToAssignable(stmtType, a));
		}
	}

	// This works over two cases. For both = and ?=, the variable(s) on the left can be inference vars.
	// Otherwise, they cannot, since we are doing some kind of calculation using them and, therefore,
	// they must have been initialized (and assigned types) earlier.
	if (!aOpHasOp(convertAssignmentOp(op))) {
	        return makeStatementType(bindInferredTypesToAssignable(stmtType, a));
	} else {
		RType actualAssignedType = getAssignmentType(partType, stmtType, convertAssignmentOp(op), sp@\loc);
		if (isFailType(actualAssignedType)) {
			return makeStatementType(actualAssignedType);
		} else {
			if (subtypeOf(actualAssignedType, partType)) {
				return makeStatementType(wholeType);
			} else {
				return makeStatementType(makeFailType("Invalid assignment, the type being assigned, <prettyPrintType(stmtType)>, must be a subtype of the type being assigned into, <prettyPrintType(partType)>",sp@\loc));
			}
		}
	}
}

//
// An assert without a message should have expression type bool.
//
public Constraints checkAssertStatement(Constraints cs, Statement sp, Expression e) {
        <cs, l1> = makeFreshTypes(2); t1 = l1[0]; t2 = l1[1];
	Constraint c1 = makeIsTypeConstraint(sp, t1);
	Constraint c2 = makeIsTypeConstraint(e, t2);
	Constraint c3 = makeIsTypeConstraint(t2, makeBoolType());
	Constraint c4 = makeIsTypeConstraint(t1, makeStatementType(makeVoidType()));
	cs.constraints = cs.constraints + { c1, c2, c3, c4 };
	return cs;
}

//
// An assert with a message should have expression types bool : str .
//
public Constraints checkAssertWithMessageStatement(Constraints cs, Statement sp, Expression e, Expression em) {
        <cs, l1> = makeFreshTypes(3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
	Constraint c1 = makeIsTypeConstraint(sp, t1);
	Constraint c2 = makeIsTypeConstraint(e, t2);
	Constraint c3 = makeIsTypeConstraint(t2, makeBoolType());
	Constraint c4 = makeIsTypeConstraint(t1, makeStatementType(makeVoidType()));
	Constraint c5 = makeIsTypeConstraint(em, t3);
	Constraint c6 = makeIsTypeConstraint(t3, makeStrType());
	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5, c6 };
	return cs;
}

//
// Checking the return statement requires checking to ensure that the returned type is the same
// as the type of the function. We could do that at the function level, using a visitor (like we
// do to check part of the visit), but do it this way instead since it should be faster, at
// the expense of maintaining additional data structures.
//
public Constraints checkReturnStatement(Constraints cs, Statement sp, Statement b) {
	RType retType = getFunctionReturnType(globalSymbolTable.returnTypeMap[sp@\loc]);
	<cs, l1> = makeFreshTypes(3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
	Constraint c1 = makeIsTypeConstraint(sp, t1);
	Constraint c2 = makeIsTypeConstraint(b,t2);
	Constraint c3 = makeIsTypeConstraint(t2,makeStatementType(t3));
	Constraint c4 = makeIsTypeConstraint(t1,t2);
	Constraint c5 = SubtypeOf(t3,retType);
	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5 };
	return cs;	
}

//
// Checking a local function statement just involves propagating any failures or, if there are no failures,
// returning the type already assigned (in the scope generation) to the name.
//
public Constraints checkLocalFunctionStatement(Constraints cs, Statement sp, Tags ts, Visibility v, Signature sig, FunctionBody fb) {
        <cs, l1> = makeFreshTypes(1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(sp, t1);
	Constraint c2 = makeIsTypeConstraint(t1, makeStatementType(makeVoidType()));
	cs.constraints = cs.constraints + { c1, c2 };

        return cs; // TODO: See if we need to do more than this, any actual errors will be computed using the internally-gathered constraints
}

//
// Typecheck a try/catch statement. Currently the behavior of the interpreter returns the value of the body if 
// the body exits correctly, or an undefined value if a throw occurs in the body. For now, type this as void,
// but TODO: check to see if we want to maintain this behavior.
//
public Constraints checkTryCatchStatement(Constraints cs, Statement sp, Statement body, Catch+ catches) {
        <cs, l1> = makeFreshTypes(1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(sp, t1);
	Constraint c2 = makeIsTypeConstraint(t1, makeStatementType(makeVoidType()));
	cs.constraints = cs.constraints + { c1, c2 };
	return cs;
}		

//
// Typecheck a try/catch/finally statement. See the comments for the try/catch statement for added details.
//
public Constraints checkTryCatchFinallyStatement(Constraints cs, Statement sp, Statement body, Catch+ catches, Statement fBody) {
        <cs, l1> = makeFreshTypes(1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(sp, t1);
	Constraint c2 = makeIsTypeConstraint(t1, makeStatementType(makeVoidType()));
	cs.constraints = cs.constraints + { c1, c2 };
	return cs;
}		

// Type check a block of statements. The result is either statement type containing a failure type, in cases where
// the label or one of the statements is a failure, or a statement type containing the internal type of the last
// statement in the block. For instance, if the last statement in the block is 3; the block would have type int.
public Constraints checkBlockStatement(Constraints cs, Statement sp, Label l, Statement+ bs) {
        <cs, l1> = makeFreshTypes(1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(sp, t1);
	cs.constraints = cs.constraints + { c1 };

	list[RType] blockTypes = [ ];

	for (s <- bs) {
	        <cs, l2> = makeFreshTypes(2); t2 = l2[0]; t3 = l2[1];
		Constraint c2 = makeIsTypeConstraint(s, t2);
		Constraint c3 = makeIsTypeConstraint(t2, makeStatementType(t3));
		blockTypes += t2;
		cs.constraints = cs.constraints + { c2, c3 };
	}

	Constraint c4 = makeIsTypeConstraint(t1, blockTypes[size(blockTypes)-1]);
	cs.constraints = cs.constraints +  { c4 };

	return cs;		
} 

//
// Check the empty statement
//
// --------------------------------------
//           ; : stmt[void]
//
public Constraints checkEmptyStatement(Constraints cs, Statement sp) {
        <cs, l1> = makeFreshTypes(cs, 1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(sp, t1);
	Constraint c2 = makeIsTypeConstraint(t1, makeStatementType(makeVoidType()));
	cs.constraints = cs.constraints + { c1, c2 };
	return cs;
}

// Typecheck all statements. This is a large switch/case over all the statement syntax, calling out to smaller functions
// where needed. The resulting type is an RStatementType containing the type of the computation
public Constraints checkStatement(Constraints cs, Statement s) {
	switch(s) {
		case `solve (<{QualifiedName ","}+ vs> <Bound b>) <Statement sb>` : {
			return checkSolveStatement(cs,s,vs,b,sb);
		}

		case `<Label l> for (<{Expression ","}+ es>) <Statement b>` : {
			return checkForStatement(cs,s,l,es,b);
		}

		case `<Label l> while (<{Expression ","}+ es>) <Statement b>` : {
			return checkWhileStatement(cs,s,l,es,b);
		}
		
		case `<Label l> do <Statement b> while (<Expression e>);` : {
			return checkDoWhileStatement(cs,s,l,b,e);
		}

		case `<Label l> if (<{Expression ","}+ es>) <Statement bt> else <Statement bf>` : {
			return checkIfThenElseStatement(cs,s,l,es,bt,bf);
		}

		case `<Label l> if (<{Expression ","}+ es>) <Statement bt>` : {
			return checkIfThenStatement(cs,s,l,es,bt);
		}

		case `<Label l> switch (<Expression e>) { <Case+ cs> }` : {
			return checkSwitchStatement(cs,s,l,e,cs);
		}

		case (Statement)`<Label l> <Visit v>` : {
			return checkVisitStatement(cs,s,l,v);
		}

		case `<Expression e> ;` : {
		        return checkExpressionStatement(cs,s,e);
		}

		case `<Assignable a> <Assignment op> <Statement b>` : {
			return checkAssignmentStatement(cs,s,a,op,b);
		}
		
		case `assert <Expression e> ;` : {
			return checkAssertStatement(cs,s,e);
		}

		case `assert <Expression e> : <Expression em> ;` : {
			return checkAssertWithMessageStatement(cs,s,e,em);
		}
		
		case `return <Statement b>` : {
			return checkReturnStatement(cs,s,b);
		}
		
		// TODO: Need to add RuntimeException to a default "type store" so we can use it
		// TODO: Modify to properly check the type of b; should be a subtype of RuntimeException
		// TODO: Fix This!
		case `throw <Statement b>` : {
			RType rt = b@rtype;
			return rt;
		}

		// TODO: Need to verify that statement has same type as current subject in visit or rewrite rule
		// TODO: Fix This!
		case `insert <DataTarget dt> <Statement b>` : {
			RType st = getInternalStatementType(b@rtype);
			RType rt = checkForFail({ dt@rtype, st }) ? makeStatementType(collapseFailTypes({ dt@rtype, st })) : b@rtype;
			return rt;
		}
		
		// TODO: Fix This!
		case `append <DataTarget dt> <Statement b>` : {
			RType st = getInternalStatementType(b@rtype);
			RType rt = checkForFail({ dt@rtype, st }) ? makeStatementType(collapseFailTypes({ dt@rtype, st })) : b@rtype;
			return rt;
		}
		
		case (Statement) `<Tags ts> <Visibility v> <Signature sig> <FunctionBody fb>` : {
			return checkLocalFunctionStatement(cs,s,ts,v,sig,fb);
		}
		
		case (Statement) `<Type t> <{Variable ","}+ vs> ;` : {
			return checkLocalVarItems(cs,s, vs);
		}
		
		// TODO: Handle the dynamic part of dynamic vars		
		case (Statement) `dynamic <Type t> <{Variable ","}+ vs> ;` : {
			return checkLocalVarItems(cs,s,vs);
		}
		
		// TODO: Fix This!
		case `break <Target t> ;` : {
			return (checkForFail({ t@rtype })) ? makeStatementType(collapseFailTypes({ t@rtype })) : makeStatementType(makeVoidType());
		}
		
		// TODO: Fix This!
		case `fail <Target t> ;` : {
			return  (checkForFail({ t@rtype })) ? makeStatementType(collapseFailTypes({ t@rtype })) : makeStatementType(makeVoidType());
		}
		
		// TODO: Fix This!
		case `continue <Target t> ;` : {
			return (checkForFail({ t@rtype })) ? makeStatementType(collapseFailTypes({ t@rtype })) : makeStatementType(makeVoidType());
		}
		
		case `try <Statement b> <Catch+ cs>` : {
			return checkTryCatchStatement(cs,s,b,cs);
		}

		case `try <Statement b> <Catch+ cs> finally <Statement bf>` : {
			return checkTryCatchFinallyStatement(cs,s,b,cs,bf);
		}
		
		case `<Label l> { <Statement+ bs> }` : {
			return checkBlockStatement(cs,s,l,bs);
		}
		
		case `;` : {
			return checkEmptyStatement(cs,s);
		}
	}
	
	throw "Unhandled type checking case in checkStatement for statement <s>";
}

//
// TODO: The expressions should all be of type type
//
private RType checkReifiedTypeExpression(Expression ep, Type t, {Expression ","}* el) {
	if (checkForFail({ e@rtype | e <- el }))
		return collapseFailTypes({ e@rtype | e <- el });
	else
		return makeReifiedType(convertType(t), [ e@rtype | e <- el ]);
}

//
// Check the call or tree expression, which can be either a function or constructor, a node
// constructor, or a location
//
// (FUNCTION OR CONSTRUCTOR)
//
//      f : tf1 x ... x tfn -> tr, e1 : t1, ... , en : tn, t1 <: tf1, ..., tn <: tfn 
// ----------------------------------------------------------------------------------------------
//               f (e1, ..., en) : tr
//
// (NODE)
//
//      f : str, e1 : t1, ... , en : tn, isValidNodeName(f)
// ----------------------------------------------------------------------------------------------
//               f (e1, ..., en) : node
//
// (LOCATION)
//
//      f : loc, e1 : int, e2 : int, e3 : tuple[int,int], e4 : tuple[int,int]
// ----------------------------------------------------------------------------------------------
//               f (e1, e2, e3, e4) : loc
//
public Constraints checkCallOrTreeExpression(Constraints cs, Expression ep, Expression ec, {Expression ","}* es) {
        <cs, l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1];
	Constraint c1 = makeIsTypeConstraint(ep,t1); // t1 is the overall type of the expression: call result, node, or loc
	Constraint c2 = makeIsTypeConstraint(ec,t2); // t2 is the type of the function, node string, or existing loc
	cs.constraints = cs.constraints + { c1, c2 };
	
	list[RType] params = [ ];
	for (e <- es) {
	        <cs, l2> = makeFreshTypes(cs,1); t3 = l2[0];
		Constraint c3 = makeIsTypeConstraint(e,t3); // t3 is the type of each parameter
		params += t3;
		cs.constraints = cs.constraints + { c3 };
	}

	<cs, l3> = makeFreshTypes(cs,1); t4 = l3[0]; 
	Constraint c4 = makeIsTypeConstraint(t2,CallableType(params,t4)); // t4 is the result type of the call; this should unify with t2's type
	Constraint c5 = makeIsTypeConstraint(t1,t4); // t4 should also be the ultimate type of executing the expression
	cs.constraints = cs.constraints + { c4, c5 };

	return cs;	
}

//
// Check the list expression
//
//      e1 : t1, ... , en : tn, tl = lub(t1, ..., tn)
// ------------------------------------------------------
//               [ e1, ..., en ] : list[tl]
//
// NOTE: This rule is simplified a bit, below we also need to handle splicing
//
public Constraints checkListExpression(Constraints cs, Expression ep, {Expression ","}* es) {
	<cs,l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1]; 
	Constraint c1 = makeIsTypeConstraint(ep,t1);
	Constraint c2 = makeIsTypeConstraint(t2,makeVoidType());
	cs.constraints = cs.constraints + { c1, c2 };

	list[RType] elements = [ t2 ]; 
	for (e <- es) { 
                <cs,l2> = makeFreshTypes(cs,1); t3 = l2[0]; 
		Constraint c3 = makeIsTypeConstraint(e,t3);
		cs.constraints = cs.constraints + { c3 };

		if (`[<{Expression ","}* el>]` !:= e) {
			Constraint c3a = SplicedListElement(t3);
			cs.constraints = cs.constraints + { c3a };
		}

		elements += t3;
        }

	<cs,l3> = makeFreshTypes(cs,1); t4 = l3[0]; 
	Constraint c4 = LubOf(elements,t4);
	Constraint c5 = makeIsTypeConstraint(t1, makeListType(t4));
	cs.constraints = cs.constraints + { c4, c5 };

	return cs;
}

//
// Check the set expression
//
//      e1 : t1, ... , en : tn, tl = lub(t1, ..., tn)
// ------------------------------------------------------
//               { e1, ..., en } : set[tl]
//
// NOTE: This rule is simplified a bit, below we also need to handle splicing
//
public Constraints checkSetExpression(Constraints cs, Expression ep, {Expression ","}* es) {
	<cs,l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1]; 
	Constraint c1 = makeIsTypeConstraint(ep,t1);
	Constraint c2 = makeIsTypeConstraint(t2,makeVoidType());
	cs.constraints = cs.constraints + { c1, c2 };

	list[RType] elements = [ t2 ]; 
	for (e <- es) { 
                <cs,l2> = makeFreshTypes(cs,1); t3 = l2[0]; 
		Constraint c3 = makeIsTypeConstraint(e,t3);
		cs.constraints = cs.constraints + { c3 };

		if (`{<{Expression ","}* el>}` !:= e) {
			Constraint c3a = SplicedSetElement(t3);
			cs.constraints = cs.constraints + { c3a };
		}

		elements += t3;
        }

	<cs,l3> = makeFreshTypes(cs,1); t4 = l3[0]; 
	Constraint c4 = LubOf(elements,t4);
	Constraint c5 = makeIsTypeConstraint(t1, makeSetType(t4));
	cs.constraints = cs.constraints + { c4, c5 };

	return cs;
}

//
// Check the trivial tuple expression
//
//      e1 : t1
// ----------------------
//   < e1 > : tuple[t1]
//
public Constraints checkTrivialTupleExpression(Constraints cs, Expression ep, Expression ei) {
	<cs,l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1]; 
	Constraint c1 = makeIsTypeConstraint(ep,t1);
	Constraint c2 = makeIsTypeConstraint(ei,t2);
	Constraint c3 = makeIsTypeConstraint(t1,makeTupleType([t2]));
	cs.constraints = cs.constraints + { c1, c2, c3 };
	return cs;
}

//
// Check the tuple expression
//
//      e1 : t1, ..., en : tn
// ------------------------------------------
//   < e1, ..., en > : tuple[t1, ..., tn]
//
public Constraints checkTupleExpression(Constraints cs, Expression ep, Expression ei, {Expression ","}* el) {
	<cs,l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1];
	Constraint c1 = makeIsTypeConstraint(ep,t1);
	Constraint c2 = makeIsTypeConstraint(ei,t2);
	cs.constraints = cs.constraints + { c1, c2 };

	list[RType] elements = [ t2 ]; 

	for (e <- el) { 
                <cs,l2> = makeFreshTypes(cs,1); t3 = l2[0]; 
		Constraint c3 = makeIsTypeConstraint(e,t3);
		cs.constraints = cs.constraints + { c3 };
		elements += t3;
        }

	Constraint c4 = makeIsTypeConstraint(t1, makeTupleType(elements));
	cs.constraints = cs.constraints + { c4 };

	return cs;
}

//
// Typecheck a closure. The type of the closure is a function type, based on the parameter types
// and the return type. This mainly then propagages any failures in the parameters or the
// closure body.
//
public RType checkClosureExpression(Expression ep, Type t, Parameters p, Statement+ ss) {
	list[RType] pTypes = getParameterTypes(p);
	bool isVarArgs = size(pTypes) > 0 ? isVarArgsType(pTypes[size(pTypes)-1]) : false;
	set[RType] stmtTypes = { getInternalStatementType(s@rtype) | s <- ss };
	
	if (checkForFail(toSet(pTypes) + stmtTypes)) return collapseFailTypes(toSet(pTypes) + stmtTypes);

	return makeFunctionType(convertType(t), pTypes);
}

//
// Typecheck a void closure. The type of the closure is a function type, based on the parameter types
// and the void return type. This mainly then propagages any failures in the parameters or the
// closure body.
//
public RType checkVoidClosureExpression(Expression ep, Parameters p, Statement+ ss) {
	list[RType] pTypes = getParameterTypes(p);
	bool isVarArgs = size(pTypes) > 0 ? isVarArgsType(pTypes[size(pTypes)-1]) : false;
	set[RType] stmtTypes = { getInternalStatementType(s@rtype) | s <- ss };
	
	if (checkForFail(toSet(pTypes) + stmtTypes)) return collapseFailTypes(toSet(pTypes) + stmtTypes);

	return makeFunctionType(makeVoidType(), pTypes);
}
 
//
// The type of a block of expressions is the type generated by the last statement in the block.
//
public RType checkNonEmptyBlockExpression(Expression ep, Statement+ ss) {
	list[Statement] sl = [ s | s <- ss ];
	list[RType] slTypes = [ getInternalStatementType(s@rtype) | s <- sl ];

	if (checkForFail(toSet(slTypes))) {
		return collapseFailTypes(toSet(slTypes));
	} else {
		return slTypes[size(slTypes)-1];
	}
}

public RType checkVisitExpression(Expression ep, Label l, Visit v) {
	if (checkForFail({l@rtype, v@rtype})) return collapseFailTypes({l@rtype, v@rtype});
	return v@rtype;
}

//
// Paren expressions are handled below in checkExpression
//

data RConstantOp =
          Negative()
        | Plus()
	| Minus()
	| NotIn()
	| In()
	| Lt()
	| LtEq()
	| Gt()
	| GtEq()
	| Eq()
	| NEq()
	| Intersect()
	| Product()
	| Join()
	| Div()
	| Mod()
        ;

data Constraint =
          IsType(Tree t, RType rt)
	| IsType(RType l, RType r)
        | FieldOf(Tree t, RType rt)
	| AssignableTo(RType l, RType r)
	| ConstantAppliable(RConstantOp rcop, list[RType] domain, RType range)
	| SubtypeOf(RType l, RType r)
	| LubOf(list[RType] lubs, RType res)
	| Failure(Tree t, RType rt)
	| DefinedBy(Tree t, set[STItemId] defs)
	| SplicedListElement(RType rt)
	| SplicedSetElement(RType rt)
	;

data Constraints = 
          Constraints(int freshCounter, set[Constraint] constraints);

data RType =
          FreshType(int tnum)
	| CallableType(list[RType] argTypes, RType resType)
        ;

tuple[Constraints,list[RType]] makeFreshTypes(Constraints cs, int n) {
        list[RType] ftlist = [FreshType(c) | c <- [cs.freshCounter .. (cs.freshCounter+n-1)] ];
	cs.freshCounter = cs.freshCounter + n;
	return < cs, ftlist >;
}

//
// Check the range expression: [ e1 .. e2 ]
//
// e1 : int, e2 : int
// ------------------
// [ e1 .. e2 ] : list[int]
//
public Constraints checkRangeExpression(Constraints cs, Expression ep, Expression e1, Expression e2) {
        <cs,l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];

	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(e1,t2); Constaint c3 = makeIsTypeConstraint(e2,t3);
	Constaint c4 = makeIsTypeConstraint(t1,makeListType(makeIntType())); // The result of [1..2] is list[int]
	Constaint c5 = makeIsTypeConstraint(t2,makeIntType());
	Constaint c6 = makeIsTypeConstraint(t3,makeIntType());
	
	cs.constraints = cs.contraints + { c1, c2, c3, c4, c5, c6 };
	return cs;
}

//
// Check the step range expression: [ e1, e2 .. e3 ]
//
// e1 : int, e2 : int, e3 : int
// -----------------------------
// [ e1, e2 .. e3 ] : list[int]
//
public Constraints checkStepRangeExpression(Constraints cs, Expression ep, Expression e1, Expression e2, Expression e3) {
        <cs,l1> = makeFreshTypes(cs,4); t1 = l1[0]; t2 = l1[1]; t3 = l1[2]; t4 = l1[3];

	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(e1,t2); Constaint c3 = makeIsTypeConstraint(e2,t3); Constraint c4 = makeIsTypeConstraint(e3,t4);
	Constaint c5 = makeIsTypeConstraint(t1,makeListType(makeIntType())); // The result of [1,2..3] is list[int]
	Constaint c6 = makeIsTypeConstraint(t2,makeIntType());
	Constaint c7 = makeIsTypeConstraint(t3,makeIntType());
	Constaint c8 = makeIsTypeConstraint(t4,makeIntType());
	
	cs.constraints = cs.contraints + { c1, c2, c3, c4, c5, c6, c7, c8 };
	return cs;
}

//
// Check the field update expression: e1.n = e2
//
// e1 : t1, e2 : t2, n fieldOf t1, t1.n : t3, t2 <: t3
// ----------------------------------------------------
//                e1.n = e2 : t1
//
public Constraints checkFieldUpdateExpression(Constraints cs, Expression ep, Expression el, Name n, Expression er) {
        <cs,l1> = makeFreshTypes(cs,4); t1 = l1[0]; t2 = l1[1]; t3 = l1[2]; t4 = l1[3];

	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(el,t2); Constaint c3 = makeIsTypeConstraint(n,t3); Constraint c4 = makeIsTypeConstraint(er,t4);
	Constraint c5 = makeIsTypeConstraint(t1,t2); // the overall expression has the same type as el, i.e., x.f = 3 is of type x
	Constraint c6 = AssignableTo(t4,t3); // the type of expression being assigned is assignment compatible with the type of the field
	Constraint c7 = FieldOf(n,t2); // name n is actually a field of type t2, i.e., in x.f = 3, f is a field of x
	Constraint c8 = DefinedBy(t3,n@nameIds);

	cs.constraints = cs.contraints + { c1, c2, c3, c4, c5, c6, c7, c8 };
	return cs;
}

//
// Check the field access expression: e1.n
//
//  e : t1, n fieldOf t1, t1.n : t2
// ----------------------------------------
//        e.n : t2
//
public Constraints checkFieldAccessExpression(Constraints cs, Expression ep, Expression el, Name n) {
        <cs,l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];

	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(el,t2); Constaint c3 = makeIsTypeConstraint(n,t3); 
	Constraint c5 = makeIsTypeConstraint(t1,t3); // the overall expression has the same type as the type of field n, i.e., x.f is of type field f
	Constraint c6 = FieldOf(n,t2); // name n is actually a field of type t2, i.e., in x.f, f is a field of x
	Constraint c7 = DefinedBy(t3,n@nameIds);

	cs.constraints = cs.contraints + { c1, c2, c3, c4, c5, c6, c7 };
	return cs;
}

//
// Field projection is defined over maps, tuples, and relations.
//
// TODO: Improve pretty printing of error messages
// 
// TODO: Factor out common code
//
// TODO: Why does <f,-1> cause a parsing error when used in a pattern match?
//
public RType checkFieldProjectExpression(Expression ep, Expression e, {Field ","}+ fl) {
	if (checkForFail({e@rtype})) return collapseFailTypes({e@rtype});

	list[Field] fieldList = [ f | f <- fl ];

	RType expType = e@rtype;

	if (isMapType(expType)) {
		list[RNamedType] fields = getMapFieldsWithNames(expType);
		list[tuple[Field field, int offset]] fieldOffsets = getFieldOffsets(fields, fieldList);

		list[Field] badFields = [ f | <f,n> <- fieldOffsets, n == -1 ];
		if (size(badFields) > 0) return makeFailType("Map <prettyPrintType(expType)> does not contain fields <badFields>");

 		list[int] fieldNumbers = [ n | <_,n> <- fieldOffsets ];
		bool keepFieldNames = size(fieldNumbers) == size(toSet(fieldNumbers));
				
		if (size(fieldNumbers) == 1)
			return makeSetType(getElementType(fields[fieldNumbers[0]]));
		else
			return makeRelType([ keepFieldNames ? fields[fieldNumbers[n]] : getElementType(fields[fieldNumbers[n]]) | n <- fieldNumbers ]);

	} else if (isRelType(expType)) {
		list[RNamedType] fields = getRelFieldsWithNames(expType);
		list[tuple[Field field, int offset]] fieldOffsets = getFieldOffsets(fields, fieldList);

		list[Field] badFields = [ f | <f,n> <- fieldOffsets, n == -1 ];
		if (size(badFields) > 0) return makeFailType("Relation <prettyPrintType(expType)> does not contain fields <badFields>");

 		list[int] fieldNumbers = [ n | <_,n> <- fieldOffsets ];
		bool keepFieldNames = size(fieldNumbers) == size(toSet(fieldNumbers));				

		if (size(fieldNumbers) == 1)
			return makeSetType(getElementType(fields[fieldNumbers[0]]));
		else
			return makeRelType([ keepFieldNames ? fields[fieldNumbers[n]] : getElementType(fields[fieldNumbers[n]]) | n <- fieldNumbers ]);

	} else if (isTupleType(expType)) {
		list[RNamedType] fields = getTupleFieldsWithNames(expType);
		list[tuple[Field field, int offset]] fieldOffsets = getFieldOffsets(fields, fieldList);

		list[Field] badFields = [ f | <f,n> <- fieldOffsets, n == -1 ];
		if (size(badFields) > 0) return makeFailType("Tuple <prettyPrintType(expType)> does not contain fields <badFields>");

 		list[int] fieldNumbers = [ n | <_,n> <- fieldOffsets ];
		bool keepFieldNames = size(fieldNumbers) == size(toSet(fieldNumbers));				

		if (size(fieldNumbers) == 1)
			return getElementType(fields[fieldNumbers[0]]);
		else
			return makeTupleType([ keepFieldNames ? fields[fieldNumbers[n]] : getElementType(fields[fieldNumbers[n]]) | n <- fieldNumbers ]);

	} else {
		return makeFailType("Cannot use field projection on type <prettyPrintType(expType)>", ep@\loc);
	}
}

public RType checkSubscriptExpression(Expression ep, Expression el, {Expression ","}+ es) {
	list[Expression] indexList = [ e | e <- es ];
	if (checkForFail({ e@rtype | e <- es } + el@rtype)) return collapseFailTypes({ e@rtype | e <- es } + el@rtype);

	RType expType = el@rtype;
	
	if (isTupleType(expType)) {
		if (size(indexList) > 1) return makeFailType("Subscripts on tuples must contain exactly one element", ep@\loc);
		if (! isIntType(indexList[0]@rtype) ) 
                        return makeFailType("Subscripts on tuples must be of type int, not type <prettyPrintType(indexList[0]@rtype)>", ep@\loc);
		return lubList(getTupleFields(expType)); 		
	} else if (isRelType(expType)) {
		if (size(indexList) > 1) return makeFailType("Subscripts on nodes must contain exactly one element", ep@\loc);
		RType relLeftType = getRelFields(expType)[0];
		RType indexType = lubSet({ e@rtype | e <- indexList});
		if (! (subtypeOf(relLeftType,indexType) || subtypeOf(indexType,relLeftType))) { 
			return makeFailType("The subscript type <prettyPrintType(indexType)> must be comparable to the type of the first projection of the relation, <prettyPrintType(relLeftType)>", ep@\loc);
		}
		list[RType] resultTypes = tail(getRelFields(expType));
		if (size(resultTypes) == 1)
			return makeSetType(resultTypes[0]);
		else
			return makeRelType(resultTypes);		
	} else if (isMapType(expType)) {
		if (size(indexList) > 1) return makeFailType("Subscripts on nodes must contain exactly one element", ep@\loc);
		RType domainType = getMapDomainType(expType);
		RType indexType = indexList[0]@rtype;
		if (! (subtypeOf(domainType,indexType) || subtypeOf(indexType,domainType))) 
			return makeFailType("The subscript type <prettyPrintType(indexType)> must be comparable to the domain type <prettyPrintType(domainType)>", ep@\loc);
		return getMapRangeType(expType);
	}  else if (isNodeType(expType)) {
		if (size(indexList) > 1) return makeFailType("Subscripts on nodes must contain exactly one element", ep@\loc);
		if (! isIntType(indexList[0]@rtype) ) return makeFailType("Subscripts on nodes must be of type int, not type <prettyPrintType(indexList[0]@rtype)>", ep@\loc);
		return makeValueType();
	} else if (isListType(expType)) {
		if (size(indexList) > 1) return makeFailType("Subscripts on lists must contain exactly one element", ep@\loc);
		if (! isIntType(indexList[0]@rtype) ) return makeFailType("Subscripts on lists must be of type int, not type <prettyPrintType(indexList[0]@rtype)>", ep@\loc);
		return getListElementType(expType);		
	} else {
		return makeFailType("Subscript not supported on type <prettyPrintType(expType)>", ep@\loc);
	}
}

//
// Check the is defined expression
//
//   e : t
// ----------
//   e? : t
//
public Constraints checkIsDefinedExpression(Constraints cs, Expression ep, Expression e) {
        <cs,l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1];

	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(e,t2); 
	Constraint c3 = makeIsTypeConstraint(t1,t2);
	
	cs.constraints = cs.constraints + { c1, c2, c3 };
	
	return cs;
}

//
// Check the negation expression
//
//      e : bool
// --------------------
//   not e : bool
//
// TODO: Could define this like Negative below, but not is only defined right now over bool
//
private Constraints checkNegationExpression(Constraints cs, Expression ep, Expression e) {
        <cs,l1> = makeFreshTypes(cs,2); t1 = l1[0]; t2 = l1[1];

	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(e,t2); 
	Constraint c3 = makeIsTypeConstraint(t1,t2);
	Constraint c4 = makeIsTypeConstraint(t2,makeBoolType());
	
	cs.constraints = cs.constraints + { c1, c2, c3, c4 };
	
	return cs;
}

//
// Check the negative expression
//
//      e : t1, -_ : t2 -> t2 defined, t1 <: t2 
// ---------------------------------------------
//          - e : t2
//
private Constraints checkNegativeExpression(Constraints cs, Expression ep, Expression e) {
        <cs,l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];

	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(e,t2); 
	Constraint c3 = ConstantAppliable(Negative(), [ t2 ], t3);
	Constraint c4 = makeIsTypeConstraint(t1,t3);
	
	cs.constraints = cs.constraints + { c1, c2, c3, c4 };
	
	return cs;
}

public RType checkTransitiveReflexiveClosureExpression(Expression ep, Expression e) {
	RType expType = e@rtype;
	if (isFailType(expType)) return expType;
	if (! isRelType(expType)) return makeFailType("Error in transitive reflexive closure operation: <e> should be a relation, but instead is <prettyPrintType(expType)>", ep@\loc);
	list[RNamedType] relFields = getRelFieldsWithNames(expType);
	if (size(relFields) != 2) return makeFailType("Error in transitive reflexive closure operation: <e> should be a relation of arity 2, but instead is <prettyPrintType(expType)>", ep@\loc);
	return expType; 
}

public RType checkTransitiveClosureExpression(Expression ep, Expression e) {
	RType expType = e@rtype;
	if (isFailType(expType)) return expType;
	if (! isRelType(expType)) return makeFailType("Error in transitive closure operation: <e> should be a relation, but instead is <prettyPrintType(expType)>", ep@\loc);
	list[RNamedType] relFields = getRelFieldsWithNames(expType);
	if (size(relFields) != 2) return makeFailType("Error in transitive closure operation: <e> should be a relation of arity 2, but instead is <prettyPrintType(expType)>", ep@\loc);
	return expType; 
}

//
// TODO: To properly check this, we need to keep a map of not just the annotation names and types,
// but of which types those annotations apply to!
//
public RType checkGetAnnotationExpression(Expression ep, Expression e, Name n) {
	RType rt = getTypeForName(globalSymbolTable, convertName(n), n@\loc);
	if (checkForFail({ e@rtype, rt })) return collapseFailTypes({ e@rtype, rt });
	return rt;
}

//
// TODO: To properly check this, we need to keep a map of not just the annotation names and types,
// but of which types those annotations apply to!
//
public RType checkSetAnnotationExpression(Expression ep, Expression el, Name n, Expression er) {
	RType rt = getTypeForName(globalSymbolTable, convertName(n), n@\loc);
	if (checkForFail({ el@rtype, rt, er@rtype })) return collapseFailTypes({ el@rtype, rt, er@rtype });
	if (! subtypeOf(er@rtype, rt)) return makeFailType("The type of <er>, <prettyPrintType(er@rtype)>, must be a subtype of the type of <n>, <prettyPrintType(rt)>", ep@\loc);
	return rt;
}

//
// Composition is defined for functions, maps, and relations.
//
// TODO: Question on order: currently the order is "backwards" from the standard mathematical
// order, i.e., r1 o r2 is r1, then r2, versus r2 first, then r1. Is this the desired behavior, or was
// this accidental? For functions the order appears to be correct, even though the implementation
// doesn't actually work. For maps the order is the same "backwards" order as it is for relations.
//
// NOTE: map composition does not maintain field names. Is this intentional?
//
public RType checkCompositionExpression(Expression ep, Expression el, Expression er) {
	if (checkForFail({ el@rtype, er@rtype })) return collapseFailTypes({ el@rtype, er@rtype });
	RType leftType = el@rtype; RType rightType = er@rtype;
	if (isFunType(leftType) && isFunType(rightType)) {
		return makeFailType("Type checking this feature is not yet supported!", ep@\loc); // TODO: Implement this, including support for overloading
	} else if (isMapType(leftType) && isMapType(rightType)) {
		// Check to make sure the fields are of the right type to compose
		RType j1 = getMapRangeType(leftType); RType j2 = getMapDomainType(rightType);
		if (! subtypeOf(j1,j2)) return makeFailType("Incompatible types in composition: <prettyPrintType(j1)> and <prettyPrintType(j2)>", ep@\loc);

		return RMapType(getMapDomainType(leftType), getMapRangeType(rightType));
	} else if (isRelType(leftType) && isRelType(rightType)) {
		list[RNamedType] leftFields = getRelFieldsWithNames(leftType); 
		list[RNamedType] rightFields = getRelFieldsWithNames(rightType);

		// Check to make sure each relation is just arity 2
		if (size(leftFields) != 2) return makeFailType("Error in composition: <el> should be a relation of arity 2, but instead is <prettyPrintType(leftType)>", ep@\loc);
		if (size(rightFields) != 2) return makeFailType("Error in composition: <er> should be a relation of arity 2, but instead is <prettyPrintType(rightType)>", ep@\loc);

		// Check to make sure the fields are of the right type to compose
		RType j1 = getElementType(head(tail(leftFields,1))); RType j2 = getElementType(head(rightFields));
		if (! subtypeOf(j1,j2)) return makeFailType("Incompatible types in composition: <prettyPrintType(j1)> and <prettyPrintType(j2)>", ep@\loc);

		// Check to see if we need to drop the field names, then return the proper type
		RNamedType r1 = head(leftFields); RNamedType r2 = head(tail(rightFields,1));
		if (RNamedType(t1,n) := r1 && RNamedType(t2,n) := r2)
			return RRelType([RUnnamedType(t1),RUnnamedType(t2)]); // Both fields had the same name, so just keep the type and make unnamed fields
		else
			return RRelType([r1,r2]); // Maintain the field names, they differ
	}
	return makeFailType("Composition is not supported on types <prettyPrintType(leftType)> and <prettyPrintType(rightType)>", ep@\loc);
}

//
// Check binary expressions
//
//      e1 : t1, e2 : t2, rop : t3 x t4 -> t5 defined, t1 <: t3, t2 <: t4
// ------------------------------------------------------------------------
//                            e1 rop e2 : t5
//
// NOTE: The subtyping check is in the ConstantAppliable logic
//
public Constraints checkBinaryExpression(Constraints cs, Expression ep, Expression el, RConstantOp rop, Expression er) {
        <cs,l1> = makeFreshTypes(cs,4); t1 = l1[0]; t2 = l1[1]; t3 = l1[2]; t4 = l1[3];
	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(el,t2); Constraint c3 = makeIsTypeConstraint(er,t3);
	Constraint c4 = ConstantAppliable(rop, [ t2, t3 ], t4);
	Constraint c5 = makeIsTypeConstraint(t1, t4);

	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5 };

	return cs;
}

//
// Check binary expressions
//
//      e1 : t1, e2 : t2, rop : t3 x t4 -> t5 defined, t1 <: t3, t2 <: t4, t6 given, t5 = t6
// --------------------------------------------------------------------------------------------
//                            e1 rop e2 : t6
//
// NOTE: The subtyping check is in the ConstantAppliable logic
//
public Constraints checkBinaryExpression(Constraints cs, Expression ep, Expression el, RConstantOp rop, Expression er, RType resultType) {
        <cs,l1> = makeFreshTypes(cs,4); t1 = l1[0]; t2 = l1[1]; t3 = l1[2]; t4 = l1[3];
	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(el,t2); Constraint c3 = makeIsTypeConstraint(er,t3);
	Constraint c4 = ConstantAppliable(rop, [ t2, t3 ], t4);
	Constraint c5 = makeIsTypeConstraint(t1, t4);
	Constraint c6 = makeIsTypeConstraint(t1, resultType); // t6 in the above

	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5, c6 };

	return cs;
}

//
// Check the product expression e1 * e2
//
public Constraints checkProductExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, Product(), er);
}

//
// Check the join expression e1 join e2
//
public Constraints checkJoinExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, Join(), er);
}

//
// Check the div expression e1 / e2
//
public Constraints checkDivExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, Div(), er);
}

//
// Check the mod expression e1 % e2
//
public Constraints checkModExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, Mod(), er);
}

//
// Check the intersection expression e1 & e2
//
public Constraints checkIntersectionExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, Intersect(), er);
}

//
// Check the plus expression e1 + e2
//
public Constraints checkPlusExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, Plus(), er);
}

//
// Check the minus expression e1 - e2
//
public Constraints checkMinusExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, Minus(), er);
}

//
// Check the notin expression e1 notin e2
//
public Constraints checkNotInExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, NotIn(), er, makeBoolType());
}

//
// Check the in expression e1 in e2
//
public Constraints checkInExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        return checkBinaryExpression(cs, ep, el, In(), er, makeBoolType());
}

//
// Check the Less Than expression e1 < e2
//
public Constraints checkLessThanExpression(Constraints cs, Expression ep, Expression el, Expression er) {
	return checkBinaryExpression(cs, ep, el, Lt(), er, makeBoolType());
}

//
// Check the Less Than or Equal expression e1 <= e2
//
public Constraints checkLessThanOrEqualExpression(Constraints cs, Expression ep, Expression el, Expression er) {
	return checkBinaryExpression(cs, ep, el, LtEq(), er, makeBoolType());
}

//
// Check the Greater Than expression e1 > e2
//
public Constraints checkGreaterThanExpression(Constraints cs, Expression ep, Expression el, Expression er) {
	return checkBinaryExpression(cs, ep, el, Gt(), er, makeBoolType());
}

//
// Check the Greater Than or Equal expression e1 >= e2
//
public Constraints checkGreaterThanOrEqualExpression(Constraints cs, Expression ep, Expression el, Expression er) {
	return checkBinaryExpression(cs, ep, el, GtEq(), er, makeBoolType());
}

//
// Check the Equals expression e1 == e2
//
public Constraints checkEqualsExpression(Constraints cs, Expression ep, Expression el, Expression er) {
	return checkBinaryExpression(cs, ep, el, Eq(), er, makeBoolType());
}

//
// Check the Not Equals expression e1 != e2
//
public Constraints checkNotEqualsExpression(Constraints cs, Expression ep, Expression el, Expression er) {
	return checkBinaryExpression(cs, ep, el, NEq(), er, makeBoolType());
}

//
// Check the ternary if expression
//
//      eb : bool, et : t1, ef : t2, t3 = lub(t1,t2)
// -----------------------------------------------------
//          eb ? et : ef  :  t3
//
public Constraints checkIfThenElseExpression(Constraints cs, Expression ep, Expression eb, Expression et, Expression ef) {

        <cs,l1> = makeFreshTypes(cs,5); t1 = l1[0]; t2 = l1[1]; t3 = l1[2]; t4 = l1[3]; t5 = l1[4];
	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(eb,t2); Constraint c3 = makeIsTypeConstraint(et,t3); Constraint c4 = makeIsTypeConstraint(ef,t4);
	Constraint c5 = makeIsTypeConstraint(t2,makeBoolType());
	Constraint c6 = LubOf([t3,t4],t5);
	Constraint c7 = makeIsTypeConstraint(t1,t5);

	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5, c6, c7 };

	return cs;
}

//
// Check the if defined / otherwise expression
//
//      ed : t1, eo : t2, t3 = lub(t1, t2)
// -----------------------------------------
//          ed ? eo  : t3
//
public Constraints checkIfDefinedOtherwiseExpression(Constraints cs, Expression ep, Expression ed, Expression eo) {

        <cs,l1> = makeFreshTypes(cs,4); t1 = l1[0]; t2 = l1[1]; t3 = l1[2]; t4 = l1[3];
	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(ed,t2); Constraint c3 = makeIsTypeConstraint(eo,t3); 
	Constraint c4 = LubOf([t2,t3],t4);
	Constraint c5 = makeIsTypeConstraint(t1,t4);

	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5 };

	return cs;
}

//
// Check the logical implication expression
//
//      el : bool, er : bool
// -----------------------------------------
//          el ==> er : bool
//
public Constraints checkImplicationExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        <cs,l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(el,t2); Constraint c3 = makeIsTypeConstraint(er,t3);
	Constraint c4 = makeIsTypeConstraint(t1, makeBoolType());
	Constraint c5 = makeIsTypeConstraint(t2, makeBoolType());
	Constraint c6 = makeIsTypeConstraint(t3, makeBoolType());

	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5, c6 };

	return cs;
}

//
// Check the logical equivalence expression
//
//      el : bool, er : bool
// -----------------------------------------
//          el <==> er : bool
//
public Constraints checkEquivalenceExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        <cs,l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(el,t2); Constraint c3 = makeIsTypeConstraint(er,t3);
	Constraint c4 = makeIsTypeConstraint(t1, makeBoolType());
	Constraint c5 = makeIsTypeConstraint(t2, makeBoolType());
	Constraint c6 = makeIsTypeConstraint(t3, makeBoolType());

	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5, c6 };

	return cs;
}

//
// Check the logical and expression
//
//      el : bool, er : bool
// -----------------------------------------
//          el && er : bool
//
public Constraints checkAndExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        <cs,l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(el,t2); Constraint c3 = makeIsTypeConstraint(er,t3);
	Constraint c4 = makeIsTypeConstraint(t1, makeBoolType());
	Constraint c5 = makeIsTypeConstraint(t2, makeBoolType());
	Constraint c6 = makeIsTypeConstraint(t3, makeBoolType());

	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5, c6 };

	return cs;
}

//
// Check the logical or expression
//
//      el : bool, er : bool
// -----------------------------------------
//          el || er : bool
//
public Constraints checkOrExpression(Constraints cs, Expression ep, Expression el, Expression er) {
        <cs,l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
	Constraint c1 = makeIsTypeConstraint(ep,t1); Constraint c2 = makeIsTypeConstraint(el,t2); Constraint c3 = makeIsTypeConstraint(er,t3);
	Constraint c4 = makeIsTypeConstraint(t1, makeBoolType());
	Constraint c5 = makeIsTypeConstraint(t2, makeBoolType());
	Constraint c6 = makeIsTypeConstraint(t3, makeBoolType());

	cs.constraints = cs.constraints + { c1, c2, c3, c4, c5, c6 };

	return cs;
}

public RType checkMatchExpression(Expression ep, Pattern p, Expression e) {
	if (checkForFail({ p@rtype, e@rtype })) return collapseFailTypes({ p@rtype, e@rtype });
	RType boundType = bindInferredTypesToPattern(e@rtype, p);
	if (isFailType(boundType)) return boundType;
	if ( (! subtypeOf(e@rtype, boundType)) && (! subtypeOf(boundType, e@rtype))) 
		return makeFailType("The type of the expression, <prettyPrintType(e@rtype)>, must be comparable to that of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
	return makeBoolType();
}

public RType checkNoMatchExpression(Expression ep, Pattern p, Expression e) {
	if (checkForFail({ p@rtype, e@rtype })) return collapseFailTypes({ p@rtype, e@rtype });
	RType boundType = bindInferredTypesToPattern(e@rtype, p);
	if (isFailType(boundType)) return boundType;
	if ( (! subtypeOf(e@rtype, boundType)) && (! subtypeOf(boundType, e@rtype))) 
		return makeFailType("The type of the expression, <prettyPrintType(e@rtype)>, must be comparable to that of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
	return makeBoolType();
}

//
// Enumerators act like a match, i.e., like :=, except for containers, like lists,
// sets, etc, where they "strip off" the outer layer of the subject. For instance,
// n <- 1 acts just like n := 1, while n <- [1..10] acts like [_*,n,_*] := [1..10].
//
public RType checkEnumeratorExpression(Expression ep, Pattern p, Expression e) {
	if (checkForFail({ p@rtype, e@rtype })) { 
		return collapseFailTypes({ p@rtype, e@rtype });
	} 
	
	RType expType = e@rtype;

	// TODO: Nodes
	// TODO: ADTs
	// TODO: Any other special cases?	
	if (isListType(expType)) {
	        RType et = getListElementType(expType);
		RType boundType = bindInferredTypesToPattern(et, p);
		if (isFailType(boundType)) return boundType;
		if (! subtypeOf(et, boundType)) return makeFailType("The list element type of the subject, <prettyPrintType(et)>, must be a subtype of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
		return makeBoolType();
	} else if (isSetType(expType)) {
	        RType et = getSetElementType(expType);
		RType boundType = bindInferredTypesToPattern(et, p);
		if (isFailType(boundType)) return boundType;
		if (! subtypeOf(et, boundType)) return makeFailType("The set element type of the subject, <prettyPrintType(et)>, must be a subtype of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
		return makeBoolType();
	} else if (isBagType(expType)) {
	        RType et = getBagElementType(expType);
		RType boundType = bindInferredTypesToPattern(et, p);
		if (isFailType(boundType)) return boundType;
		if (! subtypeOf(et, boundType)) return makeFailType("The bag element type of the subject, <prettyPrintType(et)>, must be a subtype of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
		return makeBoolType();
	} else if (isContainerType(expType)) {
	        RType et = getContainerElementType(expType);
		RType boundType = bindInferredTypesToPattern(et, p);
		if (isFailType(boundType)) return boundType;
		if (! subtypeOf(et, boundType)) return makeFailType("The container element type of the subject, <prettyPrintType(et)>, must be a subtype of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
		return makeBoolType();
	} else if (isRelType(expType)) {
	        RType et = getRelElementType(expType);
		RType boundType = bindInferredTypesToPattern(et, p);
		if (isFailType(boundType)) return boundType;
		if (! subtypeOf(et, boundType)) return makeFailType("The relation element type of the subject, <prettyPrintType(et)>, must be a subtype of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
		return makeBoolType();
	} else if (isMapType(expType)) {
	        RType dt = getMapDomainType(expType);
		RType boundType = bindInferredTypesToPattern(dt, p);
		if (isFailType(boundType)) return boundType;
		if (! subtypeOf(dt, boundType)) return makeFailType("The domain type of the map, <prettyPrintType(dt)>, must be a subtype of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
		return makeBoolType();
	} else if (isTupleType(expType)) {
	        RType tt = lubList(getTupleFields(expType));
		RType boundType = bindInferredTypesToPattern(tt, p);
		if (isFailType(boundType)) return boundType;
		if (! subtypeOf(tt, boundType)) return makeFailType("The least upper bound of the tuple element types, <prettyPrintType(tt)>, must be a subtype of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
		return makeBoolType();
	} else {
		RType boundType = bindInferredTypesToPattern(expType, p);
		if (isFailType(boundType)) return boundType;
		if (! subtypeOf(expType, boundType)) return makeFailType("The type of the subject, <prettyPrintType(expType)>, must be a subtype of the pattern type, <prettyPrintType(boundType)>", ep@\loc);
		return makeBoolType();
	}
	
	println("Unhandled enumerator case, <p> \<- <e>");
	return makeBoolType();
}

public RType checkSetComprehensionExpression(Expression ep, {Expression ","}+ els, {Expression ","}+ ers) {
	set[Expression] allExps = { e | e <- els } + { e | e <- ers };
	if (checkForFail({ e@rtype | e <- allExps })) {
		return collapseFailTypes({ e@rtype | e <- allExps });
	} else {
		set[RType] genFailures = { 
			makeFailType("Expression should have type <prettyPrintType(makeBoolType())>, but instead has type <prettyPrintType(e@rtype)>",e@\loc) |
				e <- ers, !isBoolType(e@rtype)
		};
		if (size(genFailures) == 0) {
			list[RType] setTypes = [ ];
			for (e <- els) {
			        RType eType = e@rtype;
				if (isSetType(replaceInferredTypes(eType)) && `{<{Expression ","}* el>}` := e) {
					setTypes = setTypes + [ replaceInferredTypes(eType) ];
				} else if (isSetType(replaceInferredTypes(eType))) {
					setTypes = setTypes + [ getSetElementType(replaceInferredTypes(eType)) ];
				} else {
					setTypes = setTypes + [ replaceInferredTypes(eType) ];
				}
			}
			return makeSetType(lubList(setTypes));
		} else {
			return collapseFailTypes(genFailures);
		}
	}
}

public RType checkListComprehensionExpression(Expression ep, {Expression ","}+ els, {Expression ","}+ ers) {
	set[Expression] allExps = { e | e <- els } + { e | e <- ers };
	if (checkForFail({ e@rtype | e <- allExps }))
		return collapseFailTypes({ e@rtype | e <- allExps });
	else {
		set[RType] genFailures = { 
			makeFailType("Expression should have type <prettyPrintType(makeBoolType())>, but instead has type <prettyPrintType(e@rtype)>",e@\loc) |
				e <- ers, !isBoolType(e@rtype)
		};
		if (size(genFailures) == 0) {
			list[RType] listTypes = [ ];
			for (e <- els) {
			        RType eType = e@rtype;
				if (isListType(replaceInferredTypes(eType)) && `[<{Expression ","}* el>]` := e) {
					listTypes = listTypes + [ replaceInferredTypes(eType) ];
				} else if (isListType(replaceInferredTypes(eType))) {
					listTypes = listTypes + [ getListElementType(replaceInferredTypes(eType)) ];
				} else {
					listTypes = listTypes + [ replaceInferredTypes(eType) ];
				}
			}
			return makeListType(lubList(listTypes));
		} else {
			return collapseFailTypes(genFailures);
		}
	}
}

public RType checkMapComprehensionExpression(Expression ep, Expression ef, Expression et, {Expression ","}+ ers) {
	set[Expression] allExps = { ef } + { et } + { e | e <- ers };
	if (checkForFail({ e@rtype | e <- allExps }))
		return collapseFailTypes({ e@rtype | e <- ers });
	else {
		set[RType] genFailures = { 
			makeFailType("Expression should have type <prettyPrintType(makeBoolType())>, but instead has type <prettyPrintType(e@rtype)>",e@\loc) |
				e <- ers, !isBoolType(e@rtype)
		};
		if (size(genFailures) == 0) {
			return makeMapType(replaceInferredTypes(ef@rtype), replaceInferredTypes(et@rtype));
		} else {
			return collapseFailTypes(genFailures);
		}
	}
}

//
// NOTE: We cannot actually type this statically, since the type of the "it" expression is implicit and the type of
// the result is based only indirectly on the type of er. If we could type this, we could probably solve the halting
// problem ;)
public RType checkReducerExpression(Expression ep, Expression ei, Expression er, {Expression ","}+ ers) {
	list[RType] genTypes = [ e@rtype | e <- ers ];
	if (checkForFail(toSet(genTypes + ei@rtype + er@rtype))) return collapseFailTypes(toSet(genTypes + ei@rtype + er@rtype));

	return makeValueType(); // for now, since it could be anything
}

//
// Check the all expression
//
//      e1 : bool, ..., en : bool
// -----------------------------------------
//          all(e1...en) : bool
//
public Constraints checkAllExpression(Constraints cs, Expression ep, {Expression ","}+ ers) {
        <cs, l1> = makeFreshTypes(cs,1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(ep,t1);
	Constraint c2 = makeIsTypeConstraint(t1,makeBoolType());
	cs.constraints = cs.constraints + { c1, c2 };

	for (er <- ers) {
	        <cs, l2> = makeFreshTypes(cs,1); t2 = l2[0];
		Constraint c3 = makeIsTypeConstraint(er,t2);
		Constraint c4 = makeIsTypeConstraint(t2,makeBoolType());
		cs.constraints = cs.constraints + { c3, c4 };
	}

	return cs;
}
		
//
// Check the any expression
//
//      e1 : bool, ..., en : bool
// -----------------------------------------
//          any(e1...en) : bool
//
public Constraints checkAnyExpression(Constraints cs, Expression ep, {Expression ","}+ ers) {
        <cs, l1> = makeFreshTypes(cs,1); t1 = l1[0];
	Constraint c1 = makeIsTypeConstraint(ep,t1);
	Constraint c2 = makeIsTypeConstraint(t1,makeBoolType());
	cs.constraints = cs.constraints + { c1, c2 };

	for (er <- ers) {
	        <cs, l2> = makeFreshTypes(cs,1); t2 = l2[0];
		Constraint c3 = makeIsTypeConstraint(er,t2);
		Constraint c4 = makeIsTypeConstraint(t2,makeBoolType());
		cs.constraints = cs.constraints + { c3, c4 };
	}

	return cs;
}

//
// Check the map expression
//
//      d1 : td1, r1 : tr1, ..., dn : tdn, rn : trn, td = lub(td1..tdn), tr = lub(tr1..trn)
// ----------------------------------------------------------------------------------------
//                       ( d1 : r1, ..., dn : rn ) : map[td,tr]
//
public Constraints checkMapExpression(Constraints cs, Expression exp) {
        list[tuple[Expression mapDomain, Expression mapRange]] mapContents = getMapExpressionContents(exp);
	<cs,l1> = makeFreshTypes(cs,3); t1 = l1[0]; t2 = l1[1]; t3 = l1[2];
	Constraint c1 = makeIsTypeConstraint(ep,t1);
	Constraint c2 = makeIsTypeConstraint(t2,makeVoidType());
	Constraint c3 = makeIsTypeConstraint(t3,makeVoidType());
	cs.constraints = cs.constraints + { c1, c2, c3 };

	list[RType] domains = [ t2 ]; list[RType] ranges = [ t3 ];
	for (<md,mr> <- mapContents) { 
                <cs,l2> = makeFreshTypes(cs,2); t4 = l2[0]; t5 = l2[1];
		Constraint c4 = makeIsTypeConstraint(md,t4);
		Constraint c5 = makeIsTypeConstraint(mr,t5);
		domains += t4; ranges += t5;
		cs.constraints = cs.constraints + { c4, c5 };
        }

	<cs,l3> = makeFreshTypes(cs,2); t6 = l3[0]; t7 = l3[1];
	Constraint c6 = LubOf(domains,t6);
	Constraint c7 = LubOf(domains,t7);
	Constraint c8 = makeIsTypeConstraint(t1, makeMapType(t6,t7));
	cs.constraints = cs.constraints + { c6, c7, c8 };

	return cs;
}

public Constraints checkExpression(Constraints cs, Expression exp) {
	switch(exp) {
		case (Expression)`<BooleanLiteral bl>` : {
		        <cs,l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1,makeBoolType());
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}

		case (Expression)`<DecimalIntegerLiteral il>`  : {
		        <cs,l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1,makeIntType());
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}

		case (Expression)`<OctalIntegerLiteral il>`  : {
		        <cs,l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1,makeIntType());
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}

		case (Expression)`<HexIntegerLiteral il>`  : {
		        <cs,l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1,makeIntType());
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}

		case (Expression)`<RealLiteral rl>`  : {
		        <cs,l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1,makeRealType());
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}

		case (Expression)`<StringLiteral sl>`  : {
		        <cs,l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1,makeRealType());
			cs.constraints = cs.constraints + { c1, c2 };

		        list[Tree] ipl = prodFilter(sl, 
                                bool(Production prd) { return prod(_,\cf(sort("Expression")),_) := prd || prod(_,\cf(sort("StringTemplate")),_) := prd; });
			for (ip <- ipl) {
			        <cs,l2> = makeFreshTypes(cs,1); t2 = l2[0];
				Constraint c3 = makeIsTypeConstraint(ip,t2);
				Constraint c4 = makeIsTypeConstraint(t2,makeStrType());
				cs.constraints = cs.constraints + { c3, c4 };
			}

			return cs;
		}

		case (Expression)`<LocationLiteral ll>`  : {
		        <cs,l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1,makeLocType());
			cs.constraints = cs.constraints + { c1, c2 };

		        list[Expression] ipl = prodFilter(ll, bool(Production prd) { return prod(_,\cf(sort("Expression")),_) := prd; });
			for (ip <- ipl) {
			        <cs,l2> = makeFreshTypes(cs,1); t2 = l2[0];
				Constraint c3 = makeIsTypeConstraint(ip,t2);
				Constraint c4 = makeIsTypeConstraint(t2,makeStrType());
				cs.constraints = cs.constraints + { c3, c4 };
			}

			return cs;
		}

		case (Expression)`<DateTimeLiteral dtl>`  : {
		        <cs,l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1,makeDateTimeType());
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}

		// _ as a name, should only be in patterns, but include just in case...
		case (Expression)`_`: {
		        Constraint c1 = Failure(exp,makeFailType("The anonymous name _ can only be used inside a pattern",exp@\loc));
			cs.constraints = cs.constraints + { c1 };
			return cs;
		}

		// Name
		case (Expression)`<Name n>`: {
		        <cs, l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = DefinedBy(t1,n@nameIds);
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}
		
		// QualifiedName
		case (Expression)`<QualifiedName qn>`: {
		        <cs, l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = DefinedBy(t1,qn@nameIds);
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}

		// ReifiedType
		case `<BasicType t> ( <{Expression ","}* el> )` :
			return checkReifiedTypeExpression(cs,exp,t,el);

		// CallOrTree
		case `<Expression e1> ( <{Expression ","}* el> )` :
			return checkCallOrTreeExpression(cs,exp,e1,el);

		// List
		case `[<{Expression ","}* el>]` :
			return checkListExpression(cs,exp,el);

		// Set
		case `{<{Expression ","}* el>}` :
			return checkSetExpression(cs,exp,el);

		// Tuple, with just one element
		case (Expression)`<<Expression ei>>` :
			return checkTrivialTupleExpression(cs,exp,ei);

		// Tuple, with multiple elements
		case `<<Expression ei>, <{Expression ","}* el>>` :
			return checkTupleExpression(cs,exp,ei,el);

		// Closure
		case `<Type t> <Parameters p> { <Statement+ ss> }` :
			return checkClosureExpression(cs,exp,t,p,ss);

		// VoidClosure
		case `<Parameters p> { <Statement* ss> }` :
			return checkVoidClosureExpression(cs,exp,p,ss);

		// NonEmptyBlock
		case `{ <Statement+ ss> }` :
			return checkNonEmptyBlockExpression(cs,exp,ss);
		
		// Visit
		case (Expression) `<Label l> <Visit v>` :
			return checkVisitExpression(cs,exp,l,v);
		
		// ParenExp
		case `(<Expression e>)` : {
		        <cs, l1> = makeFreshTypes(cs, 2); t1 = l1[0]; t2 = l1[1];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(e,t2);
			Constraint c3 = makeIsTypeConstraint(t1,t2);
			cs.constraints = cs.constraints + { c1, c2, c3 };
			return cs;
		}

		// Range
		case `[ <Expression e1> .. <Expression e2> ]` :
			return checkRangeExpression(cs,exp,e1,e2);

		// StepRange
		case `[ <Expression e1>, <Expression e2> .. <Expression e3> ]` :
			return checkStepRangeExpression(cs,exp,e1,e2,e3);

		// ReifyType
		case (Expression)`#<Type t>` : {
		        <cs, l1> = makeFreshTypes(cs, 1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = makeIsTypeConstraint(t1, RTypeStructured(RStructuredType(RTypeType(),[RTypeArg(convertType(t))])));
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}

		// FieldUpdate
		case `<Expression e1> [<Name n> = <Expression e2>]` :
			return checkFieldUpdateExpression(cs,exp,e1,n,e2);

		// FieldAccess
		case `<Expression e1> . <Name n>` :
			return checkFieldAccessExpression(cs,exp,e1,n);

		// FieldProject
		case `<Expression e1> < <{Field ","}+ fl> >` :
			return checkFieldProjectExpression(cs,exp,e1,fl);

		// Subscript 
		case `<Expression e1> [ <{Expression ","}+ el> ]` :
			return checkSubscriptExpression(cs,exp,e1,el);

		// IsDefined
		case `<Expression e> ?` :
			return checkIsDefinedExpression(cs,exp,e);

		// Negation
		case `! <Expression e>` :
			return checkNegationExpression(cs,exp,e);

		// Negative
		case `- <Expression e> ` :
			return checkNegativeExpression(cs,exp,e);

		// TransitiveReflexiveClosure
		case `<Expression e> * ` :
			return checkTransitiveReflexiveClosureExpression(cs,exp,e);

		// TransitiveClosure
		case `<Expression e> + ` :
			return checkTransitiveClosureExpression(cs,exp,e);

		// GetAnnotation
		case `<Expression e> @ <Name n>` :
			return checkGetAnnotationExpression(cs,exp,e,n);

		// SetAnnotation
		case `<Expression e1> [@ <Name n> = <Expression e2>]` :
			return checkSetAnnotationExpression(cs,exp,e1,n,e2);

		// Composition
		case `<Expression e1> o <Expression e2>` :
			return checkCompositionExpression(cs,exp,e1,e2);

		// Product
		case `<Expression e1> * <Expression e2>` :
			return checkProductExpression(cs,exp,e1,e2);

		// Join
		case `<Expression e1> join <Expression e2>` :
			return checkJoinExpression(cs,exp,e1,e2);

		// Div
		case `<Expression e1> / <Expression e2>` :
			return checkDivExpression(cs,exp,e1,e2);

		// Mod
		case `<Expression e1> % <Expression e2>` :
			return checkModExpression(cs,exp,e1,e2);

		// Intersection
		case `<Expression e1> & <Expression e2>` :
			return checkIntersectionExpression(cs,exp,e1,e2);
		
		// Plus
		case `<Expression e1> + <Expression e2>` :
			return checkPlusExpression(cs,exp,e1,e2);

		// Minus
		case `<Expression e1> - <Expression e2>` :
			return checkMinusExpression(cs,exp,e1,e2);

		// NotIn
		case `<Expression e1> notin <Expression e2>` :
			return checkNotInExpression(cs,exp,e1,e2);

		// In
		case `<Expression e1> in <Expression e2>` :
			return checkInExpression(cs,exp,e1,e2);

		// LessThan
		case `<Expression e1> < <Expression e2>` :
			return checkLessThanExpression(cs,exp,e1,e2);

		// LessThanOrEq
		case `<Expression e1> <= <Expression e2>` :
			return checkLessThanOrEqualExpression(cs,exp,e1,e2);

		// GreaterThan
		case `<Expression e1> > <Expression e2>` :
			return checkGreaterThanExpression(cs,exp,e1,e2);

		// GreaterThanOrEq
		case `<Expression e1> >= <Expression e2>` :
			return checkGreaterThanOrEqualExpression(cs,exp,e1,e2);

		// Equals
		case `<Expression e1> == <Expression e2>` :
			return checkEqualsExpression(cs,exp,e1,e2);

		// NotEquals
		case `<Expression e1> != <Expression e2>` :
			return checkNotEqualsExpression(cs,exp,e1,e2);

		// IfThenElse (Ternary)
		case `<Expression e1> ? <Expression e2> : <Expression e3>` :
			return checkIfThenElseExpression(cs,exp,e1,e2,e3);

		// IfDefinedOtherwise
		case `<Expression e1> ? <Expression e2>` :
			return checkIfDefinedOtherwiseExpression(cs,exp,e1,e2);

		// Implication
		case `<Expression e1> ==> <Expression e2>` :
			return checkImplicationExpression(cs,exp,e1,e2);

		// Equivalence
		case `<Expression e1> <==> <Expression e2>` :
			return checkEquivalenceExpression(cs,exp,e1,e2);

		// And
		case `<Expression e1> && <Expression e2>` :
			return checkAndExpression(cs,exp,e1,e2);

		// Or
		case `<Expression e1> || <Expression e2>` :
			return checkOrExpression(cs,exp,e1,e2);
		
		// Match
		case `<Pattern p> := <Expression e>` :
			return checkMatchExpression(cs,exp,p,e);

		// NoMatch
		case `<Pattern p> !:= <Expression e>` :
			return checkNoMatchExpression(cs,exp,p,e);

		// Enumerator
		case `<Pattern p> <- <Expression e>` :
			return checkEnumeratorExpression(cs,exp,p,e);
		
		// Set Comprehension
		case (Expression) `{ <{Expression ","}+ el> | <{Expression ","}+ er> }` :
			return checkSetComprehensionExpression(cs,exp,el,er);

		// List Comprehension
		case (Expression) `[ <{Expression ","}+ el> | <{Expression ","}+ er> ]` :
			return checkListComprehensionExpression(cs,exp,el,er);
		
		// Map Comprehension
		case (Expression) `( <Expression ef> : <Expression et> | <{Expression ","}+ er> )` :
			return checkMapComprehensionExpression(cs,exp,ef,et,er);
		
		// Reducer 
		case `( <Expression ei> | <Expression er> | <{Expression ","}+ egs> )` :
			return checkReducerExpression(cs,exp,ei,er,egs);
		
		// It
		case `it` : {
		        <cs, l1> = makeFreshTypes(cs,1); t1 = l1[0];
			Constraint c1 = makeIsTypeConstraint(exp,t1);
			Constraint c2 = DefinedBy(t1,exp@nameIds);
			cs.constraints = cs.constraints + { c1, c2 };
			return cs;
		}
			
		// All 
		case `all ( <{Expression ","}+ egs> )` :
			return checkAllExpression(cs,exp,egs);

		// Any 
		case `any ( <{Expression ","}+ egs> )` :
			return checkAnyExpression(cs,exp,egs);
	}

	// Logic for handling maps -- we cannot directly match them, so instead we need to pick apart the tree
	// representing the map.
        // exp[0] is the production used, exp[1] is the actual parse tree contents
	if (prod(_,_,attrs([_*,term(cons("Map")),_*])) := exp[0])
	        return checkMapExpression(cs,exp);
}

//
// Handle string templates
//
public RType checkStringTemplate(StringTemplate s) {
	switch(s) {
		case `for (<{Expression ","}+ gens>) { <Statement* pre> <StringMiddle body> <Statement* post> }` : {
			set[RType] res = { e@rtype | e <- gens } + { getInternalStatementType(st@rtype) | st <- pre } + { getInternalStatementType(st@rtype) | st <- post };
		        list[Tree] ipl = prodFilter(body, 
                                bool(Production prd) { return prod(_,\cf(sort("Expression")),_) := prd || prod(_,\cf(sort("StringTemplate")),_) := prd; });
			for (ipe <- ipl) {
			        if (`<Expression ipee>` := ipe)
			                res = res + ipee@rtype;
				else if (`<StringTemplate ipet>` := ipe)
				        res = res + ipet@rtype;
			}
			if (checkForFail(res)) return collapseFailTypes(res);
			return makeStrType();
		}

		case `if (<{Expression ","}+ conds>) { <Statement* pre> <StringMiddle body> <Statement* post> }` : {
			set[RType] res = { e@rtype | e <- conds } + { getInternalStatementType(st@rtype) | st <- pre } + { getInternalStatementType(st@rtype) | st <- post };
		        list[Tree] ipl = prodFilter(body, 
                                bool(Production prd) { return prod(_,\cf(sort("Expression")),_) := prd || prod(_,\cf(sort("StringTemplate")),_) := prd; });
			for (ipe <- ipl) {
			        if (`<Expression ipee>` := ipe)
			                res = res + ipee@rtype;
				else if (`<StringTemplate ipet>` := ipe)
				        res = res + ipet@rtype;
			}
			if (checkForFail(res)) return collapseFailTypes(res);
			return makeStrType();
		}

		case `if (<{Expression ","}+ conds>) { <Statement* preThen> <StringMiddle bodyThen> <Statement* postThen> } else { <Statement* preElse> <StringMiddle bodyElse> <Statement* postElse> }` : {
			set[RType] res = { e@rtype | e <- conds } + { getInternalStatementType(st@rtype) | st <- preThen } + 
                                         { getInternalStatementType(st@rtype) | st <- postThen } +
                                         { getInternalStatementType(st@rtype) | st <- preElse } + { getInternalStatementType(st@rtype) | st <- postElse };
		        list[Tree] ipl = prodFilter(bodyThen, 
                                bool(Production prd) { return prod(_,\cf(sort("Expression")),_) := prd || prod(_,\cf(sort("StringTemplate")),_) := prd; });
			for (ipe <- ipl) {
			        if (`<Expression ipee>` := ipe)
			                res = res + ipee@rtype;
				else if (`<StringTemplate ipet>` := ipe)
				        res = res + ipet@rtype;
			}
		        ipl = prodFilter(bodyElse, 
                                bool(Production prd) { return prod(_,\cf(sort("Expression")),_) := prd || prod(_,\cf(sort("StringTemplate")),_) := prd; });
			for (ipe <- ipl) {
			        if (`<Expression ipee>` := ipe)
			                res = res + ipee@rtype;
				else if (`<StringTemplate ipet>` := ipe)
				        res = res + ipet@rtype;
			}
			if (checkForFail(res)) return collapseFailTypes(res);
			return makeStrType();
		}

		case `while (<Expression cond>) { <Statement* pre> <StringMiddle body> <Statement* post> }` : {
			set[RType] res = { getInternalStatementType(st@rtype) | st <- pre } + { getInternalStatementType(st@rtype) | st <- post } + cond@rtype;
		        list[Tree] ipl = prodFilter(body, 
                                bool(Production prd) { return prod(_,\cf(sort("Expression")),_) := prd || prod(_,\cf(sort("StringTemplate")),_) := prd; });
			for (ipe <- ipl) {
			        if (`<Expression ipee>` := ipe)
			                res = res + ipee@rtype;
				else if (`<StringTemplate ipet>` := ipe)
				        res = res + ipet@rtype;
			}
			if (checkForFail(res)) return collapseFailTypes(res);
			return makeStrType();
		}

		case `do { <Statement* pre> <StringMiddle body> <Statement* post> } while (<Expression cond>)` : {
			set[RType] res = { getInternalStatementType(st@rtype) | st <- pre } + { getInternalStatementType(st@rtype) | st <- post } + cond@rtype;
		        list[Tree] ipl = prodFilter(body, 
                                bool(Production prd) { return prod(_,\cf(sort("Expression")),_) := prd || prod(_,\cf(sort("StringTemplate")),_) := prd; });
			for (ipe <- ipl) {
			        if (`<Expression ipee>` := ipe)
			                res = res + ipee@rtype;
				else if (`<StringTemplate ipet>` := ipe)
				        res = res + ipet@rtype;
			}
			if (checkForFail(res)) return collapseFailTypes(res);
			return makeStrType();
		}
	}

	throw "Unexpected string template syntax at location <s@\loc>, no match";
}

//
// Check individual cases
//
public RType checkCase(Case c) {
	switch(c) {
		case `case <PatternWithAction p>` : {
			
			// If insert is used anywhere in this case pattern, find the type being inserted and
			// check to see if it is correct.
			// TODO: This will only check the first insert. Need to modify logic to handle all
			// insert statements that are in this visit, but NOT in a nested visit. It may be
			// easiest to mark visit boundaries during the symbol table construction, since that
			// is done in a top-down manner.
			RType caseType = getCasePatternType(c);
			set[RType] failures = { };
			top-down-break visit(p) {
				case (Expression) `<Label l> <Visit v>` : 0; // no-op
				
				case (Statement) `<Label l> <Visit v>` : 0; // no-op
				
				case Statement ins : `insert <DataTarget dt> <Statement s>` : {
					RType stmtType = getInternalStatementType(s@rtype);
					if (! subtypeOf(stmtType, caseType)) {
						failures += makeFailType("Type of insert, <prettyPrintType(stmtType)>, does not match type of case, <prettyPrintType(caseType)>", s@\loc);
					}
				} 
			}
			RType retType = (size(failures) == 0) ? p@rtype : collapseFailTypes(failures);
			return retType;
		}
		
		case `default : <Statement b>` : {
			return getInternalStatementType(b@rtype);
		}
	}
}

//
// Check assignables.
//
// NOTE: This system uses a pair of types, referred to below as the "part type" and the
// "whole type". This is because, in cases like x.f = 3, we need to know the entire
// type of the resulting value, here the type of x, as well as the type of the part of
// x being assigned into, here the type of field f on x. In this example, the type of x
// is the whole type, while the type of the field f is the part type.
//

//
// TODO: Not sure what to return here, since, for a tuple, this could be any of the
// types of the tuple fields. So, for tuples, just return the lub right now, which will
// let the test pass. Returning void would be more conservative, but then this would
// never work for tuples.
//
// NOTE: Doing this for relations with arity > 2 doesn't seem to work right now in the
// interpreter. I'm not sure if this is by design or by accident.
//
// TODO: Review this code, it's complex and could have hidden bugs...
//
public RType checkSubscriptAssignable(Assignable ap, Assignable a, Expression e) {
	if (checkForFail({a@rtype, e@rtype})) return collapseFailTypes({a@rtype, e@rtype});

	RType partType = getPartType(a@rtype);
	RType wholeType = getWholeType(a@rtype);

	if (isTupleType(partType)) {
		return makeAssignableType(wholeType, lubList(getTupleFields(partType))); 		
	} else if (isRelType(partType)) {
		list[RType] relTypes = getRelFields(partType);
		RType relLeftType = relTypes[0];
		list[RType] resultTypes = tail(relTypes);
		if (! (subtypeOf(e@rtype, relLeftType))) return makeFailType("The subscript type <prettyPrintType(e@rtype)> must be a subtype of the first project of the relation type, <prettyPrintType(relLeftType)>", ap@\loc);
		if (size(resultTypes) == 1)
			return makeAssignableType(wholeType, makeSetType(resultTypes[0]));
		else
			return makeAssignableType(wholeType, makeRelType(resultTypes));		
	} else if (isMapType(partType)) {
		RType domainType = getMapDomainType(partType);
		if (! subtypeOf(e@rtype, domainType)) return makeFailType("The subscript type <prettyPrintType(e@rtype)> must be a subtype of to the domain type <prettyPrintType(domainType)>", ap@\loc);
		return makeAssignableType(wholeType, getMapRangeType(partType));
	}  else if (isNodeType(partType)) {
		return makeAssignableType(wholeType, makeValueType());
	} else if (isListType(partType)) {
		if (! isIntType(e@rtype) ) 
                        return makeFailType("Subscripts on lists must be of type int, not type <prettyPrintType(e@rtype)>", ap@\loc);
		return makeAssignableType(wholeType, getListElementType(partType));		
	} else {
		return makeFailType("Subscript not supported on type <prettyPrintType(partType)>", ap@\loc);
	}
}

//
// A field access assignable is of the form a.f, where a is another assignable. The whole
// type is just the type of a, since f is a field of a and ultimately we will return an
// a as the final value. The part type is the type of f, since this is the "part" being
// assigned into. We check for the field on the part type of the assignable, since the
// assignable could be of the form a.f1.f2.f3, or a[n].f, etc, and the type with the field 
// is not a as a whole, but a.f1.f2, or a[n], etc.
//
public RType checkFieldAccessAssignable(Assignable ap, Assignable a, Name n) {
	if (checkForFail({a@rtype})) return collapseFailTypes({a@rtype});
	RType partType = getPartType(a@rtype); // The "part" of a which contains the field
	RType wholeType = getWholeType(a@rtype); // The overall type of all of a
	RType fieldType = getFieldType(partType, convertName(n), globalSymbolTable, ap@\loc);
	if (isFailType(fieldType)) return fieldType;
	return makeAssignableType(wholeType, fieldType); 
}

//
// An if-defined-or-default assignable is of the form a ? e, where a is another assignable
// and e is the default value. We propagate up both the whole and part types, since this
// impacts neither. For instance, if we say a.f1.f2 ? [ ], we are still going to assign into
// f2, so we need that information. However, we need to check to make sure that [ ] could be
// assigned into f2, since it will actually be the default value given for it if none exists.
//		
public RType checkIfDefinedOrDefaultAssignable(Assignable ap, Assignable a, Expression e) {
	if (isFailType(a@rtype) || isFailType(e@rtype)) return collapseFailTypes({ a@rtype, e@rtype });
	RType partType = getPartType(a@rtype); // The "part" being checked for definedness
	RType wholeType = getWholeType(a@rtype); // The "whole" being assigned into
	if (!subtypeOf(e@rtype,partType)) 
                return makeFailType("The type of <e>, <prettyPrintType(e@rtype)>, is not a subtype of the type of <a>, <prettyPrintType(partType)>",ap@\loc);
	return makeAssignableType(wholeType, partType); // Propagate up the current part and whole once we've made sure the default is valid
}

//
// An annotation assignable is of the form a @ n, where a is another assignable and
// n is the annotation name on this assignable. The whole type for a is propagated
// up, with the new part type being the type of this annotation, which should be a valid
// annotation on the current part type.
//
// TODO: Ensure that annotation n is a valid annotation on the part type of a
//
public RType checkAnnotationAssignable(Assignable ap, Assignable a, Name n) {
	if (isFailType(a@rtype)) return collapseFailTypes({ a@rtype });
	RType partType = getPartType(a@rtype);
	RType wholeType = getWholeType(a@rtype);
	RType rt = getTypeForName(globalSymbolTable, convertName(n), n@\loc);
	if (isFailType(rt)) return rt;
	return makeAssignableType(wholeType, rt);
}

//
// A tuple assignable is of the form < a_1, ..., a_n >, where a_1 ... a_n are
// other assignables. For tuple assignables, the part type is a tuple of the
// part types of the constituent assignables, while the whole type is the tuple
// of the whole types of the constituent assignables. This is because we will
// ultimately return a tuple made up of the various assignables, but we will
// also assign into the part types of each of the assignables.
//		
public RType checkTrivialTupleAssignable(Assignable ap, Assignable a) {
	list[Assignable] alist = [ a ];
	if (checkForFail({ ai@rtype | ai <- alist })) return collapseFailTypes({ ai@rtype | ai <- alist });
	RType wholeType = makeTupleType([ getWholeType(ai@rtype) | ai <- alist]);
	RType partType = makeTupleType([ getPartType(ai@rtype) | ai <- alist]);
	return makeAssignableType(wholeType,partType);
}

public RType checkTupleAssignable(Assignable ap, Assignable a, {Assignable ","}* al) {
	list[Assignable] alist = [ a ] + [ ai | ai <- al];
	if (checkForFail({ ai@rtype | ai <- alist })) return collapseFailTypes({ ai@rtype | ai <- alist });
	RType wholeType = makeTupleType([ getWholeType(ai@rtype) | ai <- alist]);
	RType partType = makeTupleType([ getPartType(ai@rtype) | ai <- alist]);
	return makeAssignableType(wholeType,partType);
}

//
// Check assignables.
//
public RType checkAssignable(Assignable a) {
	switch(a) {
		// Variable _
		case (Assignable)`_` : {
			RType rt = getTypeForName(globalSymbolTable, RSimpleName("_"), a@\loc);
			return makeAssignableType(rt,rt); 
		}

		// Variable with an actual name
		case (Assignable)`<QualifiedName qn>` : {
			RType rt = getTypeForName(globalSymbolTable, convertName(qn), qn@\loc);
			return makeAssignableType(rt,rt); 
		}
		
		// Subscript
		case `<Assignable al> [ <Expression e> ]` : {
			return checkSubscriptAssignable(a,al,e);
		}
		
		// Field Access
		case `<Assignable al> . <Name n>` : {
			return checkFieldAccessAssignable(a,al,n);
		}
		
		// If Defined or Default
		case `<Assignable al> ? <Expression e>` : {
			return checkIfDefinedOrDefaultAssignable(a,al,e);
		}
		
		// Annotation
		case `<Assignable al> @ <Name n>` : {
			return checkAnnotationAssignable(a,al,n);
		}
		
		// Tuple, with just one element
		case (Assignable)`< <Assignable ai> >` : {
			return checkTupleAssignable(a, ai);
		}

		// Tuple, with multiple elements
		case (Assignable)`< <Assignable ai>, <{Assignable ","}* al> >` : {
			return checkTupleAssignable(a, ai, al);
		}
	}
}

//
// Given an actual type rt and an assignable a, recurse the structure of a, assigning the correct parts of
// rt to any named parts of a. For instance, in an assignment like x = 5, if x has an inference type it will
// be assigned type int, while in an assignment like <a,b> = <true,4>, a would be assigned type bool
// while b would be assigned type int (again, assuming they are both inferrence variables). The return
// type is the newly-computed type of the assignable, with inference vars bound to concrete types.
//
// NOTE: This functionality now does much more checking, similarly to the bind logic in patterns,
// since we also now do all the subtype checking here as well.
//
public RType bindInferredTypesToAssignable(RType rt, Assignable a) {
	RType partType = getPartType(a@rtype);
	RType wholeType = getWholeType(a@rtype);
	
	switch(a) {
		// Anonymous name (variable name _)
	        // When assigning into _, we make sure that either the type assigned to _ is still open or that the type we are
		// assigning is a subtype. Realistically, it should always be open, since each instance of _ is distinct.
		case (Assignable)`_` : {
		        RType varType = getTypeForNameLI(globalSymbolTable, RSimpleName("_"), a@\loc);
		        if (isInferredType(varType)) {
			        RType t = globalSymbolTable.inferredTypeMap[getInferredTypeIndex(varType)];
				if (isInferredType(t)) {
				        updateInferredTypeMappings(t,rt);
					return rt;
				} else if (! equivalent(t,rt)) {
				        return makeFailType("Attempt to bind multiple types to the same implicitly typed anonymous name: already bound <prettyPrintType(t)>, attempting to bind <prettyPrintType(rt)>", a@\loc);
				} else {
				        return rt;
				}
			} else {
			        if (subtypeOf(rt, varType)) {
				        return varType;
				} else {
				        return makeFailType("Type <prettyPrintType(rt)> must be a subtype of the type of <a>, <prettyPrintType(varType)>",a@\loc);
				}
			}
		}

		// Qualified Name (variable name)
		// When assigning into a name, we make sure that either the type assigned to the name is still open or that the
		// type we are assigning is a subtype.
		// NOTE: This includes a terrible hack to handle situations such as x = { }; x = { 1 } which don't work right now.
		// This allows container (set/list/map) types to be bumped up from void to non-void element types. However, this
		// is not sound, so we need to instead divise a better way to handle this, for instance by using constraint systems.
		// so, TODO: Fix this!
		case (Assignable)`<QualifiedName qn>` : {
		        RType varType = getTypeForNameLI(globalSymbolTable,convertName(qn),qn@\loc);
			if (isInferredType(varType)) {
				RType t = globalSymbolTable.inferredTypeMap[getInferredTypeIndex(varType)];
				if (isInferredType(t)) {
					updateInferredTypeMappings(t,rt);
					return rt;
				} else if ( (isListType(t) && isVoidType(getListElementType(t)) && isListType(rt)) || 
                                            (isSetType(t) && isVoidType(getSetElementType(t)) && isSetType(rt)) ||
                                            (isMapType(t) && isVoidType(getMapDomainType(t)) && isVoidType(getMapRangeType(t)) && isMapType(rt))) {
				        updateInferredTypeMappings(varType,rt);
					return rt;
				} else if ( (isListType(t) && isListType(rt) && isVoidType(getListElementType(rt))) ||
				            (isSetType(t) && isSetType(rt) && isVoidType(getSetElementType(rt))) ||
					    (isMapType(t) && isMapType(rt) && isVoidType(getMapDomainType(rt)) && isVoidType(getMapRangeType(rt)))) {
					return t;
			        } else if (! equivalent(t,rt)) {
				        return makeFailType("Attempt to bind multiple types to the same implicitly typed name <qn>: already bound <prettyPrintType(t)>, attempting to bind <prettyPrintType(rt)>", qn@\loc);
			        } else {
				        return rt; 
			        }
			} else {
			        if (subtypeOf(rt, varType)) {
				        return varType;
				} else {
				        return makeFailType("Type <prettyPrintType(rt)> must be a subtype of the type of <a>, <prettyPrintType(varType)>",a@\loc);
				}
			}
		}
		
		// Subscript
		// Check to see if the part type of the assignable matches the binding type. It doesn't make
		// sense to push this any further down, since the type we have to compare against is just the
		// part type, not the whole type. Checking the assignable already checked the structure of
		// the whole type.
		case `<Assignable al> [ <Expression e> ]` : {
		        RType partType = getPartType(a@rtype);
			if (! subtypeOf(rt, partType))
			        return makeFailType("Error, cannot assign expression of type <prettyPrintType(rt)> to subscript with type <prettyPrintType(partType)>", a@\loc);
			return getWholeType(a@rtype);
		}
		
		// Field Access
		// Check to see if the part type of the assignable matches the binding type. It doesn't make
		// sense to push this any further down, since the type we have to compare against is just the
		// part type, not the whole type.
		case `<Assignable al> . <Name n>` : {
		        RType partType = getPartType(a@rtype);
			if (! subtypeOf(rt, partType))
			        return makeFailType("Error, cannot assign expression of type <prettyPrintType(rt)> to field with type <prettyPrintType(partType)>", 
                                                    a@\loc);
			return getWholeType(a@rtype);
		}
		
		// If Defined or Default
		// This just pushes the binding down into the assignable on the left-hand
		// side of the ?, the default expression has no impact on the binding.
		case `<Assignable al> ? <Expression e>` : {
			return bindInferredTypesToAssignable(rt, al);
		}
		
		// Annotation
		// Check to see if the part type of the assignable matches the binding type. It doesn't make
		// sense to push this any further down, since the type we have to compare against is just the
		// part type, not the whole type.
		case `<Assignable al> @ <Name n>` : {
		        RType partType = getPartType(a@rtype);
			if (! subtypeOf(rt, partType))
			        return makeFailType("Error, cannot assign expression of type <prettyPrintType(rt)> to field with type <prettyPrintType(partType)>", 
                                                    a@\loc);
			return getWholeType(a@rtype);
		}
		
		// Tuple
		// To be correct, the type being bound into the assignable also needs to be a tuple
		// of the same length. If this is true, the bind recurses on each tuple element.
		// If not, a failure type, indicating the type of failure (arity mismatch, or type of
		// assignable not a tuple) has occurred.
		case (Assignable)`< <Assignable ai> >` : {
			list[Assignable] alist = [ai];
			if (isTupleType(rt) && getTupleFieldCount(rt) == size(alist)) {
				list[RType] tupleFieldTypes = getTupleFields(rt);
				results = [bindInferredTypesToAssignable(tft,ali) | n <- [0..(getTupleFieldCount(rt)-1)], tft := tupleFieldTypes[n], ali := alist[n]];
				failures = { result | result <- results, isFailType(result) };
				if (size(failures) > 0) return collapseFailTypes(failures);
				return makeTupleType(results);
			} else if (!isTupleType(rt)) {
				return makeFailType("Type mismatch: cannot assign non-tuple type <prettyPrintType(rt)> to <a>", a@\loc);
			} else {
				return makeFailType("Arity mismatch: cannot assign tuple of length <getTupleFieldCount(rt)> to <a>", a@\loc);
			}
		}

		case (Assignable)`< <Assignable ai>, <{Assignable ","}* al> >` : {
			list[Assignable] alist = [ai] + [ ali | ali <- al ];
			if (isTupleType(rt) && getTupleFieldCount(rt) == size(alist)) {
				list[RType] tupleFieldTypes = getTupleFields(rt);
				results = [bindInferredTypesToAssignable(tft,ali) | n <- [0..(getTupleFieldCount(rt)-1)], tft := tupleFieldTypes[n], ali := alist[n]];
				failures = { result | result <- results, isFailType(result) };
				if (size(failures) > 0) return collapseFailTypes(failures);
				return makeTupleType(results);
			} else if (!isTupleType(rt)) {
				return makeFailType("Type mismatch: cannot assign non-tuple type <prettyPrintType(rt)> to <a>", a@\loc);
			} else {
				return makeFailType("Arity mismatch: cannot assign tuple of length <getTupleFieldCount(rt)> to <a>", a@\loc);
			}
		}
		
	}
}

//
// Check local variable declarations. The variables themselves have already been checked, so we just
// need to collect any possible failures here.
//
public RType checkLocalVarItems(Statement sp, {Variable ","}+ vs) {
	set[RType] localTypes = { v@rtype | v <- vs };
	return makeStatementType(checkForFail(localTypes) ? collapseFailTypes(localTypes) : makeVoidType());
}

//
// Check catch clauses in exception handlers
//
public RType checkCatch(Catch c) {
	switch(c) {
		case `catch : <Statement b>` : {
			return b@rtype;
		}
		
		// TODO: Pull out into own function for consistency
		case `catch <Pattern p> : <Statement b>` : {
			
			if (checkForFail({ p@rtype, getInternalStatementType(b@rtype) }))
				return makeStatementType(collapseFailTypes({ p@rtype, getInternalStatementType(b@rtype) }));
			else {
				RType boundType = bindInferredTypesToPattern(p@rtype, p);
				if (isFailType(boundType)) return makeStatementType(boundType);
				return b@rtype;
			}
		}
	}
}

public RType checkLabel(Label l) {
	if ((Label)`<Name n> :` := l && hasRType(globalSymbolTable, n@\loc)) {
		RType rt = getTypeForName(globalSymbolTable, convertName(n), n@\loc);
		return rt;
	}
	return makeVoidType();
}

//
// TODO: Extract common code in each case into another function
//
// TODO: Any way to verify that types of visited sub-parts can properly be types
// of subparts of the visited expression?
//
// TODO: Put checks back in, taken out for now since they are adding useless "noise"
//
public RType checkVisit(Visit v) {
	switch(v) {
		case `visit (<Expression se>) { <Case+ cs> }` : {
			set[RType] caseTypes = { c@rtype | c <- cs };
			if (checkForFail( caseTypes + se@rtype )) return collapseFailTypes(caseTypes + se@rtype);
			RType caseLubType = lubSet(caseTypes);
			//if (subtypeOf(caseLubType, se@rtype)) 
				return se@rtype;
			//else
				//return makeFailType("Visit cases must all be subtypes of the type of the visited expression",v@\loc); 
		}
		
		case `<Strategy st> visit (<Expression se>) { <Case+ cs> }` : {
			set[RType] caseTypes = { c@rtype | c <- cs };
			if (checkForFail( caseTypes + se@rtype )) return collapseFailTypes(caseTypes + se@rtype);
			RType caseLubType = lubSet(caseTypes);
			//if (subtypeOf(caseLubType, se@rtype))
				return se@rtype;
			//else
				//return makeFailType("Visit cases must all be subtypes of the type of the visited expression",v@\loc); 
		}		
	}
}

//
// Check the type of a reified type pattern.
//
// TODO: Should add additional checks, including an arity check, since you can only have
// one type inside the pattern (even though the syntax allows more).
//
// TODO: Need to expand type so we know that ADTs, etc are marked.
//
// TODO: pl should all have type type
//
public RType checkReifiedTypePattern(Pattern pp, Type t, {Pattern ","}* pl) {
	if (checkForFail({ p@rtype | p <- pl })) return collapseFailTypes({ p@rtype | p <- pl });
	return makeReifiedType(convertType(t), [ p@rtype | p <- pl ]);
}

//
// TODO: this takes a strict view of what a static type error is for patterns. We
// may want a more relaxed version, where if someone uses a pattern that could never
// match we just let it go, since this won't cause a runtime error (but it may be
// useful for the user to know)
//
public RType checkCallOrTreePattern(Pattern pp, Pattern pc, {Pattern ","}* ps) {
	list[RType] matches = getCallOrTreePatternType(pp, pc, ps);
	if (size(matches) > 1) { 
		return makeFailType("There are multiple possible matches for this constructor pattern. Please add additional type information. Matches: <prettyPrintTypeListWLoc(matches)>");
	} else if (size(matches) == 1 && rt := head(matches) && isFailType(rt)) {
		return rt;
	} else if (size(matches) == 1 && rt := head(matches) && isConstructorType(rt)) {
		RType boundType = bindInferredTypesToPattern(rt, pp[@rtype=getConstructorResultType(rt)][@fctype=rt]);
		return rt;
	} else {
		throw "Unexpected situation, checkCallOrTreePattern, found the following matches: <matches>";
	}
}

//
// Find the type of a call or tree pattern. This has to be the use of a constructor -- functions
// invocations can't be used in patterns. So, this function needs to figure out which constructor
// is being used. Note that this is a local determination, i.e., we don't currently allow
// information from the surrounding context to help. So, we have to be able to determine the type
// just from looking at the constructor name and its pattern.
//
// TODO: See if we need to allow contextual information. We may need this in cases where (for instance)
// we have two constructors C of two different ADTs, and we want to be able to use matches such
// as C(_) :=.
//
// TODO: See how much error information we can gather. Currently, we just return if pc or ps
// contains any failures. However, in some situations we could get more error info, for instance
// if pc has a normal type but there are no constructors with that name that take the given
// number of parameters.
//
public list[RType] getCallOrTreePatternType(Pattern pp, Pattern pc, {Pattern ","}* ps) {
	// First, if we have any failures, just propagate those upwards, don't bother to
	// check the rest of the call. 
	if (checkForFail({ pc@rtype } + { p@rtype | p <- ps }))
		return [ collapseFailTypes({ pc@rtype } + { p@rtype | p <- ps }) ];
			
	// Set up the possible alternatives. We will treat the case of no overloads as a trivial
	// case of overloading with only one alternative.
	set[ROverloadedType] alternatives = isOverloadedType(pc@rtype) ? getOverloadOptions(pc@rtype) : { ( (pc@rtype@at)? ) ? ROverloadedTypeWithLoc(pc@rtype,pc@rtype@at) :  ROverloadedType(pc@rtype) };
	
	// Now, try each alternative, seeing if one matches. Note: we could have multiple matches (for
	// instance, if we have inference vars in a constructor), even if the instances themselves
	// did not overlap. e.g., S(int,bool) and S(str,loc) would not overlap, but both would
	// be acceptable alternatives for S(x,y) := e. At this point, we can just return both; the caller
	// can decide if this is acceptable or not.
	list[RType] matches = [ ];
	set[RType] failures = { };
	list[Pattern] actuals = [ p | p <- ps ];
		
	for (a <- alternatives) {
	        bool typeHasLoc = ROverloadedTypeWithLoc(_,_) := a;
		RType fcType = typeHasLoc ?  a.overloadType[@at=a.overloadLoc] : a.overloadType;
		
		if (isConstructorType(fcType)) {
			list[RType] formals = getConstructorArgumentTypes(fcType);

			// NOTE: We do not currently support varargs constructors.
			if (size(formals) == size(actuals)) {
				set[RType] localFailures = { };
				for (idx <- domain(actuals)) {
					RType actualType = actuals[idx]@rtype;
					RType formalType = formals[idx];
					if (! subtypeOf(actualType, formalType)) {
						localFailures = localFailures + makeFailType("Could not use alternative <prettyPrintType(fcType)><typeHasLoc ? " defined at <fcType@at>" : "">: pattern type for pattern argument <actuals[idx]> is <prettyPrintType(actuals[idx]@rtype)> but argument type is <prettyPrintType(formalType)>",actuals[idx]@\loc);
					}
				}
				if (size(localFailures) > 0) {
					failures = failures + localFailures;
				} else {
					matches = matches + ( typeHasLoc ? fcType[@at=a.overloadLoc ] : fcType ); 
				}
			} else {
				failures = failures + makeFailType("Could not use alternative <prettyPrintType(fcType)><typeHasLoc ? " defined at <fcType@at>" : "">: constructor accepts <size(formals)> arguments while pattern <pp> has arity <size(actuals)>", pp@\loc);
			}
		} else {
			failures = failures + makeFailType("Type <prettyPrintType(fcType)><typeHasLoc ? " defined at <fcType@at>" : ""> is not a constructor",pp@\loc);
		}
	}

	// If we found a match, use that. If not, send back the failures instead. The matches take precedence
	// since failures can result from trying all possible constructors in an effort to find the matching
	// constructor, which is the constructor we will actually use.	
	if (size(matches) > 0)
		return matches;
	else
		return [ collapseFailTypes(failures) ];
}

//
// This handles returning the correct type for a pattern in a list. There are several cases:
//
// 1. A name that represents a list. This can be treated like an element of the list, since [1,x,2], where x
//    is [3,4], just expands to [1,3,4,2]. More formally, in these cases, if list(te) := t, we return te.
//
// 2. A pattern that is explicitly given a name or typed name (name becomes patterns) or guarded pattern. Here
//    we look at the next level of pattern and treat it according to these rules.
//
// 3. All other patterns. Here we just return the type of the pattern.
//  
public RType getPatternTypeForList(Pattern pat) {
	if ((Pattern)`<Name n>` := pat || (Pattern)`<QualifiedName qn>` := pat || (Pattern)`<Type t><Name n>` := pat || (Pattern)`<QualifiedName qn> *` := pat) {
	        RType patType = pat@rtype;
		if (isListType(patType)) return getListElementType(patType);
		if (isContainerType(patType)) return getContainerElementType(patType);    
	} else if ((Pattern)`<Name n> : <Pattern p>` := pat || (Pattern)`<Type t> <Name n> : <Pattern p>` := pat || (Pattern)`[ <Type t> ] <Pattern p>` := pat) {
	    return getPatternTypeForList(p);
	}
	return pat@rtype;
}

//
// Indicates if a variable is a list container variable. Uses the same rules as the above.
// 
public bool isListContainerVar(Pattern pat) {
	if ((Pattern)`<Name n>` := pat || (Pattern)`<QualifiedName qn>` := pat || (Pattern)`<Type t><Name n>` := pat || (Pattern)`<QualifiedName qn> *` := pat) {
	        RType patType = pat@rtype;
		if (isListType(patType)) return true;
		if (isContainerType(patType)) return true;    
	} else if ((Pattern)`<Name n> : <Pattern p>` := pat || (Pattern)`<Type t> <Name n> : <Pattern p>` := pat || (Pattern)`[ <Type t> ] <Pattern p>` := pat) {
	    return isListContainerVar(p);
	}
	return false;
}

//
// Determine the type of a list pattern. This is based on the types of its components.
// It may not be possible to determine an exact type, in which case we delay the
// computation of the lub by returning a list of lub type.
//
public RType checkListPattern(Pattern pp, {Pattern ","}* ps) {
	if (checkForFail({ p@rtype | p <- ps })) return collapseFailTypes({ p@rtype | p <- ps });
	
	// Get the types in the list, we need to watch for inferrence types since we need
	// to handle those separately. We also need to match for lub types that are
	// propagating up from nested patterns.
	list[RType] patTypes = [ getPatternTypeForList(p) | p <- ps ];
	list[RType] patTypesI = [ t | t <- patTypes, hasDeferredTypes(t) ];
	
	if (size(patTypesI) > 0) {
		return makeListType(makeLubType(patTypes));
	} else {
		return makeListType(lubList(patTypes));
	}
}

//
// This handles returning the correct type for a pattern in a set. This uses the same rules
// given above for getPatternTypeForList, so refer to that for more details.
//  
public RType getPatternTypeForSet(Pattern pat) {
	if ((Pattern)`<Name n>` := pat || (Pattern)`<QualifiedName qn>` := pat || (Pattern)`<Type t><Name n>` := pat || (Pattern)`<QualifiedName qn> *` := pat) {
	        RType patType = pat@rtype;
		if (isSetType(patType)) return getSetElementType(patType);
		if (isContainerType(patType)) return getContainerElementType(patType);    
	} else if ((Pattern)`<Name n> : <Pattern p>` := pat || (Pattern)`<Type t> <Name n> : <Pattern p>` := pat || (Pattern)`[ <Type t> ] <Pattern p>` := pat) {
	    return getPatternTypeForSet(p);
	}
	return pat@rtype;
}

//
// Indicates if a variable is a set container variable. Uses the same rules as the above.
// 
public bool isSetContainerVar(Pattern pat) {
	if ((Pattern)`<Name n>` := pat || (Pattern)`<QualifiedName qn>` := pat || (Pattern)`<Type t><Name n>` := pat || (Pattern)`<QualifiedName qn> *` := pat) {
	        RType patType = pat@rtype;
		if (isSetType(patType)) return true;
		if (isContainerType(patType)) return true;    
	} else if ((Pattern)`<Name n> : <Pattern p>` := pat || (Pattern)`<Type t> <Name n> : <Pattern p>` := pat || (Pattern)`[ <Type t> ] <Pattern p>` := pat) {
	    return isSetContainerVar(p);
	}
	return false;
}		

//
// Determine the type of a set pattern. This is based on the types of its components.
// It may not be possible to determine an exact type, in which case we delay the
// computation of the lub by returning a set of lub type.
//
public RType checkSetPattern(Pattern pp, {Pattern ","}* ps) {
	if (checkForFail({ p@rtype | p <- ps })) return collapseFailTypes({ p@rtype | p <- ps });

	// Get the types in the list, we need to watch for inferrence types since we need
	// to handle those separately.  We also need to match for lub types that are
	// propagating up from nested patterns.
	list[RType] patTypes = [ getPatternTypeForSet(p) | p <- ps ];
	list[RType] patTypesI = [ t | t <- patTypes, hasDeferredTypes(t)];
	
	if (size(patTypesI) > 0) {
		return makeSetType(makeLubType(patTypes));
	} else {
		return makeSetType(lubList(patTypes));
	}
}

//
// Check the type of a trivial (one element) tuple pattern, which is either
// tuple[t] when pi : t or fail when pi has a fail type.
//
public RType checkTrivialTuplePattern(Pattern pp, Pattern pi) {
	set[Pattern] pset = {pi};
	if (checkForFail({p@rtype | p <- pset})) return collapseFailTypes({p@rtype | p <- pset});
	return makeTupleType([ p@rtype | p <- pset]);
}

//
// Check the type of a non-trivial (multiple element) tuple pattern.
//
public RType checkTuplePattern(Pattern pp, Pattern pi, {Pattern ","}* ps) {
	list[Pattern] plist = [pi] + [ p | p <- ps ];
	if (checkForFail({p@rtype | p <- plist})) return collapseFailTypes({p@rtype | p <- plist});
	return makeTupleType([ p@rtype | p <- plist]);
}

//
// Check the variable becomes pattern. Note that we don't bind the pattern type to
// the name here, since we don't actually have a real type yet for the pattern -- it
// itself could contain inference vars, etc. We wait until the bind function is
// called to do this.
//
public RType checkVariableBecomesPattern(Pattern pp, Name n, Pattern p) {
	RType rt = getTypeForName(globalSymbolTable, convertName(n), n@\loc);
	if (checkForFail({ rt, p@rtype })) return collapseFailTypes({ rt, p@rtype });
	return p@rtype;
}

//
// Check the typed variable becomes pattern. We require that the pattern type is
// a subtype of the name type, since otherwise we cannot assign it. Note: we ignore
// the type t here since the process of building the symbol table already assigned
// this type to n.
//
public RType checkTypedVariableBecomesPattern(Pattern pp, Type t, Name n, Pattern p) {
	RType rt = getTypeForName(globalSymbolTable, convertName(n), n@\loc);
	if (checkForFail({ rt, p@rtype })) return collapseFailTypes({ rt, p@rtype });
	if (! subtypeOf(p@rtype, rt)) return makeFailType("Type of pattern, <prettyPrintType(p)>, must be a subtype of the type of <n>, <prettyPrintType(rt)>",pp@\loc);
	return rt;
}

//
// Check the guarded pattern type. The result will be of that type, since it must be to match
// (else the match would fail). We return a failure if the pattern can never match the guard. 
//
// TODO: Need to expand type so we know that ADTs, etc are marked.
//
public RType checkGuardedPattern(Pattern pp, Type t, Pattern p) {
	if (isFailType(p@rtype)) return p@rtype;
	RType rt = convertType(t);
	if (! subtypeOf(p@rtype, rt)) return makeFailType("Type of pattern, <prettyPrintType(p)>, must be a subtype of the type of the guard, <prettyPrintType(rt)>",pp@\loc);
	return rt;
}

//
// For the antipattern we will return the type of the pattern, since we still want
// to make sure the pattern can be used to form a valid match. For instance, we
// want to allow !n := 3, where n is an int, but not !n := true, even though, in
// some sense, this is true -- it indicates a (potential) misunderstanding of what
// is being done in the code.
//
public RType checkAntiPattern(Pattern pp, Pattern p) {
	return p@rtype;
}

//
// Type check a map pattern. 
//
public RType checkMapPattern(Pattern pat) {
        list[tuple[Pattern mapDomain, Pattern mapRange]] mapContents = getMapPatternContents(pat);
	if (size(mapContents) == 0) return makeMapType(makeVoidType(), makeVoidType());

	list[RType] domains; list[RType] ranges;
	for (<md,mr> <- mapContents) { domains += md@rtype; ranges += mr@rtype; }

	if (checkForFail(toSet(domains+ranges))) return collapseFailTypes(toSet(domains+ranges));
	return makeMapType(lubList(domains),lubList(ranges));	
}

//
// Driver code to check patterns. This code, except for literals and names, mainly just 
// dispatches to the various functions defined above.
//
// TODO: This is still insufficient to deal with descendant patterns, since we really
// need to know the type of the subject before we can truly check it. This isn't an
// issue with patterns like / x := B, but it is with patterns like [_*,/x,_*] := B,
// where B is a list with (for instance) ADTs inside. So, think about how we
// want to handle this, we may need another type that is treated specially in patterns,
// like RUnderspecified(t), where t is the type information we have (e.g., list of
// something inferred, etc)
//
public RType checkPattern(Pattern pat) {
	switch(pat) {
		case (Pattern)`<BooleanLiteral bl>` : {
			return makeBoolType();
		}

		case (Pattern)`<DecimalIntegerLiteral il>`  : {
			return makeIntType();
		}

		case (Pattern)`<OctalIntegerLiteral il>`  : {
			return makeIntType();
		}

		case (Pattern)`<HexIntegerLiteral il>`  : {
			return makeIntType();
		}

		case (Pattern)`<RealLiteral rl>`  : {
			return makeRealType();
		}

		case (Pattern)`<StringLiteral sl>`  : {
			return makeStrType();
		}

		case (Pattern)`<LocationLiteral ll>`  : {
			return makeLocType();
		}

		case (Pattern)`<DateTimeLiteral dtl>`  : {
			return makeDateTimeType();
		}

		// Regular Expression literal
		case (Pattern)`<RegExpLiteral rl>` : {
		        // NOTE: The only possible source of errors here is the situation where one of the variables in the
  			// regular expression pattern is not a string. We usually can't detect this until the bind, though,
			// so save that check for bindInferredTypesToPattern.
		        list[Tree] names = prodFilter(rl, bool(Production prd) { return prod(_,lex(sort("Name")),_) := prd; });
			list[RType] retTypes = [ getTypeForName(globalSymbolTable, RSimpleName("<n>"), n@\loc) | n <- names ];
			if (checkForFail(toSet(retTypes))) return collapseFailTypes(toSet(retTypes));
			return makeStrType();
		}

		case (Pattern)`_` : {
		        RType patType = getTypeForName(globalSymbolTable, RSimpleName("_"), pat@\loc);
			//println("For pattern _ at location <pat@\loc> found type(s) <patType>");
			return patType;
		}
		
		case (Pattern)`<Name n>`: {
			return getTypeForName(globalSymbolTable, convertName(n), n@\loc);
		}
		
		// QualifiedName
		case (Pattern)`<QualifiedName qn>`: {
			return getTypeForName(globalSymbolTable, convertName(qn), qn@\loc);
		}

		// ReifiedType
		case (Pattern) `<BasicType t> ( <{Pattern ","}* pl> )` : {
			return checkReifiedTypePattern(pat,t,pl);
		}

		// CallOrTree
		case (Pattern) `<Pattern p1> ( <{Pattern ","}* pl> )` : {
			return checkCallOrTreePattern(pat,p1,pl);
		}

		// List
		case (Pattern) `[<{Pattern ","}* pl>]` : {
			return checkListPattern(pat,pl);
		}

		// Set
		case (Pattern) `{<{Pattern ","}* pl>}` : {
			return checkSetPattern(pat,pl);
		}

		// Tuple
		case (Pattern) `<<Pattern pi>>` : {
			return checkTrivialTuplePattern(pat,pi);
		}

		case (Pattern) `<<Pattern pi>, <{Pattern ","}* pl>>` : {
			return checkTuplePattern(pat,pi,pl);
		}

		// Typed Variable
		case (Pattern) `<Type t> <Name n>` : {
			return getTypeForName(globalSymbolTable, convertName(n), n@\loc);
		}

		// Multi Variable
		case (Pattern) `_ *` : {
			return getTypeForName(globalSymbolTable, RSimpleName("_"), pat@\loc);
		}
		
		case (Pattern) `<QualifiedName qn> *` : {
			return getTypeForName(globalSymbolTable, convertName(qn), qn@\loc);
		}

		// Descendant
		case (Pattern) `/ <Pattern p>` : {
			return p@rtype;
		}

		// Variable Becomes
		case (Pattern) `<Name n> : <Pattern p>` : {
			return checkVariableBecomesPattern(pat,n,p);
		}
		
		// Typed Variable Becomes
		case (Pattern) `<Type t> <Name n> : <Pattern p>` : {
			return checkTypedVariableBecomesPattern(pat,t,n,p);
		}
		
		// Guarded
		case (Pattern) `[ <Type t> ] <Pattern p>` : {
			return checkGuardedPattern(pat,t,p);
		}			
		
		// Anti
		case (Pattern) `! <Pattern p>` : {
			return checkAntiPattern(pat,p);
		}
	}

	// Logic for handling maps -- we cannot directly match them, so instead we need to pick apart the tree
	// representing the map.
        // pat[0] is the production used, pat[1] is the actual parse tree contents
	if (prod(_,_,attrs([_*,term(cons("Map")),_*])) := pat[0]) {
	        RType t = checkMapPattern(pat);
                return t;
	}
	throw "Missing case on checkPattern for pattern <pat> at location <pat@\loc>";
}

//
// Bind any variables used in the map pattern to the types present in type rt.
//
public RType bindInferredTypesToMapPattern(RType rt, Pattern pat) {
        // Get the domain and range types for rt
        RType mapDomain = getMapDomainType(rt);
        RType mapRange = getMapRangeType(rt);

        list[tuple[Pattern mapDomain, Pattern mapRange]] mapContents = getMapPatternContents(pat);
	if (size(mapContents) == 0) return makeMapType(makeVoidType(), makeVoidType());

	list[RType] domains; list[RType] ranges;
	for (<md,mr> <- mapContents) { 
	        domains += bindInferredTypesToPattern(mapDomain, pl);
		ranges += bindInferredTypesToPattern(mapRange, pr);
        }

	if (checkForFail(toSet(domains+ranges))) return collapseFailTypes(toSet(domains+ranges));
	return makeMapType(lubList(domains),lubList(ranges));	
}

//
// Bind inferred types to multivar names: _* and QualifiedName*
//
public RType bindInferredTypesToMV(RType rt, RType pt, Pattern pat) {
        RType retType;

	// Make sure the type we are given is actually one that can contain elements
	if (! (isListType(rt) || isSetType(rt) || isContainerType(rt))) {
	        return makeFailType("Attempting to bind type <prettyPrintType(rt)> to a multivariable <pat>",pat@\loc);
	}

	// Make sure that the type we are given is compatible with the type of the container variable
	if ( ! ( (isListType(rt) && (isListType(pt) || isContainerType(pt))) ||
                 (isSetType(rt) && (isSetType(pt) || isContainerType(pt))) ||
                 (isContainerType(rt) && isContainerType(pt)))) {
	        return makeFailType("Attempting to bind type <prettyPrintType(rt)> to an incompatible container type <prettyPrintType(pt)>",pat@\loc);
        }

        // This should be structured as RContainerType(RInferredType(#)) unless we have assigned a more specific
	// type between creation and now. It should always be a container (list, set, or container) of some sort.
	if (isContainerType(pt) || isListType(pt) || isSetType(pt)) {
                RType elementType;
		bool elementIsInferred = false;
	        if (isContainerType(pt)) {
	                elementIsInferred = (isInferredType(getContainerElementType(pt))) ? true : false;
			elementType = (isInferredType(getContainerElementType(pt))) ?
 			        globalSymbolTable.inferredTypeMap[getInferredTypeIndex(getContainerElementType(pt))] :
				getContainerElementType(pt);
		} else if (isListType(pt)) {
			elementIsInferred = (isInferredType(getListElementType(pt))) ? true : false;
			elementType = (isInferredType(getListElementType(pt))) ?
 			        globalSymbolTable.inferredTypeMap[getInferredTypeIndex(getListElementType(pt))] : 
			        getListElementType(pt);
		} else if (isSetType(pt)) {
			elementIsInferred = (isInferredType(getSetElementType(pt))) ? true : false;
			elementType = (isInferredType(getSetElementType(pt))) ?
 			        globalSymbolTable.inferredTypeMap[getInferredTypeIndex(getSetElementType(pt))] : 
				getSetElementType(pt);
		}

		// Get the type of element inside the type being bound
		RType relementType = isContainerType(rt) ? getContainerElementType(rt) : (isListType(rt) ? getListElementType(rt) : getSetElementType(rt));

		if (elementIsInferred) {
		        // The element type is inferred. See if it still is open -- if it still points to an inferred type.
			if (isInferredType(elementType)) {
		                // Type still open, update mapping
				updateInferredTypeMappings(elementType,relementType);
 				retType = rt;
	                } else if (! equivalent(elementType, relementType)) {
		                // Already assigned a type, issue a failure, attempting to bind multiple types to the same var
				retType = makeFailType("Attempt to bind multiple types to the same implicitly typed name <pat>: already bound element type as <prettyPrintType(elementType)>, attempting to bind new element type <prettyPrintType(relementType)>", pat@\loc);
			} else {
				// Trying to assign the same type again, which is fine, just return it.
				retType = rt;
		        }
		} else {
		        // The element type is NOT an inferred type. The type of rt must match exactly.
		        if (! equivalent(elementType, relementType)) {
			        retType = makeFailType("Attempt to bind multiple types to the same implicitly typed name <pat>: already bound element type as <prettyPrintType(elementType)>, attempting to bind new element type <prettyPrintType(relementType)>", pat@\loc);
			} else {
				retType = rt;
			}  
		}
	} else {
	        throw "Unexpected type assigned to container var at location <pat@\loc>: <prettyPrintType(pt)>";
	}
	
        return retType;
}

//
// Recursively bind the types from an expression to any inferred types in a pattern. To make subtyping easier,
// we do the binding before we do the subtyping. This allows us to find specific errors in cases where the
// subject and the pattern do not match -- for instance, we can find that a constructor is given two
// arguments, but expects three. If we do subtyping checks first, we get less information -- only that the
// pattern and the subject are not comparable.
//
// TODO: In certain odd cases Lub types could be assigned to names; make sure those are resolved
// correctly here... 
//
public RType bindInferredTypesToPattern(RType rt, Pattern pat) {
	RType pt = pat@rtype; // Just save some typing below...
	
	// If either the type we are binding against (rt) or the current pattern type are fail
	// types, don't try to bind, just fail, we had something wrong in either the pattern
	// or the subject that may yield lots of spurious errors here.
	if (isFailType(rt) || isFailType(pat@rtype)) return collapseFailTypes({ rt, pat@rtype });
	
	// Now, compare the pattern and binding (subject) types, binding actual types to lub and
	// inference types if possible.	
	switch(pat) {
		case (Pattern)`<BooleanLiteral bl>` : {
			if (isBoolType(rt) && isBoolType(pt)) {
				return pt;
			} else {
				return makeFailType("Boolean literal pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		case (Pattern)`<DecimalIntegerLiteral il>`  : {
			if (isIntType(rt) && isIntType(pt)) {
				return pt;
			} else {
				return makeFailType("Integer literal pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		case (Pattern)`<OctalIntegerLiteral il>`  : {
			if (isIntType(rt) && isIntType(pt)) {
				return pt;
			} else {
				return makeFailType("Integer literal pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		case (Pattern)`<HexIntegerLiteral il>`  : {
			if (isIntType(rt) && isIntType(pt)) {
				return pt;
			} else {
				return makeFailType("Integer literal pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		case (Pattern)`<RealLiteral rl>`  : {
			if (isRealType(rt) && isRealType(pt)) {
				return pt;
			} else {
				return makeFailType("Real literal pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		case (Pattern)`<StringLiteral sl>`  : {
			if (isStrType(rt) && isStrType(pt)) {
				return pt;
			} else {
				return makeFailType("String literal pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		case (Pattern)`<LocationLiteral ll>`  : {
			if (isLocType(rt) && isLocType(pt)) {
				return pt;
			} else {
				return makeFailType("Location literal pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		case (Pattern)`<DateTimeLiteral dtl>`  : {
			if (isDateTimeType(rt) && isDateTimeType(pt)) {
				return pt;
			} else {
				return makeFailType("DateTime literal pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		// Regular Expression literal
		// TODO: We need to check for this pattern in the main visitor, so we can mark the types on the names.
		case (Pattern)`<RegExpLiteral rl>` : {
		    if (isStrType(rt) && isStrType(pt)) {
		        list[tuple[RType,RName]] resTypes = [ ];
		        list[Tree] names = prodFilter(rl, bool(Production prd) { return prod(_,lex(sort("Name")),_) := prd; });
			for (n <- names) {
			    RType pt = getTypeForName(globalSymbolTable, RSimpleName("<n>"), n@\loc);
			    RType t = (isInferredType(pt)) ? globalSymbolTable.inferredTypeMap[getInferredTypeIndex(pt)] : pt;
			    if (isInferredType(t)) {
				updateInferredTypeMappings(t,rt);
				resTypes += <rt,RSimpleName("<n>")>;
			    } else if (! equivalent(t,rt)) {
				resTypes += <makeFailType("Attempt to bind multiple types to the same implicitly typed anonymous name <n> in pattern <pat>: already bound type <prettyPrintType(t)>, attempting to bind type <prettyPrintType(rt)>", n@\loc),RSimpleName("<n>")>;
			    } 			
                        }
			if (checkForFail({t | <t,_> <- resTypes})) return collapseFailTypes({t | <t,_> <- resTypes});
			if (size(resTypes) == 0 || (size(resTypes) > 0 && isStrType(lubList([t | <t,_> <- resTypes])))) return rt;
			return makeFailType("The following names in the pattern are not of type string: <[n | <t,n> <- resTypes, !isStrType(t)]>",pat@\loc);
                   } else {
		       return makeFailType("Regular Expression  pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>",pat@\loc);
                   }
		}

		// Anonymous name
		// TODO: Add LubType support, just in case
		case (Pattern)`_` : {
			RType retType;
			RType t = (isInferredType(pt)) ? globalSymbolTable.inferredTypeMap[getInferredTypeIndex(pt)] : pt;
			if (isInferredType(t)) {
				updateInferredTypeMappings(t,rt);
				retType = rt;
			} else if (! equivalent(t,rt)) {
				retType = makeFailType("Attempt to bind multiple types to the same implicitly typed anonymous name <pat>: already bound type <prettyPrintType(t)>, attempting to bind type <prettyPrintType(rt)>", pat@\loc);
			} else {
				retType = t; // or rt, types are equal
			}
			return retType;
		}
		
		// Name
		// TODO: Add LubType support, just in case
		case (Pattern)`<Name n>`: {
			RType retType;
			RType nType = getTypeForNameLI(globalSymbolTable,convertName(n),n@\loc);
			RType t = (isInferredType(nType)) ? globalSymbolTable.inferredTypeMap[getInferredTypeIndex(nType)] : nType;
			if (isInferredType(t)) {
				updateInferredTypeMappings(t,rt);
				retType = rt;
			} else if (! equivalent(t,rt)) {
				retType = makeFailType("Attempt to bind multiple types to the same implicitly typed name <n>: already bound type <prettyPrintType(t)>, attempting to bind type <prettyPrintType(rt)>", n@\loc);
			} else {
				retType = t; // or rt, types are equal
			}
			return retType;			
		}

		// QualifiedName
		// TODO: Add LubType support, just in case
		case (Pattern)`<QualifiedName qn>`: {
			RType retType;
			RType nType = getTypeForNameLI(globalSymbolTable,convertName(qn),qn@\loc);
			RType t = (isInferredType(nType)) ? globalSymbolTable.inferredTypeMap[getInferredTypeIndex(nType)] : nType;
			if (isInferredType(t)) {
				updateInferredTypeMappings(t,rt);
				retType = rt;
			} else if (! equivalent(t,rt)) {
				retType = makeFailType("Attempt to bind multiple types to the same implicitly typed name <qn>: already bound type <prettyPrintType(t)>, attempting to bind type <prettyPrintType(rt)>", n@\loc);
			} else {
				retType = t; // or rt, types are equal
			}
			return retType;			
		}

		// TODO: ReifiedType, see if we need to expand matching for this
		case (Pattern) `<BasicType t> ( <{Pattern ","}* pl> )` : {
			if (RReifiedType(bt) := rt) {
				return rt; // TODO: Will need to change to really get this working, just return the binder type for now
			} else {
				return makeFailType("Type of pattern, <prettyPrintType(pt)>, is not compatible with the type of the binding expression, <prettyPrintType(rt)>",pat@\loc);
			}
		}

		// CallOrTree
		// This handles two different cases. In the first, the binding code is invoked when we handle
		// a constructor pattern to assign types to the variables. In that case, we actually have the
		// full signature of the constructor, so we have the information for each field in the
		// pattern. In the second, the binding code is invoked during a match or enumeration, so
		// we don't actually have explicit constructor types, just the ADT type. In that case, we
		// can't descend into the pattern, we just have to compare the ADT types of the constructor
		// and the type of the binding type (rt).
		case (Pattern) `<Pattern p1> ( <{Pattern ","}* pl> )` : {
			list[Pattern] patternFields = [p | p <- pl];
			RType patternType = pat@fctype; // Get back the constructor type used, not the ADT types
			if (isConstructorType(patternType) && isConstructorType(rt) && size(getConstructorArgumentTypes(patternType)) == size(patternFields)) {
				set[RType] potentialFailures = { };
				list[RType] rtArgTypes = getConstructorArgumentTypes(rt); 
				for (n <- domain(rtArgTypes))
					potentialFailures += bindInferredTypesToPattern(rtArgTypes[n],patternFields[n]);
				if (checkForFail(potentialFailures)) return collapseFailTypes(potentialFailures);
				return getConstructorResultType(patternType);
			} else if (isADTType(pt) && isADTType(rt) && subtypeOf(rt,pt)) {
				return pt; // TODO: Firm this up
			} else {
				return makeFailType("Actual type, <prettyPrintType(rt)>, is incompatible with the pattern type, <prettyPrintType(pt)>",pat@\loc);
			}
		}

		// List
		case (Pattern) `[<{Pattern ","}* pl>]` : {
			if (isListType(rt) && isListType(pt)) {
				RType plt = getListElementType(pt);
				RType rlt = getListElementType(rt);
				
				list[RType] elementTypes = [ ];
				for (p <- pl) {
					if (isListContainerVar(p))			
						elementTypes += bindInferredTypesToPattern(rt,p);
					else
						elementTypes += bindInferredTypesToPattern(rlt,p);
				}
				
				if (checkForFail(toSet(elementTypes))) return collapseFailTypes(toSet(elementTypes));
				
				// Get the types in the list, we need to watch for inferrence types since we need
				// to handle those separately. We also need to watch for lub types, since we could
				// propagate these up, although we should be able to resolve them at some point (maybe
				// just not yet). For instance, if we have C([ [x,_*], _* ]), when we type [x,_*] this
				// will generate a lub type, then [ [x,_*], _* ] will also generate a lub type, and it
				// will not be resolved until we reach C([ [x,_*], _*]), where we should be able to
				// determine the actual type.
				list[RType] patTypesI = [ t | t <- elementTypes, isInferredType(t) || isLubType(t) ];
				
				if (size(patTypesI) > 0) {
					return makeListType(makeLubType(elementTypes));
				} else {
					RType lubType = lubList(elementTypes);
					if (subtypeOf(rlt,lubType)) {
						return makeListType(lubType);
					} else {
						return makeFailType("The list element type of the subject, <prettyPrintType(rlt)>, must be a subtype of the list element type in the pattern, <prettyPrintType(lubType)>", pat@\loc);
					}
				}
			} else {
				return makeFailType("List pattern has pattern type of <prettyPrintType(pt)> but subject type of <prettyPrintType(rt)>",pat@\loc);
			}
		}

		// Set
		case (Pattern) `{<{Pattern ","}* pl>}` : {
			if (isSetType(rt) && isSetType(pt)) {
				RType pst = getSetElementType(pt);
				RType rst = getSetElementType(rt);
				
				list[RType] elementTypes = [ ];
				for (p <- pl) {
					if (isSetContainerVar(p))			
						elementTypes += bindInferredTypesToPattern(rt,p);
					else
						elementTypes += bindInferredTypesToPattern(rst,p);
				}
				
				if (checkForFail(toSet(elementTypes))) return collapseFailTypes(toSet(elementTypes));
				
				// Get the types in the set, we need to watch for inferrence types since we need
				// to handle those separately. We also need to watch for lub types, since we could
				// propagate these up, although we should be able to resolve them at some point (maybe
				// just not yet). For instance, if we have C({ {x,_*}, _* }), when we type {x,_*} this
				// will generate a lub type, then { {x,_*}, _* } will also generate a lub type, and it
				// will not be resolved until we reach C({ {x,_*}, _*}), where we should be able to
				// determine the actual type.
				list[RType] patTypesI = [ t | t <- elementTypes, hasDeferredTypes(t) ];
				
				if (size(patTypesI) > 0) {
					return makeListType(makeLubType(elementTypes));
				} else {
					RType lubType = lubList(elementTypes);
					if (subtypeOf(rst,lubType)) {
						return makeSetType(lubType);
					} else {
						return makeFailType("The set element type of the subject, <prettyPrintType(rst)>, must be a subtype of the set element type in the pattern, <prettyPrintType(lubType)>", pat@\loc);
					}
				}
			} else {
				return makeFailType("Set pattern has pattern type of <prettyPrintType(pt)> but subject type of <prettyPrintType(rt)>",pat@\loc);
			}
		}

		// Tuple with just one element
		// TODO: Ensure fields persist in the match, they don't right now
		case (Pattern) `<<Pattern pi>>` : {
			if (isTupleType(rt) && isTupleType(pt)) {
				list[RType] tupleFields = getTupleFields(rt);
				if (size(tupleFields) == 1) {
					RType resultType = bindInferredTypesToPattern(head(tupleFields),pi);
					if (isFailType(resultType))
						return resultType;
					else
						return makeTupleType([resultType]);
				} else {
					return makeFailType("Tuple type in subject <prettyPrintType(rt)> has more fields than tuple type in pattern <pat>, <prettyPrintType(pat@rtype)>",pat@\loc);
				}
			} else {
				return makeFailType("tuple pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>", pat@\loc);
			}
		}

		// Tuple with more than one element
		// TODO: Ensure fields persist in the match, they don't right now
		case (Pattern) `<<Pattern pi>, <{Pattern ","}* pl>>` : {
			if (isTupleType(rt) && isTupleType(pt)) {
				list[RType] tupleFields = getTupleFields(rt);
				list[Pattern] patternFields = [pi] + [p | p <- pl];
				
				if (size(tupleFields) == size(patternFields)) {
					list[RType] elementTypes = [ ];
					for (n <- [0..size(tupleFields)-1])
						elementTypes += bindInferredTypesToPattern(tupleFields[n],patternFields[n]);
					if (checkForFail(toSet(elementTypes))) return collapseFailTypes(toSet(elementTypes));
					return makeTupleType(elementTypes);
				} else {
					return makeFailType("Tuple type in subject <prettyPrintType(rt)> has a different number of fields than tuple type in pattern <pat>, <prettyPrintType(pat@rtype)>",pat@\loc);
				}
			} else {
				return makeFailType("tuple pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>", pat@\loc);
			}
		}

		// Typed Variable: a variable of type t can match a subject of type rt when rt <: t
		// TODO: Special rules for scalars vs nodes/ADTs? May make sense to say they can match
		// when, with allSubtypes being the set of all possible subtypes of t,
		// size(allSubtypes(pt) inter allSubtypes(rt)) > 0, i.e., when the actual type of each,
		// which is a subtype of the static type, could be shared...
		case (Pattern) `<Type t> <Name n>` : {
			if (subtypeOf(rt,pt))
				return pt;
			else
				return makeFailType("not possible to bind actual type <prettyPrintType(rt)> to pattern type <prettyPrintType(pt)>", pat@\loc);
		}
		
		// Multi Variable patterns, _* and QualifiedName*
		case (Pattern)`_ *` : {
			return bindInferredTypesToMV(rt, getTypeForNameLI(globalSymbolTable,RSimpleName("_"),pat@\loc), pat);
		}
		
		case (Pattern) `<QualifiedName qn> *` : {
			return bindInferredTypesToMV(rt, getTypeForNameLI(globalSymbolTable,convertName(qn),qn@\loc), pat);
		}

		// Descendant
		// Since this pattern is inside something, we use the subject type (rt) to determine what it is
		// inside. If p is itself just an inferred type (e.g., p = / x) then we use rt to figure
		// out what x can hold, which is: the lub of all the types reachable through rt. If p has
		// a type of some sort at the top level, we check to see if that can be used inside rt.
		// If so, and if it contains inferred or deferred types, we push down a lub of the matching
		// types in rt. If so, and if it has no deferred types, we just use that type, if it can
		// occur inside rt.
		// 
		// NOTE: We actually return rt as the type of / x, not lub(reachable(rt)). This is because
		// pattern / x essentially stands in for rt in this case, if we have [_*,/ x,_*] for instance,
		// and we use this to indicate that the second position actually has an rt which we are
		// picking apart.
		case (Pattern) `/ <Pattern p>` : {
			if ( isInferredType(p@rtype) ) {
			        set[RType] rts = reachableTypes(globalSymbolTable, rt);
				RType bt = bindInferredTypesToPattern(lubSet(rts), p);
				return isFailType(bt) ? bt : rt;
			} else if ( (! isInferredType(p@rtype)) && (hasDeferredTypes(p@rtype))) {
			        set[RType] rts = reachableTypes(globalSymbolTable, rt);
				rts = { rtsi | rtsi <- rts, subtypeOf(rtsi, p@rtype)};
				RType bt = bindInferredTypesToPattern(lubSet(rts), p);
				return isFailType(bt) ? bt : rt;
			} else {
			        set[RType] rts = reachableTypes(globalSymbolTable, rt);
				if (p@rtype in rts) return rt;
				return makeFailType("Pattern type <prettyPrintType(p@rtype)> cannot appear in type <prettyPrintType(rt)>", pat@\loc);
			}
		}

		// Variable Becomes
		case (Pattern) `<Name n> : <Pattern p>` : {
			RType boundType = bindInferredTypesToPattern(rt, p);
			if (! isFailType(boundType)) {
        			RType nType = getTypeForNameLI(globalSymbolTable,convertName(n),n@\loc);
	        		RType t = (isInferredType(nType)) ? globalSymbolTable.inferredTypeMap[getInferredTypeIndex(nType)] : nType;
		        	if (isInferredType(t)) {
			        	updateInferredTypeMappings(t,boundType);
				        return boundType;
        			} else if (! equivalent(t,boundType)) {
	        			return makeFailType("Attempt to bind multiple types to the same implicitly typed name <n>: already bound type <prettyPrintType(t)>, attempting to bind type <prettyPrintType(boundType)>", n@\loc);
		        	} else {
			        	return t; // or boundType, types are equal
        			}
			}
			return boundType;
		}
		
		// Typed Variable Becomes
		case (Pattern) `<Type t> <Name n> : <Pattern p>` : {
			if (subtypeOf(rt,pt)) {
				RType resultType = bindInferredTypesToPattern(rt, p);
				if (isFailType(resultType)) return resultType;
				return pt;
			} else {
				return makeFailType("Not possible to bind actual type <prettyPrintType(rt)> to pattern type <prettyPrintType(pt)>", pat@\loc);
			}
		}
		
		// Guarded
		case (Pattern) `[ <Type t> ] <Pattern p>` : {
			if (subtypeOf(rt,pt)) {
				RType resultType = bindInferredTypesToPattern(rt, p);
				if (isFailType(resultType)) return resultType;
				return pt;
			} else {
				return makeFailType("Not possible to bind actual type <prettyPrintType(rt)> to pattern type <prettyPrintType(pt)>", pat@\loc);
			}
		}			
		
		// Anti -- TODO see if this makes sense, check the interpreter
		case (Pattern) `! <Pattern p>` : {
			return bindInferredTypesToPattern(rt, p);
		}
	}

	// Logic for handling maps -- we cannot directly match them, so instead we need to pick apart the tree
	// representing the map.
        // pat[0] is the production used, pat[1] is the actual parse tree contents
	if (prod(_,_,attrs([_*,term(cons("Map")),_*])) := pat[0]) {
	        if (isMapType(rt) && isMapType(pt)) {
	                RType t = bindInferredTypesToMapPattern(rt, pat);
                        return t;
                } else {
                        return makeFailType("map pattern has unexpected pattern and subject types: <prettyPrintType(pt)>, <prettyPrintType(rt)>", pat@\loc);
                }
	}

	throw "Missing case on checkPattern for pattern <pat>";
}

//
// Check Pattern with Action productions
//
public RType checkPatternWithAction(PatternWithAction pat) {
	switch(pat) {
		case `<Pattern p> => <Expression e>` : {
			if (checkForFail( { p@rtype, e@rtype } )) return collapseFailTypes( { p@rtype, e@rtype } );
			RType boundType = bindInferredTypesToPattern(p@rtype, p);
			if (isFailType(boundType)) return boundType;
			if (!subtypeOf(e@rtype,boundType)) return makeFailType("Type of pattern, <prettyPrintType(boundType)>, and action expression, <prettyPrintType(e@rtype)>, must be identical.", pat@\loc); 
			return p@rtype; 
		}
		
		case `<Pattern p> => <Expression er> when <{Expression ","}+ es>` : {
			set[RType] whenTypes = { e@rtype | e <- es };
			if (checkForFail( whenTypes + p@rtype + er@rtype )) return collapseFailTypes( whenTypes + p@rtype + er@rtype );
			RType boundType = bindInferredTypesToPattern(p@rtype, p);
			if (isFailType(boundType)) return boundType;
			if (!subtypeOf(er@rtype,boundType)) return makeFailType("Type of pattern, <prettyPrintType(boundType)>, and action expression, <prettyPrintType(er@rtype)>, must be comparable.", pat@\loc); 
			return p@rtype; 
		}
		
		case `<Pattern p> : <Statement s>` : {
			RType stmtType = getInternalStatementType(s@rtype);
			if (checkForFail( { p@rtype, stmtType })) return collapseFailTypes( { p@rtype, stmtType });
			RType boundType = bindInferredTypesToPattern(p@rtype, p);
			if (isFailType(boundType)) return boundType;
			return stmtType;
		}
	}
	
	throw "Unhandled case in checkPatternWithAction, <pat>";	
}

//
// Check the type of the data target. This just propagates failures (for instance, from using a target
// name that is not defined), otherwise assigning a void type.
//
public RType checkDataTarget(DataTarget dt) {
	if ((DataTarget)`<Name n> :` := dt && isFailType(getTypeForName(globalSymbolTable,convertName(n),n@\loc))) 
		return getTypeForName(globalSymbolTable,convertName(n),n@\loc);		
	return makeVoidType();
}

//
// Check the type of the target. This just propagates failures (for instance, from using a target
// name that is not defined), otherwise assigning a void type.
//
public RType checkTarget(Target t) {
	if ((Target)`<Name n>` := t && isFailType(getTypeForName(globalSymbolTable,convertName(n),n@\loc))) 
		return getTypeForName(globalSymbolTable,convertName(n),n@\loc);		
	return makeVoidType();
}

// TODO: For now, just update the exact index. If we need to propagate these changes we need to make this
// code more powerful.
private void updateInferredTypeMappings(RType t, RType rt) {
	globalSymbolTable.inferredTypeMap[getInferredTypeIndex(t)] = rt;
}

// Replace inferred with concrete types
public RType replaceInferredTypes(RType rt) {
	return visit(rt) { case RInferredType(n) => globalSymbolTable.inferredTypeMap[n] };
}

//
// Calculate the list of types assigned to a list of parameters
//
public list[RType] getParameterTypes(Parameters p) {
	list[RType] pTypes = [];

	if (`( <Formals f> )` := p && (Formals)`<{Formal ","}* fs>` := f) {
		for ((Formal)`<Type t> <Name n>` <- fs) {
				pTypes += getTypeForName(globalSymbolTable,convertName(n),n@\loc);
		}
	} else if (`( <Formals f> ... )` := p && (Formals)`<{Formal ","}* fs>` := f) {
		for ((Formal)`<Type t> <Name n>` <- fs) {
				pTypes += getTypeForName(globalSymbolTable,convertName(n),n@\loc);
		}
		// For varargs, mark the last parameter as the variable size parameter; if we have no
		// parameters, then we add one, a varargs which accepts anything
		if (size(pTypes) > 0)
			pTypes[size(pTypes)-1] = RVarArgsType(pTypes[size(pTypes)-1]);
		else
			pTypes = [ RVarArgsType(makeValueType()) ];
	}

	return pTypes;
}

//
// Figure the type of value that would be assigned, based on the assignment statement
// being used. This returns a fail type if the assignment is invalid. 
//
public RType getAssignmentType(RType t1, RType t2, RAssignmentOp raOp, loc l) {
	if (aOpHasOp(raOp)) {
		RType expType = expressionType(t1,t2,opForAOp(raOp),l);
		if (isFailType(expType)) return expType;
		if (subtypeOf(expType, t1)) return t1;
		return makeFailType("Invalid assignment of type <prettyPrintType(expType)> into variable of type <prettyPrintType(t1)>",l);
	} else if (raOp in { RADefault(), RAIfDefined() }) {
		if (subtypeOf(t2,t1)) {
			return t1;
		} else {
			return makeFailType("Invalid assignment of type <prettyPrintType(t2)> into variable of type <prettyPrintType(t1)>",l);
		}
	} else {
		throw "Invalid assignment operation: <raOp>";
	}
}

// TODO: We need logic that caches the signatures on the parse trees for the
// modules. Until then, we load up the signatures here...
public SignatureMap populateSignatureMap(list[Import] imports) {

	str getNameOfImportedModule(ImportedModule im) {
		switch(im) {
			case `<QualifiedName qn> <ModuleActuals ma> <Renamings rn>` : {
				return prettyPrintName(convertName(qn));
			}
			case `<QualifiedName qn> <ModuleActuals ma>` : {
				return prettyPrintName(convertName(qn));
			}
			case `<QualifiedName qn> <Renamings rn>` : {
				return prettyPrintName(convertName(qn));
			}
			case (ImportedModule)`<QualifiedName qn>` : {
				return prettyPrintName(convertName(qn));
			}
		}
		throw "getNameOfImportedModule: invalid syntax for ImportedModule <im>, cannot get name";
	}


	SignatureMap sigMap = ( );
	for (i <- imports) {
		if (`import <ImportedModule im> ;` := i || `extend <ImportedModule im> ;` := i) {
			Tree importTree = getModuleParseTree(getNameOfImportedModule(im));
			sigMap[i] = getModuleSignature(importTree);
		} 
	}

	return sigMap;
}

private SymbolTable globalSymbolTable = createNewSymbolTable();

// Check to see if the cases given cover the possible matches of the expected type.
// If a default is present this is automatically true, else we need to look at the
// patterns given in the various cases. 
public bool checkCaseCoverage(RType expectedType, Case+ options, SymbolTable table) {
	set[Case] defaultCases = { cs | cs <- options, `default: <Statement b>` := cs };
	if (size(defaultCases) > 0) return true;	
	
	set[Pattern] casePatterns = { p | cs <- options, `case <Pattern p> => <Replacement r>` := cs || `case <Pattern p> : <Statement b>` := cs };
	return checkPatternCoverage(expectedType, casePatterns, table);		
}

// Check to see if the patterns in the options set cover the possible matches of the
// expected type. This can be recursive, for instance with ADT types.
// TODO: Need to expand support for matching over reified types	
public bool checkPatternCoverage(RType expectedType, set[Pattern] options, SymbolTable table) {

	// Check to see if a given use of a name is the same use that defines it. A use is the
	// defining use if, at the location of the name, there is a use of the name, and that use
	// is also the location of the definition of a new item.
	bool isDefiningUse(Name n, SymbolTable table) {
		loc nloc = n@\loc;
		if (nloc in table.itemUses) {
			if (size(table.itemUses[nloc]) == 1) {
				if (nloc in domain(table.itemLocations)) {
					set[STItemId] items = { si | si <- table.itemLocations[nloc], isItem(table.scopeItemMap[si]) };
					if (size(items) == 1) {
						return (VariableItem(_,_,_) := table.scopeItemMap[getOneFrom(items)]);
					} else if (size(items) > 1) {
						throw "isDefiningUse: Error, location defines more than one scope item.";
					}				
				}
			}
		}
		return false;
	}

	// Take a rough approximation of whether a pattern completely covers the given
	// type. This is not complete, since some situations where this is true will return
	// false here, but it is sound, in that any time we return true it should be the
	// case that the pattern actually covers the type.
	bool isDefiningPattern(Pattern p, RType expectedType, SymbolTable table) {
		if ((Pattern)`_` := p) {
			return true;
		} else if ((Pattern)`<Name n>` := p && isDefiningUse(n, table)) {
			return true;
		} else if ((Pattern)`<Type t> _` := p && convertType(t) == expectedType) {
			return true;
		} else if ((Pattern)`<Type t> <Name n>` := p && isDefiningUse(n, table) && convertType(t) == expectedType) {
			return true;
		} else if (`<Name n> : <Pattern pd>` := p) {
			return isDefiningPattern(pd, expectedType, table);
		} else if (`<Type t> <Name n> : <Pattern pd>` := p && convertType(t) == expectedType) {
			return isDefiningPattern(pd, expectedType, table);
		} else if (`[ <Type t> ] <Pattern pd>` := p && convertType(t) == expectedType) {
			return isDefiningPattern(pd, expectedType, table);
		}
		
		return false;
	}
	
	// Check to see if a 0 or more element pattern is empty (i.e., contains no elements)
	bool checkEmptyMatch({Pattern ","}* pl, RType expectedType, SymbolTable table) {
		return size([p | p <- pl]) == 0;
	}

	// Check to see if a 0 or more element pattern matches an arbitrary sequence of zero or more items;
	// this means that all the internal patterns have to be of the form x*, like [ xs* ys* ], since this
	// still allows 0 items total
	bool checkTotalMatchZeroOrMore({Pattern ","}* pl, RType expectedType, SymbolTable table) {
		list[Pattern] plst = [p | p <- pl];
		set[bool] starMatch = { `<QualifiedName qn>*` := p | p <- pl };
		return (! (false in starMatch) );
	}

	// Check to see if a 1 or more element pattern matches an arbitrary sequence of one or more items;
	// this would be something like [xs* x ys*]. If so, recurse to make sure this pattern actually covers
	// the element type being matched. So, [xs* x ys*] := [1..10] would cover (x taking 1..10), but
	// [xs* 3 ys*] would not (even though it matches here, there is no static guarantee it does without
	// checking the values allowed on the right), and [xs* 1000 ys*] does not (again, no static guarantees,
	// and it definitely doesn't cover the example here).
	bool checkTotalMatchOneOrMore({Pattern ","}* pl, RType expectedType, SymbolTable table) {
		list[Pattern] plst = [p | p <- pl];
		set[int] nonStarMatch = { n | n <- domain(plst), ! `<QualifiedName qn>*` := plst[n] };
		return (size(nonStarMatch) == 1 && isDefiningPattern(plst[getOneFrom(nonStarMatch)], expectedType, table));
	}
	
	if (isBoolType(expectedType)) {
		// For booleans, check to see if either a) a variable is given which could match either
		// true or false, or b) both the constants true and false are explicitly given in two cases
		bool foundTrue = false; bool foundFalse = false;
		for (p <- options) {
			if (isDefiningPattern(p, expectedType, table)) 
				return true;
			else if ((Pattern)`true` := p) 
				foundTrue = true;
			else if ((Pattern)`false` := p) 
				foundFalse = true;
			if (foundTrue && foundFalse) return true; 
		}
		return false;
	} else if (isIntType(expectedType) || isRealType(expectedType) || isNumType(expectedType) || isStrType(expectedType) || isValueType(expectedType) || isLocType(expectedType) || isLexType(expectedType) || isReifiedType(expectedType) || isDateTimeType(expectedType)) {
		// For int, real, num, str, value, loc, lex, datetime, and reified types, just check to see
		// if a variable if given which could match any value of these types.
		for (p <- options) {
			if (isDefiningPattern(p, expectedType, table)) return true;
		}
		return false;			
	} else if (isListType(expectedType)) {
		// For lists, check to see if either a) a variable which could represent the entire list is given, or
		// b) the list is used explicitly, but the patterns given inside the list cover all the cases.
		// TODO: At this point, we do a simple check here for b). Either we have a variable which can represent
		// 0 or more items inside the list, or we have a case with the empty list and a case with 1 item in the
		// list. We don't check anything more advanced, but it would be good to.
		bool foundEmptyMatch = false; bool foundTotalMatch = false; bool foundSingleMatch = false;
		for (p <- options) {
			if (isDefiningPattern(p, expectedType, table)) return true;
			if (`[<{Pattern ","}* pl>]` := p) {
				RType listElementType = getListElementType(expectedType);
				if (!foundEmptyMatch) foundEmptyMatch = checkEmptyMatch(pl, listElementType, table);
				if (!foundTotalMatch) foundTotalMatch = checkTotalMatchZeroOrMore(pl, listElementType, table);
				if (!foundSingleMatch) foundSingleMatch = checkTotalMatchOneOrMore(pl, listElementType, table);
			}
			if (foundTotalMatch || (foundEmptyMatch && foundSingleMatch)) return true;
		}
		return false;
	} else if (isSetType(expectedType)) {
		bool foundEmptyMatch = false; bool foundTotalMatch = false; bool foundSingleMatch = false;
		for (p <- options) {
			if (isDefiningPattern(p, expectedType, table)) return true;
			if (`{<{Pattern ","}* pl>}` := p) {
				RType setElementType = getSetElementType(expectedType);
				if (!foundEmptyMatch) foundEmptyMatch = checkEmptyMatch(pl, setElementType, table);
				if (!foundTotalMatch) foundTotalMatch = checkTotalMatchZeroOrMore(pl, setElementType, table);
				if (!foundSingleMatch) foundSingleMatch = checkTotalMatchOneOrMore(pl, setElementType, table);
			}
			if (foundTotalMatch || (foundEmptyMatch && foundSingleMatch)) return true;
		}
		return false;
	} else if (isMapType(expectedType)) {
		for (p <- options) {
			if (isDefiningPattern(p, expectedType, table)) return true;
		}
		return false;					
	} else if (isRelType(expectedType)) {
		for (p <- options) {
			if (isDefiningPattern(p, expectedType, table)) return true;
		}
		return false;				
	} else if (isTupleType(expectedType)) {
		for (p <- options) {
			if (isDefiningPattern(p, expectedType, table)) return true;
		}
		return false;				
	} else if (isADTType(expectedType)) {
	        println("Checking case coverage for ADT type <expectedType>");
		for (p <- options) {
			if (isDefiningPattern(p, expectedType, table)) return true;
		}
		return false;				
	}

	return false;	
}

//
// Check a file, given the path to the file
//
public Tree typecheckFile(str filePath) {
	loc l = |file://<filePath>|;
	Tree t = parse(#Module,l);
	return typecheckTree(t);
}

//
// Check a tree
//
public Tree typecheckTree(Tree t) {
	println("TYPE CHECKER: Getting Imports for Module");
	list[Import] imports = getImports(t);
	println("TYPE CHECKER: Got Imports");
	
	println("TYPE CHECKER: Generating Signature Map");
	SignatureMap sigMap = populateSignatureMap(imports);
	println("TYPE CHECKER: Generated Signature Map");
	
	println("TYPE CHECKER: Generating Symbol Table"); 
	globalSymbolTable = buildNamespace(t, sigMap);
	println("TYPE CHECKER: Generated Symbol Table");
	
	println("TYPE CHECKER: Type Checking Module");
	Tree tc = check(t);
	println("TYPE CHECKER: Type Checked Module");
	
	println("TYPE CHECKER: Retagging Names with Type Information");
	tc = retagNames(tc);
	println("TYPE CHECKER: Retagged Names");
	
	if (isFailType(tc@rtype)) tc = tc[@messages = { error(l,s) | RFailType(allFailures) := tc@rtype, <s,l> <- allFailures }];
	if (debug && isFailType(tc@rtype)) {
		println("TYPE CHECKER: Found type checking errors");
		for (RFailType(allFailures) := tc@rtype, <s,l> <- allFailures) println("<l>: <s>");
	}
	return tc;
}


public SymbolTable justGenerateTable(Tree t) {
	println("TYPE CHECKER: Getting Imports for Module");
	list[Import] imports = getImports(t);
	println("TYPE CHECKER: Got Imports");
	
	println("TYPE CHECKER: Generating Signature Map");
	SignatureMap sigMap = populateSignatureMap(imports);
	println("TYPE CHECKER: Generated Signature Map");
	
	println("TYPE CHECKER: Generating Symbol Table"); 
	symbolTable = buildNamespace(t, sigMap);
	println("TYPE CHECKER: Generated Symbol Table");
	
	return symbolTable;
}

public Tree typecheckTreeWithExistingTable(SymbolTable symbolTable, Tree t) {
	globalSymbolTable = symbolTable;
	
	println("TYPE CHECKER: Type Checking Module");
	Tree tc = check(t);
	println("TYPE CHECKER: Type Checked Module");
	
	println("TYPE CHECKER: Retagging Names with Type Information");
	tc = retagNames(tc);
	println("TYPE CHECKER: Retagged Names");
	
	if (isFailType(tc@rtype)) tc = tc[@messages = { error(l,s) | RFailType(allFailures) := tc@rtype, <s,l> <- allFailures }];
	if (debug && isFailType(tc@rtype)) {
		println("TYPE CHECKER: Found type checking errors");
		for (RFailType(allFailures) := tc@rtype, <s,l> <- allFailures) println("<l>: <s>");
	}
	return tc;
}