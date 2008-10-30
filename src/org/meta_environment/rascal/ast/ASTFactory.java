package org.meta_environment.rascal.ast;
import org.eclipse.imp.pdb.facts.ITree;
import java.util.Collections;
public class ASTFactory
{
  java.util.Map < AbstractAST, AbstractAST > table =
    new java.util.Hashtable < AbstractAST, AbstractAST > ();

  public Body.Ambiguity makeBodyAmbiguity (java.util.List < Body >
					   alternatives)
  {
    Body.Ambiguity amb = new Body.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Body.Toplevels makeBodyToplevels (ITree tree,
					   java.util.List < Toplevel >
					   toplevels)
  {
    Body.Toplevels x =
      new Body.Toplevels (tree,
			  params2expressions (java.util.List < Toplevel >
					      toplevels));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Formal.Ambiguity makeFormalAmbiguity (java.util.List < Formal >
					       alternatives)
  {
    Formal.Ambiguity amb = new Formal.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Formal.TypeName makeFormalTypeName (ITree tree, Type type, Name name)
  {
    Formal.TypeName x = new Formal.TypeName (tree, type, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Formals.Ambiguity makeFormalsAmbiguity (java.util.List < Formals >
						 alternatives)
  {
    Formals.Ambiguity amb = new Formals.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Formals.Default makeFormalsDefault (ITree tree,
					     java.util.List < Formal >
					     formals)
  {
    Formals.Default x =
      new Formals.Default (tree,
			   params2expressions (java.util.List < Formal >
					       formals));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Parameters.VarArgs makeParametersVarArgs (ITree tree,
						   Formals formals)
  {
    Parameters.VarArgs x = new Parameters.VarArgs (tree, formals);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Parameters.Ambiguity makeParametersAmbiguity (java.util.List <
						       Parameters >
						       alternatives)
  {
    Parameters.Ambiguity amb = new Parameters.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Parameters.Default makeParametersDefault (ITree tree,
						   Formals formals)
  {
    Parameters.Default x = new Parameters.Default (tree, formals);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Visit makeExpressionVisit (ITree tree, Visit visit)
  {
    Expression.Visit x = new Expression.Visit (tree, visit);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Forall makeExpressionForall (ITree tree,
						 ValueProducer producers,
						 Expression expression)
  {
    Expression.Forall x = new Expression.Forall (tree, producers, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Exists makeExpressionExists (ITree tree,
						 ValueProducer producer,
						 Expression expression)
  {
    Expression.Exists x = new Expression.Exists (tree, producer, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Comprehension makeExpressionComprehension (ITree tree,
							       Comprehension
							       comprehension)
  {
    Expression.Comprehension x =
      new Expression.Comprehension (tree, comprehension);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.
    TypedVariablePattern makeExpressionTypedVariablePattern (ITree tree,
							     Type type,
							     Name name)
  {
    Expression.TypedVariablePattern x =
      new Expression.TypedVariablePattern (tree, type, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.QualifiedName makeExpressionQualifiedName (ITree tree,
							       QualifiedName
							       qualifiedName)
  {
    Expression.QualifiedName x =
      new Expression.QualifiedName (tree, qualifiedName);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.
    AreaInFileLocation makeExpressionAreaInFileLocation (ITree tree,
							 Expression filename,
							 Expression area)
  {
    Expression.AreaInFileLocation x =
      new Expression.AreaInFileLocation (tree, filename, area);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.AreaLocation makeExpressionAreaLocation (ITree tree,
							     Expression area)
  {
    Expression.AreaLocation x = new Expression.AreaLocation (tree, area);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.FileLocation makeExpressionFileLocation (ITree tree,
							     Expression
							     filename)
  {
    Expression.FileLocation x = new Expression.FileLocation (tree, filename);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Area makeExpressionArea (ITree tree)
  {
    Expression.Area x = new Expression.Area (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Location makeExpressionLocation (ITree tree)
  {
    Expression.Location x = new Expression.Location (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.MapTuple makeExpressionMapTuple (ITree tree,
						     Expression from,
						     Expression to)
  {
    Expression.MapTuple x = new Expression.MapTuple (tree, from, to);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Tuple makeExpressionTuple (ITree tree, Expression first,
					       java.util.List < Expression >
					       rest)
  {
    Expression.Tuple x =
      new Expression.Tuple (tree, first,
			    params2expressions (java.util.List < Expression >
						rest));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Set makeExpressionSet (ITree tree,
					   java.util.List < Expression >
					   elements)
  {
    Expression.Set x =
      new Expression.Set (tree,
			  params2expressions (java.util.List < Expression >
					      elements));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.StepRange makeExpressionStepRange (ITree tree,
						       Expression from,
						       Expression by,
						       Expression to)
  {
    Expression.StepRange x = new Expression.StepRange (tree, from, by, to);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Range makeExpressionRange (ITree tree, Expression from,
					       Expression to)
  {
    Expression.Range x = new Expression.Range (tree, from, to);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.List makeExpressionList (ITree tree,
					     java.util.List < Expression >
					     elements)
  {
    Expression.List x =
      new Expression.List (tree,
			   params2expressions (java.util.List < Expression >
					       elements));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.CallOrTree makeExpressionCallOrTree (ITree tree,
							 Name name,
							 java.util.List <
							 Expression >
							 arguments)
  {
    Expression.CallOrTree x =
      new Expression.CallOrTree (tree, name,
				 params2expressions (java.util.List <
						     Expression > arguments));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Literal makeExpressionLiteral (ITree tree,
						   Literal literal)
  {
    Expression.Literal x = new Expression.Literal (tree, literal);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Operator makeExpressionOperator (ITree tree,
						     StandardOperator
						     operator)
  {
    Expression.Operator x = new Expression.Operator (tree, operator);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.IfThenElse makeExpressionIfThenElse (ITree tree,
							 Expression condition,
							 Expression thenExp,
							 Expression elseExp)
  {
    Expression.IfThenElse x =
      new Expression.IfThenElse (tree, condition, thenExp, elseExp);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.IfDefined makeExpressionIfDefined (ITree tree,
						       Expression lhs,
						       Expression rhs)
  {
    Expression.IfDefined x = new Expression.IfDefined (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Or makeExpressionOr (ITree tree, Expression lhs,
					 Expression rhs)
  {
    Expression.Or x = new Expression.Or (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.And makeExpressionAnd (ITree tree, Expression lhs,
					   Expression rhs)
  {
    Expression.And x = new Expression.And (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.In makeExpressionIn (ITree tree, Expression lhs,
					 Expression rhs)
  {
    Expression.In x = new Expression.In (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.NotIn makeExpressionNotIn (ITree tree, Expression lhs,
					       Expression rhs)
  {
    Expression.NotIn x = new Expression.NotIn (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.NonEquals makeExpressionNonEquals (ITree tree,
						       Expression lhs,
						       Expression rhs)
  {
    Expression.NonEquals x = new Expression.NonEquals (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Equals makeExpressionEquals (ITree tree, Expression lhs,
						 Expression rhs)
  {
    Expression.Equals x = new Expression.Equals (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.GreaterThanOrEq makeExpressionGreaterThanOrEq (ITree tree,
								   Expression
								   lhs,
								   Expression
								   rhs)
  {
    Expression.GreaterThanOrEq x =
      new Expression.GreaterThanOrEq (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.GreaterThan makeExpressionGreaterThan (ITree tree,
							   Expression lhs,
							   Expression rhs)
  {
    Expression.GreaterThan x = new Expression.GreaterThan (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.LessThanOrEq makeExpressionLessThanOrEq (ITree tree,
							     Expression lhs,
							     Expression rhs)
  {
    Expression.LessThanOrEq x = new Expression.LessThanOrEq (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.LessThan makeExpressionLessThan (ITree tree,
						     Expression lhs,
						     Expression rhs)
  {
    Expression.LessThan x = new Expression.LessThan (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.NoMatch makeExpressionNoMatch (ITree tree, Expression lhs,
						   Expression rhs)
  {
    Expression.NoMatch x = new Expression.NoMatch (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Match makeExpressionMatch (ITree tree, Expression lhs,
					       Expression rhs)
  {
    Expression.Match x = new Expression.Match (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Substraction makeExpressionSubstraction (ITree tree,
							     Expression lhs,
							     Expression rhs)
  {
    Expression.Substraction x = new Expression.Substraction (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Addition makeExpressionAddition (ITree tree,
						     Expression lhs,
						     Expression rhs)
  {
    Expression.Addition x = new Expression.Addition (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Division makeExpressionDivision (ITree tree,
						     Expression lhs,
						     Expression rhs)
  {
    Expression.Division x = new Expression.Division (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Intersection makeExpressionIntersection (ITree tree,
							     Expression lhs,
							     Expression rhs)
  {
    Expression.Intersection x = new Expression.Intersection (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Product makeExpressionProduct (ITree tree, Expression lhs,
						   Expression rhs)
  {
    Expression.Product x = new Expression.Product (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Negation makeExpressionNegation (ITree tree,
						     Expression argument)
  {
    Expression.Negation x = new Expression.Negation (tree, argument);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Annotation makeExpressionAnnotation (ITree tree,
							 Expression
							 expression,
							 Name name)
  {
    Expression.Annotation x =
      new Expression.Annotation (tree, expression, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.
    TransitiveClosure makeExpressionTransitiveClosure (ITree tree,
						       Expression argument)
  {
    Expression.TransitiveClosure x =
      new Expression.TransitiveClosure (tree, argument);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.
    TransitiveReflexiveClosure makeExpressionTransitiveReflexiveClosure (ITree
									 tree,
									 Expression
									 argument)
  {
    Expression.TransitiveReflexiveClosure x =
      new Expression.TransitiveReflexiveClosure (tree, argument);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Subscript makeExpressionSubscript (ITree tree,
						       Expression expression,
						       Expression subscript)
  {
    Expression.Subscript x =
      new Expression.Subscript (tree, expression, subscript);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.FieldAccess makeExpressionFieldAccess (ITree tree,
							   Expression
							   expression,
							   Name field)
  {
    Expression.FieldAccess x =
      new Expression.FieldAccess (tree, expression, field);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.FieldUpdate makeExpressionFieldUpdate (ITree tree,
							   Expression
							   expression,
							   Name key,
							   Expression
							   replacement)
  {
    Expression.FieldUpdate x =
      new Expression.FieldUpdate (tree, expression, key, replacement);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.ClosureCall makeExpressionClosureCall (ITree tree,
							   Expression closure,
							   java.util.List <
							   Expression >
							   arguments)
  {
    Expression.ClosureCall x =
      new Expression.ClosureCall (tree, closure,
				  params2expressions (java.util.List <
						      Expression >
						      arguments));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Expression.Ambiguity makeExpressionAmbiguity (java.util.List <
						       Expression >
						       alternatives)
  {
    Expression.Ambiguity amb = new Expression.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Expression.Closure makeExpressionClosure (ITree tree, Type type,
						   java.util.List <
						   Statement > statements)
  {
    Expression.Closure x =
      new Expression.Closure (tree, type,
			      params2expressions (java.util.List < Statement >
						  statements));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public SymbolLiteral.Ambiguity makeSymbolLiteralAmbiguity (java.util.List <
							     SymbolLiteral >
							     alternatives)
  {
    SymbolLiteral.Ambiguity amb = new SymbolLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Literal.String makeLiteralString (ITree tree, StringLiteral string)
  {
    Literal.String x = new Literal.String (tree, string);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Literal.Double makeLiteralDouble (ITree tree,
					   FloatingPointLiteral double)
  {
    Literal.Double x = new Literal.Double (tree, double);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Literal.Integer makeLiteralInteger (ITree tree,
					     IntegerLiteral integer)
  {
    Literal.Integer x = new Literal.Integer (tree, integer);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Literal.Boolean makeLiteralBoolean (ITree tree,
					     BooleanLiteral boolean)
  {
    Literal.Boolean x = new Literal.Boolean (tree, boolean);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Literal.Symbol makeLiteralSymbol (ITree tree, SymbolLiteral symbol)
  {
    Literal.Symbol x = new Literal.Symbol (tree, symbol);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Literal.Ambiguity makeLiteralAmbiguity (java.util.List < Literal >
						 alternatives)
  {
    Literal.Ambiguity amb = new Literal.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Literal.RegExp makeLiteralRegExp (ITree tree, RegExpLiteral regExp)
  {
    Literal.RegExp x = new Literal.RegExp (tree, regExp);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Bound.Default makeBoundDefault (ITree tree, Expression expression)
  {
    Bound.Default x = new Bound.Default (tree, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Bound.Ambiguity makeBoundAmbiguity (java.util.List < Bound >
					     alternatives)
  {
    Bound.Ambiguity amb = new Bound.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Bound.Empty makeBoundEmpty (ITree tree)
  {
    Bound.Empty x = new Bound.Empty (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.GlobalDirective makeStatementGlobalDirective (ITree tree,
								 Type type,
								 java.util.
								 List <
								 QualifiedName
								 > names)
  {
    Statement.GlobalDirective x =
      new Statement.GlobalDirective (tree, type,
				     params2expressions (java.util.List <
							 QualifiedName >
							 names));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.
    VariableDeclaration makeStatementVariableDeclaration (ITree tree,
							  LocalVariableDeclaration
							  declaration)
  {
    Statement.VariableDeclaration x =
      new Statement.VariableDeclaration (tree, declaration);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.
    FunctionDeclaration makeStatementFunctionDeclaration (ITree tree,
							  FunctionDeclaration
							  functionDeclaration)
  {
    Statement.FunctionDeclaration x =
      new Statement.FunctionDeclaration (tree, functionDeclaration);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Block makeStatementBlock (ITree tree, Label label,
					     java.util.List < Statement >
					     statements)
  {
    Statement.Block x =
      new Statement.Block (tree, label,
			   params2expressions (java.util.List < Statement >
					       statements));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.TryFinally makeStatementTryFinally (ITree tree,
						       Statement body,
						       java.util.List <
						       Catch > handlers,
						       Statement finallyBody)
  {
    Statement.TryFinally x =
      new Statement.TryFinally (tree, body,
				params2expressions (java.util.List < Catch >
						    handlers,
						    Statement finallyBody));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Try makeStatementTry (ITree tree, Statement body,
					 java.util.List < Catch > handlers)
  {
    Statement.Try x =
      new Statement.Try (tree, body,
			 params2expressions (java.util.List < Catch >
					     handlers));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Fail makeStatementFail (ITree tree)
  {
    Statement.Fail x = new Statement.Fail (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.ReturnVoid makeStatementReturnVoid (ITree tree)
  {
    Statement.ReturnVoid x = new Statement.ReturnVoid (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Continue makeStatementContinue (ITree tree)
  {
    Statement.Continue x = new Statement.Continue (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Break makeStatementBreak (ITree tree)
  {
    Statement.Break x = new Statement.Break (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Throw makeStatementThrow (ITree tree,
					     Expression expression)
  {
    Statement.Throw x = new Statement.Throw (tree, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Insert makeStatementInsert (ITree tree,
					       Expression expression)
  {
    Statement.Insert x = new Statement.Insert (tree, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Return makeStatementReturn (ITree tree,
					       Expression expression)
  {
    Statement.Return x = new Statement.Return (tree, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Assert makeStatementAssert (ITree tree,
					       StringLiteral label,
					       Expression expression)
  {
    Statement.Assert x = new Statement.Assert (tree, label, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Assignment makeStatementAssignment (ITree tree,
						       java.util.List <
						       Assignable >
						       assignables,
						       Assignment operator,
						       java.util.List <
						       Expression >
						       expressions)
  {
    Statement.Assignment x =
      new Statement.Assignment (tree,
				params2expressions (java.util.List <
						    Assignable > assignables,
						    Assignment operator,
						    java.util.List <
						    Expression >
						    expressions));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Visit makeStatementVisit (ITree tree, Visit visit)
  {
    Statement.Visit x = new Statement.Visit (tree, visit);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Expression makeStatementExpression (ITree tree,
						       Expression expression)
  {
    Statement.Expression x = new Statement.Expression (tree, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Switch makeStatementSwitch (ITree tree, Label label,
					       Expression expression,
					       java.util.List < Case > cases)
  {
    Statement.Switch x =
      new Statement.Switch (tree, label, expression,
			    params2expressions (java.util.List < Case >
						cases));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.IfThen makeStatementIfThen (ITree tree, Label label,
					       Condition condition,
					       Statement thenStatement)
  {
    Statement.IfThen x =
      new Statement.IfThen (tree, label, condition, thenStatement);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.IfThenElse makeStatementIfThenElse (ITree tree,
						       Label label,
						       Condition condition,
						       Statement
						       thenStatement,
						       Statement
						       elseStatement)
  {
    Statement.IfThenElse x =
      new Statement.IfThenElse (tree, label, condition, thenStatement,
				elseStatement);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.DoWhile makeStatementDoWhile (ITree tree, Label label,
						 Statement body,
						 Expression condition)
  {
    Statement.DoWhile x =
      new Statement.DoWhile (tree, label, body, condition);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.While makeStatementWhile (ITree tree, Label label,
					     Expression condition,
					     Statement body)
  {
    Statement.While x = new Statement.While (tree, label, condition, body);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.For makeStatementFor (ITree tree, Label label,
					 java.util.List < Generator >
					 generators, Statement body)
  {
    Statement.For x =
      new Statement.For (tree, label,
			 params2expressions (java.util.List < Generator >
					     generators, Statement body));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Statement.Ambiguity makeStatementAmbiguity (java.util.List <
						     Statement > alternatives)
  {
    Statement.Ambiguity amb = new Statement.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Statement.Solve makeStatementSolve (ITree tree,
					     java.util.List < Declarator >
					     declarations, Statement body)
  {
    Statement.Solve x =
      new Statement.Solve (tree,
			   params2expressions (java.util.List < Declarator >
					       declarations, Statement body));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Condition.Conjunction makeConditionConjunction (ITree tree,
							 Condition lhs,
							 Condition rhs)
  {
    Condition.Conjunction x = new Condition.Conjunction (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Condition.Expression makeConditionExpression (ITree tree,
						       Expression expression)
  {
    Condition.Expression x = new Condition.Expression (tree, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Condition.NoMatch makeConditionNoMatch (ITree tree, Pattern pattern,
						 Expression expression)
  {
    Condition.NoMatch x = new Condition.NoMatch (tree, pattern, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Condition.Ambiguity makeConditionAmbiguity (java.util.List <
						     Condition > alternatives)
  {
    Condition.Ambiguity amb = new Condition.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Condition.Match makeConditionMatch (ITree tree, Pattern pattern,
					     Expression expression)
  {
    Condition.Match x = new Condition.Match (tree, pattern, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public NoElseMayFollow.Ambiguity makeNoElseMayFollowAmbiguity (java.util.
								 List <
								 NoElseMayFollow
								 >
								 alternatives)
  {
    NoElseMayFollow.Ambiguity amb =
      new NoElseMayFollow.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Assignable.Constructor makeAssignableConstructor (ITree tree,
							   Name name,
							   java.util.List <
							   Assignable >
							   arguments)
  {
    Assignable.Constructor x =
      new Assignable.Constructor (tree, name,
				  params2expressions (java.util.List <
						      Assignable >
						      arguments));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignable.Tuple makeAssignableTuple (ITree tree, Assignable first,
					       java.util.List < Assignable >
					       rest)
  {
    Assignable.Tuple x =
      new Assignable.Tuple (tree, first,
			    params2expressions (java.util.List < Assignable >
						rest));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignable.Annotation makeAssignableAnnotation (ITree tree,
							 Assignable receiver,
							 Expression
							 annotation)
  {
    Assignable.Annotation x =
      new Assignable.Annotation (tree, receiver, annotation);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignable.IfDefined makeAssignableIfDefined (ITree tree,
						       Assignable receiver,
						       Expression condition)
  {
    Assignable.IfDefined x =
      new Assignable.IfDefined (tree, receiver, condition);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignable.FieldAccess makeAssignableFieldAccess (ITree tree,
							   Assignable
							   receiver,
							   Name field)
  {
    Assignable.FieldAccess x =
      new Assignable.FieldAccess (tree, receiver, field);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignable.Subscript makeAssignableSubscript (ITree tree,
						       Assignable receiver,
						       Expression subscript)
  {
    Assignable.Subscript x =
      new Assignable.Subscript (tree, receiver, subscript);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignable.Ambiguity makeAssignableAmbiguity (java.util.List <
						       Assignable >
						       alternatives)
  {
    Assignable.Ambiguity amb = new Assignable.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Assignable.Variable makeAssignableVariable (ITree tree,
						     QualifiedName
						     qualifiedName)
  {
    Assignable.Variable x = new Assignable.Variable (tree, qualifiedName);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignment.Interesection makeAssignmentInteresection (ITree tree)
  {
    Assignment.Interesection x = new Assignment.Interesection (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignment.Division makeAssignmentDivision (ITree tree)
  {
    Assignment.Division x = new Assignment.Division (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignment.Product makeAssignmentProduct (ITree tree)
  {
    Assignment.Product x = new Assignment.Product (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignment.Substraction makeAssignmentSubstraction (ITree tree)
  {
    Assignment.Substraction x = new Assignment.Substraction (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignment.Addition makeAssignmentAddition (ITree tree)
  {
    Assignment.Addition x = new Assignment.Addition (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Assignment.Ambiguity makeAssignmentAmbiguity (java.util.List <
						       Assignment >
						       alternatives)
  {
    Assignment.Ambiguity amb = new Assignment.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Assignment.Default makeAssignmentDefault (ITree tree)
  {
    Assignment.Default x = new Assignment.Default (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Label.Default makeLabelDefault (ITree tree, Name name)
  {
    Label.Default x = new Label.Default (tree, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Label.Ambiguity makeLabelAmbiguity (java.util.List < Label >
					     alternatives)
  {
    Label.Ambiguity amb = new Label.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Label.Empty makeLabelEmpty (ITree tree)
  {
    Label.Empty x = new Label.Empty (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Break.Unlabeled makeBreakUnlabeled (ITree tree)
  {
    Break.Unlabeled x = new Break.Unlabeled (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Break.Ambiguity makeBreakAmbiguity (java.util.List < Break >
					     alternatives)
  {
    Break.Ambiguity amb = new Break.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Break.Labeled makeBreakLabeled (ITree tree, Name label)
  {
    Break.Labeled x = new Break.Labeled (tree, label);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Catch.Binding makeCatchBinding (ITree tree, Type type, Name name,
					 Statement body)
  {
    Catch.Binding x = new Catch.Binding (tree, type, name, body);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Catch.Ambiguity makeCatchAmbiguity (java.util.List < Catch >
					     alternatives)
  {
    Catch.Ambiguity amb = new Catch.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Catch.Default makeCatchDefault (ITree tree, Statement body)
  {
    Catch.Default x = new Catch.Default (tree, body);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declarator.Ambiguity makeDeclaratorAmbiguity (java.util.List <
						       Declarator >
						       alternatives)
  {
    Declarator.Ambiguity amb = new Declarator.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Declarator.Default makeDeclaratorDefault (ITree tree, Type type,
						   java.util.List < Variable >
						   variables)
  {
    Declarator.Default x =
      new Declarator.Default (tree, type,
			      params2expressions (java.util.List < Variable >
						  variables));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public LocalVariableDeclaration.
    Dynamic makeLocalVariableDeclarationDynamic (ITree tree,
						 Declarator declarator)
  {
    LocalVariableDeclaration.Dynamic x =
      new LocalVariableDeclaration.Dynamic (tree, declarator);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public LocalVariableDeclaration.
    Ambiguity makeLocalVariableDeclarationAmbiguity (java.util.List <
						     LocalVariableDeclaration
						     > alternatives)
  {
    LocalVariableDeclaration.Ambiguity amb =
      new LocalVariableDeclaration.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public LocalVariableDeclaration.
    Default makeLocalVariableDeclarationDefault (ITree tree,
						 Declarator declarator)
  {
    LocalVariableDeclaration.Default x =
      new LocalVariableDeclaration.Default (tree, declarator);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public RegExpLiteral.Ambiguity makeRegExpLiteralAmbiguity (java.util.List <
							     RegExpLiteral >
							     alternatives)
  {
    RegExpLiteral.Ambiguity amb = new RegExpLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public RegExpModifier.Ambiguity makeRegExpModifierAmbiguity (java.util.
							       List <
							       RegExpModifier
							       > alternatives)
  {
    RegExpModifier.Ambiguity amb =
      new RegExpModifier.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Backslash.Ambiguity makeBackslashAmbiguity (java.util.List <
						     Backslash > alternatives)
  {
    Backslash.Ambiguity amb = new Backslash.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public RegExp.Ambiguity makeRegExpAmbiguity (java.util.List < RegExp >
					       alternatives)
  {
    RegExp.Ambiguity amb = new RegExp.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public NamedRegExp.Ambiguity makeNamedRegExpAmbiguity (java.util.List <
							 NamedRegExp >
							 alternatives)
  {
    NamedRegExp.Ambiguity amb = new NamedRegExp.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public NamedBackslash.Ambiguity makeNamedBackslashAmbiguity (java.util.
							       List <
							       NamedBackslash
							       > alternatives)
  {
    NamedBackslash.Ambiguity amb =
      new NamedBackslash.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Visibility.Private makeVisibilityPrivate (ITree tree)
  {
    Visibility.Private x = new Visibility.Private (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Visibility.Ambiguity makeVisibilityAmbiguity (java.util.List <
						       Visibility >
						       alternatives)
  {
    Visibility.Ambiguity amb = new Visibility.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Visibility.Public makeVisibilityPublic (ITree tree)
  {
    Visibility.Public x = new Visibility.Public (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Toplevel.DefaultVisibility makeToplevelDefaultVisibility (ITree tree,
								   Declaration
								   declaration)
  {
    Toplevel.DefaultVisibility x =
      new Toplevel.DefaultVisibility (tree, declaration);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Toplevel.Ambiguity makeToplevelAmbiguity (java.util.List < Toplevel >
						   alternatives)
  {
    Toplevel.Ambiguity amb = new Toplevel.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Toplevel.GivenVisibility makeToplevelGivenVisibility (ITree tree,
							       Visibility
							       visibility,
							       Declaration
							       declaration)
  {
    Toplevel.GivenVisibility x =
      new Toplevel.GivenVisibility (tree, visibility, declaration);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declaration.Tag makeDeclarationTag (ITree tree, Kind kind, Name name,
					     Tags tags,
					     java.util.List < Type > types)
  {
    Declaration.Tag x =
      new Declaration.Tag (tree, kind, name, tags,
			   params2expressions (java.util.List < Type >
					       types));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declaration.Annotation makeDeclarationAnnotation (ITree tree,
							   Type type,
							   Name name,
							   Tags tags,
							   java.util.List <
							   Type > types)
  {
    Declaration.Annotation x =
      new Declaration.Annotation (tree, type, name, tags,
				  params2expressions (java.util.List < Type >
						      types));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declaration.Rule makeDeclarationRule (ITree tree, Name name,
					       Tags tags, Rule rule)
  {
    Declaration.Rule x = new Declaration.Rule (tree, name, tags, rule);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declaration.Variable makeDeclarationVariable (ITree tree, Type type,
						       java.util.List <
						       Variable > variables)
  {
    Declaration.Variable x =
      new Declaration.Variable (tree, type,
				params2expressions (java.util.List <
						    Variable > variables));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declaration.Function makeDeclarationFunction (ITree tree,
						       FunctionDeclaration
						       functionDeclaration)
  {
    Declaration.Function x =
      new Declaration.Function (tree, functionDeclaration);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declaration.Data makeDeclarationData (ITree tree, UserType user,
					       Tags tags,
					       java.util.List < Variant >
					       variants)
  {
    Declaration.Data x =
      new Declaration.Data (tree, user, tags,
			    params2expressions (java.util.List < Variant >
						variants));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declaration.Type makeDeclarationType (ITree tree, Type base,
					       UserType user, Tags tags)
  {
    Declaration.Type x = new Declaration.Type (tree, base, user, tags);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Declaration.Ambiguity makeDeclarationAmbiguity (java.util.List <
							 Declaration >
							 alternatives)
  {
    Declaration.Ambiguity amb = new Declaration.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Declaration.View makeDeclarationView (ITree tree, Name view,
					       Name type, Tags tags,
					       java.util.List < Alternative >
					       alternatives)
  {
    Declaration.View x =
      new Declaration.View (tree, view, type, tags,
			    params2expressions (java.util.List < Alternative >
						alternatives));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Alternative.Ambiguity makeAlternativeAmbiguity (java.util.List <
							 Alternative >
							 alternatives)
  {
    Alternative.Ambiguity amb = new Alternative.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Alternative.NamedType makeAlternativeNamedType (ITree tree,
							 Name name, Type type)
  {
    Alternative.NamedType x = new Alternative.NamedType (tree, name, type);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Variant.NillaryConstructor makeVariantNillaryConstructor (ITree tree,
								   Name name)
  {
    Variant.NillaryConstructor x =
      new Variant.NillaryConstructor (tree, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Variant.NAryConstructor makeVariantNAryConstructor (ITree tree,
							     Name name,
							     java.util.List <
							     TypeArg >
							     arguments)
  {
    Variant.NAryConstructor x =
      new Variant.NAryConstructor (tree, name,
				   params2expressions (java.util.List <
						       TypeArg > arguments));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Variant.Ambiguity makeVariantAmbiguity (java.util.List < Variant >
						 alternatives)
  {
    Variant.Ambiguity amb = new Variant.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Variant.Type makeVariantType (ITree tree, Type type, Name name)
  {
    Variant.Type x = new Variant.Type (tree, type, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.NotIn makeStandardOperatorNotIn (ITree tree)
  {
    StandardOperator.NotIn x = new StandardOperator.NotIn (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.In makeStandardOperatorIn (ITree tree)
  {
    StandardOperator.In x = new StandardOperator.In (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.Not makeStandardOperatorNot (ITree tree)
  {
    StandardOperator.Not x = new StandardOperator.Not (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.Or makeStandardOperatorOr (ITree tree)
  {
    StandardOperator.Or x = new StandardOperator.Or (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.And makeStandardOperatorAnd (ITree tree)
  {
    StandardOperator.And x = new StandardOperator.And (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.
    GreaterThanOrEq makeStandardOperatorGreaterThanOrEq (ITree tree)
  {
    StandardOperator.GreaterThanOrEq x =
      new StandardOperator.GreaterThanOrEq (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.
    GreaterThan makeStandardOperatorGreaterThan (ITree tree)
  {
    StandardOperator.GreaterThan x = new StandardOperator.GreaterThan (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.
    LessThanOrEq makeStandardOperatorLessThanOrEq (ITree tree)
  {
    StandardOperator.LessThanOrEq x =
      new StandardOperator.LessThanOrEq (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.LessThan makeStandardOperatorLessThan (ITree tree)
  {
    StandardOperator.LessThan x = new StandardOperator.LessThan (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.NotEquals makeStandardOperatorNotEquals (ITree tree)
  {
    StandardOperator.NotEquals x = new StandardOperator.NotEquals (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.Equals makeStandardOperatorEquals (ITree tree)
  {
    StandardOperator.Equals x = new StandardOperator.Equals (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.
    Intersection makeStandardOperatorIntersection (ITree tree)
  {
    StandardOperator.Intersection x =
      new StandardOperator.Intersection (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.Division makeStandardOperatorDivision (ITree tree)
  {
    StandardOperator.Division x = new StandardOperator.Division (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.Product makeStandardOperatorProduct (ITree tree)
  {
    StandardOperator.Product x = new StandardOperator.Product (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.
    Substraction makeStandardOperatorSubstraction (ITree tree)
  {
    StandardOperator.Substraction x =
      new StandardOperator.Substraction (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StandardOperator.Ambiguity makeStandardOperatorAmbiguity (java.util.
								   List <
								   StandardOperator
								   >
								   alternatives)
  {
    StandardOperator.Ambiguity amb =
      new StandardOperator.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public StandardOperator.Addition makeStandardOperatorAddition (ITree tree)
  {
    StandardOperator.Addition x = new StandardOperator.Addition (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public FunctionName.Operator makeFunctionNameOperator (ITree tree,
							 StandardOperator
							 operator)
  {
    FunctionName.Operator x = new FunctionName.Operator (tree, operator);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public FunctionName.Ambiguity makeFunctionNameAmbiguity (java.util.List <
							   FunctionName >
							   alternatives)
  {
    FunctionName.Ambiguity amb = new FunctionName.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public FunctionName.Name makeFunctionNameName (ITree tree, Name name)
  {
    FunctionName.Name x = new FunctionName.Name (tree, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public FunctionModifier.Ambiguity makeFunctionModifierAmbiguity (java.util.
								   List <
								   FunctionModifier
								   >
								   alternatives)
  {
    FunctionModifier.Ambiguity amb =
      new FunctionModifier.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public FunctionModifier.Java makeFunctionModifierJava (ITree tree)
  {
    FunctionModifier.Java x = new FunctionModifier.Java (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public FunctionModifiers.Ambiguity makeFunctionModifiersAmbiguity (java.
								     util.
								     List <
								     FunctionModifiers
								     >
								     alternatives)
  {
    FunctionModifiers.Ambiguity amb =
      new FunctionModifiers.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public FunctionModifiers.List makeFunctionModifiersList (ITree tree,
							   java.util.List <
							   FunctionModifier >
							   modifiers)
  {
    FunctionModifiers.List x =
      new FunctionModifiers.List (tree,
				  params2expressions (java.util.List <
						      FunctionModifier >
						      modifiers));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Signature.WithThrows makeSignatureWithThrows (ITree tree, Type type,
						       FunctionModifiers
						       modifiers,
						       FunctionName name,
						       Parameters parameters,
						       java.util.List < Type >
						       exceptions)
  {
    Signature.WithThrows x =
      new Signature.WithThrows (tree, type, modifiers, name, parameters,
				params2expressions (java.util.List < Type >
						    exceptions));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Signature.Ambiguity makeSignatureAmbiguity (java.util.List <
						     Signature > alternatives)
  {
    Signature.Ambiguity amb = new Signature.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Signature.NoThrows makeSignatureNoThrows (ITree tree, Type type,
						   FunctionModifiers
						   modifiers,
						   FunctionName name,
						   Parameters parameters)
  {
    Signature.NoThrows x =
      new Signature.NoThrows (tree, type, modifiers, name, parameters);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public FunctionDeclaration.
    Abstract makeFunctionDeclarationAbstract (ITree tree, Signature signature,
					      Tags tags)
  {
    FunctionDeclaration.Abstract x =
      new FunctionDeclaration.Abstract (tree, signature, tags);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public FunctionDeclaration.Ambiguity makeFunctionDeclarationAmbiguity (java.
									 util.
									 List
									 <
									 FunctionDeclaration
									 >
									 alternatives)
  {
    FunctionDeclaration.Ambiguity amb =
      new FunctionDeclaration.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public FunctionDeclaration.
    Default makeFunctionDeclarationDefault (ITree tree, Signature signature,
					    Tags tags, FunctionBody body)
  {
    FunctionDeclaration.Default x =
      new FunctionDeclaration.Default (tree, signature, tags, body);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public FunctionBody.Ambiguity makeFunctionBodyAmbiguity (java.util.List <
							   FunctionBody >
							   alternatives)
  {
    FunctionBody.Ambiguity amb = new FunctionBody.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public FunctionBody.Default makeFunctionBodyDefault (ITree tree,
						       java.util.List <
						       Statement > statements)
  {
    FunctionBody.Default x =
      new FunctionBody.Default (tree,
				params2expressions (java.util.List <
						    Statement > statements));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Variable.Ambiguity makeVariableAmbiguity (java.util.List < Variable >
						   alternatives)
  {
    Variable.Ambiguity amb = new Variable.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Variable.
    GivenInitialization makeVariableGivenInitialization (ITree tree,
							 Name name, Tags tags,
							 Expression initial)
  {
    Variable.GivenInitialization x =
      new Variable.GivenInitialization (tree, name, tags, initial);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.All makeKindAll (ITree tree)
  {
    Kind.All x = new Kind.All (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.Tag makeKindTag (ITree tree)
  {
    Kind.Tag x = new Kind.Tag (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.Anno makeKindAnno (ITree tree)
  {
    Kind.Anno x = new Kind.Anno (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.Type makeKindType (ITree tree)
  {
    Kind.Type x = new Kind.Type (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.View makeKindView (ITree tree)
  {
    Kind.View x = new Kind.View (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.Data makeKindData (ITree tree)
  {
    Kind.Data x = new Kind.Data (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.Variable makeKindVariable (ITree tree)
  {
    Kind.Variable x = new Kind.Variable (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.Function makeKindFunction (ITree tree)
  {
    Kind.Function x = new Kind.Function (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Kind.Ambiguity makeKindAmbiguity (java.util.List < Kind >
					   alternatives)
  {
    Kind.Ambiguity amb = new Kind.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Kind.Module makeKindModule (ITree tree)
  {
    Kind.Module x = new Kind.Module (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Comment.Ambiguity makeCommentAmbiguity (java.util.List < Comment >
						 alternatives)
  {
    Comment.Ambiguity amb = new Comment.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public CommentChar.Ambiguity makeCommentCharAmbiguity (java.util.List <
							 CommentChar >
							 alternatives)
  {
    CommentChar.Ambiguity amb = new CommentChar.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Asterisk.Ambiguity makeAsteriskAmbiguity (java.util.List < Asterisk >
						   alternatives)
  {
    Asterisk.Ambiguity amb = new Asterisk.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public BasicType.Loc makeBasicTypeLoc (ITree tree)
  {
    BasicType.Loc x = new BasicType.Loc (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public BasicType.Void makeBasicTypeVoid (ITree tree)
  {
    BasicType.Void x = new BasicType.Void (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public BasicType.Term makeBasicTypeTerm (ITree tree)
  {
    BasicType.Term x = new BasicType.Term (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public BasicType.Value makeBasicTypeValue (ITree tree)
  {
    BasicType.Value x = new BasicType.Value (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public BasicType.String makeBasicTypeString (ITree tree)
  {
    BasicType.String x = new BasicType.String (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public BasicType.Double makeBasicTypeDouble (ITree tree)
  {
    BasicType.Double x = new BasicType.Double (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public BasicType.Int makeBasicTypeInt (ITree tree)
  {
    BasicType.Int x = new BasicType.Int (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public BasicType.Ambiguity makeBasicTypeAmbiguity (java.util.List <
						     BasicType > alternatives)
  {
    BasicType.Ambiguity amb = new BasicType.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public BasicType.Bool makeBasicTypeBool (ITree tree)
  {
    BasicType.Bool x = new BasicType.Bool (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public TypeArg.Named makeTypeArgNamed (ITree tree, Type type, Name name)
  {
    TypeArg.Named x = new TypeArg.Named (tree, type, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public TypeArg.Ambiguity makeTypeArgAmbiguity (java.util.List < TypeArg >
						 alternatives)
  {
    TypeArg.Ambiguity amb = new TypeArg.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public TypeArg.Default makeTypeArgDefault (ITree tree, Type type)
  {
    TypeArg.Default x = new TypeArg.Default (tree, type);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StructuredType.Tuple makeStructuredTypeTuple (ITree tree,
						       TypeArg first,
						       java.util.List <
						       TypeArg > rest)
  {
    StructuredType.Tuple x =
      new StructuredType.Tuple (tree, first,
				params2expressions (java.util.List < TypeArg >
						    rest));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StructuredType.Relation makeStructuredTypeRelation (ITree tree,
							     TypeArg first,
							     java.util.List <
							     TypeArg > rest)
  {
    StructuredType.Relation x =
      new StructuredType.Relation (tree, first,
				   params2expressions (java.util.List <
						       TypeArg > rest));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StructuredType.Map makeStructuredTypeMap (ITree tree, TypeArg first,
						   TypeArg second)
  {
    StructuredType.Map x = new StructuredType.Map (tree, first, second);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StructuredType.Set makeStructuredTypeSet (ITree tree,
						   TypeArg typeArg)
  {
    StructuredType.Set x = new StructuredType.Set (tree, typeArg);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StructuredType.Ambiguity makeStructuredTypeAmbiguity (java.util.
							       List <
							       StructuredType
							       > alternatives)
  {
    StructuredType.Ambiguity amb =
      new StructuredType.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public StructuredType.List makeStructuredTypeList (ITree tree,
						     TypeArg typeArg)
  {
    StructuredType.List x = new StructuredType.List (tree, typeArg);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public FunctionType.Ambiguity makeFunctionTypeAmbiguity (java.util.List <
							   FunctionType >
							   alternatives)
  {
    FunctionType.Ambiguity amb = new FunctionType.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public FunctionType.TypeArguments makeFunctionTypeTypeArguments (ITree tree,
								   Type type,
								   java.util.
								   List <
								   TypeArg >
								   arguments)
  {
    FunctionType.TypeArguments x =
      new FunctionType.TypeArguments (tree, type,
				      params2expressions (java.util.List <
							  TypeArg >
							  arguments));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public TypeVar.Bounded makeTypeVarBounded (ITree tree, Name name,
					     Type bound)
  {
    TypeVar.Bounded x = new TypeVar.Bounded (tree, name, bound);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public TypeVar.Ambiguity makeTypeVarAmbiguity (java.util.List < TypeVar >
						 alternatives)
  {
    TypeVar.Ambiguity amb = new TypeVar.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public TypeVar.Free makeTypeVarFree (ITree tree, Name name)
  {
    TypeVar.Free x = new TypeVar.Free (tree, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public UserType.Parametric makeUserTypeParametric (ITree tree, Name name,
						     java.util.List <
						     TypeVar > parameters)
  {
    UserType.Parametric x =
      new UserType.Parametric (tree, name,
			       params2expressions (java.util.List < TypeVar >
						   parameters));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public UserType.Ambiguity makeUserTypeAmbiguity (java.util.List < UserType >
						   alternatives)
  {
    UserType.Ambiguity amb = new UserType.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public UserType.Name makeUserTypeName (ITree tree, Name name)
  {
    UserType.Name x = new UserType.Name (tree, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public DataTypeSelector.Ambiguity makeDataTypeSelectorAmbiguity (java.util.
								   List <
								   DataTypeSelector
								   >
								   alternatives)
  {
    DataTypeSelector.Ambiguity amb =
      new DataTypeSelector.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public DataTypeSelector.Selector makeDataTypeSelectorSelector (ITree tree,
								 Name sort,
								 Name
								 production)
  {
    DataTypeSelector.Selector x =
      new DataTypeSelector.Selector (tree, sort, production);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Type.Selector makeTypeSelector (ITree tree,
					 DataTypeSelector selector)
  {
    Type.Selector x = new Type.Selector (tree, selector);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Type.Symbol makeTypeSymbol (ITree tree, Symbol symbol)
  {
    Type.Symbol x = new Type.Symbol (tree, symbol);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Type.User makeTypeUser (ITree tree, UserType user)
  {
    Type.User x = new Type.User (tree, user);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Type.Variable makeTypeVariable (ITree tree, TypeVar typeVar)
  {
    Type.Variable x = new Type.Variable (tree, typeVar);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Type.Function makeTypeFunction (ITree tree, FunctionType function)
  {
    Type.Function x = new Type.Function (tree, function);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Type.Structured makeTypeStructured (ITree tree,
					     StructuredType structured)
  {
    Type.Structured x = new Type.Structured (tree, structured);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Type.Ambiguity makeTypeAmbiguity (java.util.List < Type >
					   alternatives)
  {
    Type.Ambiguity amb = new Type.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Type.Basic makeTypeBasic (ITree tree, BasicType basic)
  {
    Type.Basic x = new Type.Basic (tree, basic);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StrChar.Ambiguity makeStrCharAmbiguity (java.util.List < StrChar >
						 alternatives)
  {
    StrChar.Ambiguity amb = new StrChar.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public StrChar.newline makeStrCharnewline (ITree tree)
  {
    StrChar.newline x = new StrChar.newline (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public StrCon.Ambiguity makeStrConAmbiguity (java.util.List < StrCon >
					       alternatives)
  {
    StrCon.Ambiguity amb = new StrCon.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Sort.Ambiguity makeSortAmbiguity (java.util.List < Sort >
					   alternatives)
  {
    Sort.Ambiguity amb = new Sort.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Symbol.
    CaseInsensitiveLiteral makeSymbolCaseInsensitiveLiteral (ITree tree,
							     SingleQuotedStrCon
							     singelQuotedString)
  {
    Symbol.CaseInsensitiveLiteral x =
      new Symbol.CaseInsensitiveLiteral (tree, singelQuotedString);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.Literal makeSymbolLiteral (ITree tree, StrCon string)
  {
    Symbol.Literal x = new Symbol.Literal (tree, string);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.LiftedSymbol makeSymbolLiftedSymbol (ITree tree,
						     Symbol symbol)
  {
    Symbol.LiftedSymbol x = new Symbol.LiftedSymbol (tree, symbol);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.CharacterClass makeSymbolCharacterClass (ITree tree,
							 CharClass charClass)
  {
    Symbol.CharacterClass x = new Symbol.CharacterClass (tree, charClass);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.Alternative makeSymbolAlternative (ITree tree, Symbol lhs,
						   Symbol rhs)
  {
    Symbol.Alternative x = new Symbol.Alternative (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.IterStarSep makeSymbolIterStarSep (ITree tree, Symbol symbol,
						   StrCon sep)
  {
    Symbol.IterStarSep x = new Symbol.IterStarSep (tree, symbol, sep);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.IterSep makeSymbolIterSep (ITree tree, Symbol symbol,
					   StrCon sep)
  {
    Symbol.IterSep x = new Symbol.IterSep (tree, symbol, sep);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.IterStar makeSymbolIterStar (ITree tree, Symbol symbol)
  {
    Symbol.IterStar x = new Symbol.IterStar (tree, symbol);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.Iter makeSymbolIter (ITree tree, Symbol symbol)
  {
    Symbol.Iter x = new Symbol.Iter (tree, symbol);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.Optional makeSymbolOptional (ITree tree, Symbol symbol)
  {
    Symbol.Optional x = new Symbol.Optional (tree, symbol);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.Sequence makeSymbolSequence (ITree tree, Symbol head,
					     java.util.List < Symbol > tail)
  {
    Symbol.Sequence x =
      new Symbol.Sequence (tree, head,
			   params2expressions (java.util.List < Symbol >
					       tail));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.Empty makeSymbolEmpty (ITree tree)
  {
    Symbol.Empty x = new Symbol.Empty (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.ParameterizedSort makeSymbolParameterizedSort (ITree tree,
							       Sort sort,
							       java.util.
							       List < Symbol >
							       parameters)
  {
    Symbol.ParameterizedSort x =
      new Symbol.ParameterizedSort (tree, sort,
				    params2expressions (java.util.List <
							Symbol > parameters));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Symbol.Ambiguity makeSymbolAmbiguity (java.util.List < Symbol >
					       alternatives)
  {
    Symbol.Ambiguity amb = new Symbol.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Symbol.Sort makeSymbolSort (ITree tree, Sort sort)
  {
    Symbol.Sort x = new Symbol.Sort (tree, sort);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public SingleQuotedStrChar.Ambiguity makeSingleQuotedStrCharAmbiguity (java.
									 util.
									 List
									 <
									 SingleQuotedStrChar
									 >
									 alternatives)
  {
    SingleQuotedStrChar.Ambiguity amb =
      new SingleQuotedStrChar.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public SingleQuotedStrCon.Ambiguity makeSingleQuotedStrConAmbiguity (java.
								       util.
								       List <
								       SingleQuotedStrCon
								       >
								       alternatives)
  {
    SingleQuotedStrCon.Ambiguity amb =
      new SingleQuotedStrCon.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public CharRange.Range makeCharRangeRange (ITree tree, Character start,
					     Character end)
  {
    CharRange.Range x = new CharRange.Range (tree, start, end);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public CharRange.Ambiguity makeCharRangeAmbiguity (java.util.List <
						     CharRange > alternatives)
  {
    CharRange.Ambiguity amb = new CharRange.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public CharRange.Character makeCharRangeCharacter (ITree tree,
						     Character character)
  {
    CharRange.Character x = new CharRange.Character (tree, character);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public CharRanges.Concatenate makeCharRangesConcatenate (ITree tree,
							   CharRanges lhs,
							   CharRanges rhs)
  {
    CharRanges.Concatenate x = new CharRanges.Concatenate (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public CharRanges.Ambiguity makeCharRangesAmbiguity (java.util.List <
						       CharRanges >
						       alternatives)
  {
    CharRanges.Ambiguity amb = new CharRanges.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public CharRanges.Range makeCharRangesRange (ITree tree, CharRange range)
  {
    CharRanges.Range x = new CharRanges.Range (tree, range);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public OptCharRanges.Present makeOptCharRangesPresent (ITree tree,
							 CharRanges ranges)
  {
    OptCharRanges.Present x = new OptCharRanges.Present (tree, ranges);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public OptCharRanges.Ambiguity makeOptCharRangesAmbiguity (java.util.List <
							     OptCharRanges >
							     alternatives)
  {
    OptCharRanges.Ambiguity amb = new OptCharRanges.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public OptCharRanges.Absent makeOptCharRangesAbsent (ITree tree)
  {
    OptCharRanges.Absent x = new OptCharRanges.Absent (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public CharClass.Union makeCharClassUnion (ITree tree, CharClass lhs,
					     CharClass rhs)
  {
    CharClass.Union x = new CharClass.Union (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public CharClass.Intersection makeCharClassIntersection (ITree tree,
							   CharClass lhs,
							   CharClass rhs)
  {
    CharClass.Intersection x = new CharClass.Intersection (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public CharClass.Difference makeCharClassDifference (ITree tree,
						       CharClass lhs,
						       CharClass rhs)
  {
    CharClass.Difference x = new CharClass.Difference (tree, lhs, rhs);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public CharClass.Complement makeCharClassComplement (ITree tree,
						       CharClass charClass)
  {
    CharClass.Complement x = new CharClass.Complement (tree, charClass);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public CharClass.Ambiguity makeCharClassAmbiguity (java.util.List <
						     CharClass > alternatives)
  {
    CharClass.Ambiguity amb = new CharClass.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public CharClass.SimpleCharclass makeCharClassSimpleCharclass (ITree tree,
								 OptCharRanges
								 optionalCharRanges)
  {
    CharClass.SimpleCharclass x =
      new CharClass.SimpleCharclass (tree, optionalCharRanges);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public NumChar.Ambiguity makeNumCharAmbiguity (java.util.List < NumChar >
						 alternatives)
  {
    NumChar.Ambiguity amb = new NumChar.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public ShortChar.Ambiguity makeShortCharAmbiguity (java.util.List <
						     ShortChar > alternatives)
  {
    ShortChar.Ambiguity amb = new ShortChar.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Character.LabelStart makeCharacterLabelStart (ITree tree)
  {
    Character.LabelStart x = new Character.LabelStart (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Character.Bottom makeCharacterBottom (ITree tree)
  {
    Character.Bottom x = new Character.Bottom (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Character.EOF makeCharacterEOF (ITree tree)
  {
    Character.EOF x = new Character.EOF (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Character.Top makeCharacterTop (ITree tree)
  {
    Character.Top x = new Character.Top (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Character.Short makeCharacterShort (ITree tree, ShortChar short)
  {
    Character.Short x = new Character.Short (tree, short);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Character.Ambiguity makeCharacterAmbiguity (java.util.List <
						     Character > alternatives)
  {
    Character.Ambiguity amb = new Character.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Character.Numeric makeCharacterNumeric (ITree tree, NumChar numeric)
  {
    Character.Numeric x = new Character.Numeric (tree, numeric);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Module.Ambiguity makeModuleAmbiguity (java.util.List < Module >
					       alternatives)
  {
    Module.Ambiguity amb = new Module.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Module.Default makeModuleDefault (ITree tree, Header header,
					   Body body)
  {
    Module.Default x = new Module.Default (tree, header, body);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public ModuleWord.Ambiguity makeModuleWordAmbiguity (java.util.List <
						       ModuleWord >
						       alternatives)
  {
    ModuleWord.Ambiguity amb = new ModuleWord.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public ModuleName.Ambiguity makeModuleNameAmbiguity (java.util.List <
						       ModuleName >
						       alternatives)
  {
    ModuleName.Ambiguity amb = new ModuleName.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public ModuleActuals.Ambiguity makeModuleActualsAmbiguity (java.util.List <
							     ModuleActuals >
							     alternatives)
  {
    ModuleActuals.Ambiguity amb = new ModuleActuals.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public ModuleActuals.Default makeModuleActualsDefault (ITree tree,
							 java.util.List <
							 Type > types)
  {
    ModuleActuals.Default x =
      new ModuleActuals.Default (tree,
				 params2expressions (java.util.List < Type >
						     types));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public ImportedModule.Default makeImportedModuleDefault (ITree tree,
							   ModuleName name)
  {
    ImportedModule.Default x = new ImportedModule.Default (tree, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public ImportedModule.Renamings makeImportedModuleRenamings (ITree tree,
							       ModuleName
							       name,
							       Renamings
							       renamings)
  {
    ImportedModule.Renamings x =
      new ImportedModule.Renamings (tree, name, renamings);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public ImportedModule.Actuals makeImportedModuleActuals (ITree tree,
							   ModuleName name,
							   ModuleActuals
							   actuals)
  {
    ImportedModule.Actuals x =
      new ImportedModule.Actuals (tree, name, actuals);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public ImportedModule.Ambiguity makeImportedModuleAmbiguity (java.util.
							       List <
							       ImportedModule
							       > alternatives)
  {
    ImportedModule.Ambiguity amb =
      new ImportedModule.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public ImportedModule.
    ActualsRenaming makeImportedModuleActualsRenaming (ITree tree,
						       ModuleName name,
						       ModuleActuals actuals,
						       Renamings renamings)
  {
    ImportedModule.ActualsRenaming x =
      new ImportedModule.ActualsRenaming (tree, name, actuals, renamings);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Renaming.Ambiguity makeRenamingAmbiguity (java.util.List < Renaming >
						   alternatives)
  {
    Renaming.Ambiguity amb = new Renaming.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Renaming.Default makeRenamingDefault (ITree tree, Name from, Name to)
  {
    Renaming.Default x = new Renaming.Default (tree, from, to);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Renamings.Ambiguity makeRenamingsAmbiguity (java.util.List <
						     Renamings > alternatives)
  {
    Renamings.Ambiguity amb = new Renamings.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Renamings.Default makeRenamingsDefault (ITree tree,
						 java.util.List < Renaming >
						 renamings)
  {
    Renamings.Default x =
      new Renamings.Default (tree,
			     params2expressions (java.util.List < Renaming >
						 renamings));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Import.Extend makeImportExtend (ITree tree, ImportedModule module)
  {
    Import.Extend x = new Import.Extend (tree, module);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Import.Ambiguity makeImportAmbiguity (java.util.List < Import >
					       alternatives)
  {
    Import.Ambiguity amb = new Import.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Import.Default makeImportDefault (ITree tree, ImportedModule module)
  {
    Import.Default x = new Import.Default (tree, module);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public ModuleParameters.Ambiguity makeModuleParametersAmbiguity (java.util.
								   List <
								   ModuleParameters
								   >
								   alternatives)
  {
    ModuleParameters.Ambiguity amb =
      new ModuleParameters.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public ModuleParameters.Default makeModuleParametersDefault (ITree tree,
							       java.util.
							       List <
							       TypeVar >
							       parameters)
  {
    ModuleParameters.Default x =
      new ModuleParameters.Default (tree,
				    params2expressions (java.util.List <
							TypeVar >
							parameters));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Header.Parameters makeHeaderParameters (ITree tree, ModuleName name,
						 ModuleParameters params,
						 Tags tags,
						 java.util.List < Import >
						 imports)
  {
    Header.Parameters x =
      new Header.Parameters (tree, name, params, tags,
			     params2expressions (java.util.List < Import >
						 imports));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Header.Ambiguity makeHeaderAmbiguity (java.util.List < Header >
					       alternatives)
  {
    Header.Ambiguity amb = new Header.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Header.Default makeHeaderDefault (ITree tree, ModuleName name,
					   Tags tags,
					   java.util.List < Import > imports)
  {
    Header.Default x =
      new Header.Default (tree, name, tags,
			  params2expressions (java.util.List < Import >
					      imports));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Name.Ambiguity makeNameAmbiguity (java.util.List < Name >
					   alternatives)
  {
    Name.Ambiguity amb = new Name.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public QualifiedName.Ambiguity makeQualifiedNameAmbiguity (java.util.List <
							     QualifiedName >
							     alternatives)
  {
    QualifiedName.Ambiguity amb = new QualifiedName.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public QualifiedName.Default makeQualifiedNameDefault (ITree tree,
							 java.util.List <
							 Name > names)
  {
    QualifiedName.Default x =
      new QualifiedName.Default (tree,
				 params2expressions (java.util.List < Name >
						     names));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Area.Ambiguity makeAreaAmbiguity (java.util.List < Area >
					   alternatives)
  {
    Area.Ambiguity amb = new Area.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Area.Default makeAreaDefault (ITree tree, Expression beginLine,
				       Expression beginColumn,
				       Expression endLine,
				       Expression endColumn,
				       Expression offset, Expression length)
  {
    Area.Default x =
      new Area.Default (tree, beginLine, beginColumn, endLine, endColumn,
			offset, length);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public TagString.Ambiguity makeTagStringAmbiguity (java.util.List <
						     TagString > alternatives)
  {
    TagString.Ambiguity amb = new TagString.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public TagChar.Ambiguity makeTagCharAmbiguity (java.util.List < TagChar >
						 alternatives)
  {
    TagChar.Ambiguity amb = new TagChar.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Tag.Ambiguity makeTagAmbiguity (java.util.List < Tag > alternatives)
  {
    Tag.Ambiguity amb = new Tag.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Tag.Default makeTagDefault (ITree tree, Name name)
  {
    Tag.Default x = new Tag.Default (tree, name);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Tags.Ambiguity makeTagsAmbiguity (java.util.List < Tags >
					   alternatives)
  {
    Tags.Ambiguity amb = new Tags.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Tags.Default makeTagsDefault (ITree tree,
				       java.util.List < Tag > annotations)
  {
    Tags.Default x =
      new Tags.Default (tree,
			params2expressions (java.util.List < Tag >
					    annotations));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public ValueProducer.
    GivenStrategy makeValueProducerGivenStrategy (ITree tree,
						  Strategy strategy,
						  Pattern pattern,
						  Expression expression)
  {
    ValueProducer.GivenStrategy x =
      new ValueProducer.GivenStrategy (tree, strategy, pattern, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public ValueProducer.Ambiguity makeValueProducerAmbiguity (java.util.List <
							     ValueProducer >
							     alternatives)
  {
    ValueProducer.Ambiguity amb = new ValueProducer.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public ValueProducer.
    DefaultStrategy makeValueProducerDefaultStrategy (ITree tree,
						      Pattern pattern,
						      Expression expression)
  {
    ValueProducer.DefaultStrategy x =
      new ValueProducer.DefaultStrategy (tree, pattern, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Generator.Producer makeGeneratorProducer (ITree tree,
						   ValueProducer producer)
  {
    Generator.Producer x = new Generator.Producer (tree, producer);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Generator.Ambiguity makeGeneratorAmbiguity (java.util.List <
						     Generator > alternatives)
  {
    Generator.Ambiguity amb = new Generator.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Generator.Expression makeGeneratorExpression (ITree tree,
						       Expression expression)
  {
    Generator.Expression x = new Generator.Expression (tree, expression);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Strategy.Innermost makeStrategyInnermost (ITree tree)
  {
    Strategy.Innermost x = new Strategy.Innermost (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Strategy.Outermost makeStrategyOutermost (ITree tree)
  {
    Strategy.Outermost x = new Strategy.Outermost (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Strategy.BottomUpBreak makeStrategyBottomUpBreak (ITree tree)
  {
    Strategy.BottomUpBreak x = new Strategy.BottomUpBreak (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Strategy.BottomUp makeStrategyBottomUp (ITree tree)
  {
    Strategy.BottomUp x = new Strategy.BottomUp (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Strategy.TopDownBreak makeStrategyTopDownBreak (ITree tree)
  {
    Strategy.TopDownBreak x = new Strategy.TopDownBreak (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Strategy.Ambiguity makeStrategyAmbiguity (java.util.List < Strategy >
						   alternatives)
  {
    Strategy.Ambiguity amb = new Strategy.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Strategy.TopDown makeStrategyTopDown (ITree tree)
  {
    Strategy.TopDown x = new Strategy.TopDown (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Comprehension.List makeComprehensionList (ITree tree,
						   Expression result,
						   java.util.List <
						   Generator > generators)
  {
    Comprehension.List x =
      new Comprehension.List (tree, result,
			      params2expressions (java.util.List < Generator >
						  generators));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Comprehension.Ambiguity makeComprehensionAmbiguity (java.util.List <
							     Comprehension >
							     alternatives)
  {
    Comprehension.Ambiguity amb = new Comprehension.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Comprehension.Set makeComprehensionSet (ITree tree,
						 Expression result,
						 java.util.List < Generator >
						 generators)
  {
    Comprehension.Set x =
      new Comprehension.Set (tree, result,
			     params2expressions (java.util.List < Generator >
						 generators));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Match.Arbitrary makeMatchArbitrary (ITree tree, Pattern match,
					     Statement statement)
  {
    Match.Arbitrary x = new Match.Arbitrary (tree, match, statement);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Match.Ambiguity makeMatchAmbiguity (java.util.List < Match >
					     alternatives)
  {
    Match.Ambiguity amb = new Match.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Match.Replacing makeMatchReplacing (ITree tree, Pattern match,
					     Expression replacement)
  {
    Match.Replacing x = new Match.Replacing (tree, match, replacement);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Rule.NoGuard makeRuleNoGuard (ITree tree, Match match)
  {
    Rule.NoGuard x = new Rule.NoGuard (tree, match);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Rule.Ambiguity makeRuleAmbiguity (java.util.List < Rule >
					   alternatives)
  {
    Rule.Ambiguity amb = new Rule.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Rule.WithGuard makeRuleWithGuard (ITree tree, Type type, Match match)
  {
    Rule.WithGuard x = new Rule.WithGuard (tree, type, match);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Case.Default makeCaseDefault (ITree tree, Statement statement)
  {
    Case.Default x = new Case.Default (tree, statement);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Case.Ambiguity makeCaseAmbiguity (java.util.List < Case >
					   alternatives)
  {
    Case.Ambiguity amb = new Case.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Case.Rule makeCaseRule (ITree tree, Rule rule)
  {
    Case.Rule x = new Case.Rule (tree, rule);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Visit.GivenStrategy makeVisitGivenStrategy (ITree tree,
						     Strategy strategy,
						     Expression subject,
						     java.util.List < Case >
						     cases)
  {
    Visit.GivenStrategy x =
      new Visit.GivenStrategy (tree, strategy, subject,
			       params2expressions (java.util.List < Case >
						   cases));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public Visit.Ambiguity makeVisitAmbiguity (java.util.List < Visit >
					     alternatives)
  {
    Visit.Ambiguity amb = new Visit.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public Visit.DefaultStrategy makeVisitDefaultStrategy (ITree tree,
							 Expression subject,
							 java.util.List <
							 Case > cases)
  {
    Visit.DefaultStrategy x =
      new Visit.DefaultStrategy (tree, subject,
				 params2expressions (java.util.List < Case >
						     cases));
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public UnicodeEscape.Ambiguity makeUnicodeEscapeAmbiguity (java.util.List <
							     UnicodeEscape >
							     alternatives)
  {
    UnicodeEscape.Ambiguity amb = new UnicodeEscape.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public DecimalIntegerLiteral.
    Ambiguity makeDecimalIntegerLiteralAmbiguity (java.util.List <
						  DecimalIntegerLiteral >
						  alternatives)
  {
    DecimalIntegerLiteral.Ambiguity amb =
      new DecimalIntegerLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public HexIntegerLiteral.Ambiguity makeHexIntegerLiteralAmbiguity (java.
								     util.
								     List <
								     HexIntegerLiteral
								     >
								     alternatives)
  {
    HexIntegerLiteral.Ambiguity amb =
      new HexIntegerLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public OctalIntegerLiteral.Ambiguity makeOctalIntegerLiteralAmbiguity (java.
									 util.
									 List
									 <
									 OctalIntegerLiteral
									 >
									 alternatives)
  {
    OctalIntegerLiteral.Ambiguity amb =
      new OctalIntegerLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public DecimalLongLiteral.Ambiguity makeDecimalLongLiteralAmbiguity (java.
								       util.
								       List <
								       DecimalLongLiteral
								       >
								       alternatives)
  {
    DecimalLongLiteral.Ambiguity amb =
      new DecimalLongLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public HexLongLiteral.Ambiguity makeHexLongLiteralAmbiguity (java.util.
							       List <
							       HexLongLiteral
							       > alternatives)
  {
    HexLongLiteral.Ambiguity amb =
      new HexLongLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public OctalLongLiteral.Ambiguity makeOctalLongLiteralAmbiguity (java.util.
								   List <
								   OctalLongLiteral
								   >
								   alternatives)
  {
    OctalLongLiteral.Ambiguity amb =
      new OctalLongLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public FloatingPointLiteral.
    Ambiguity makeFloatingPointLiteralAmbiguity (java.util.List <
						 FloatingPointLiteral >
						 alternatives)
  {
    FloatingPointLiteral.Ambiguity amb =
      new FloatingPointLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public DoubleLiteral.Ambiguity makeDoubleLiteralAmbiguity (java.util.List <
							     DoubleLiteral >
							     alternatives)
  {
    DoubleLiteral.Ambiguity amb = new DoubleLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public BooleanLiteral.Ambiguity makeBooleanLiteralAmbiguity (java.util.
							       List <
							       BooleanLiteral
							       > alternatives)
  {
    BooleanLiteral.Ambiguity amb =
      new BooleanLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public SingleCharacter.Ambiguity makeSingleCharacterAmbiguity (java.util.
								 List <
								 SingleCharacter
								 >
								 alternatives)
  {
    SingleCharacter.Ambiguity amb =
      new SingleCharacter.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public CharacterLiteral.Ambiguity makeCharacterLiteralAmbiguity (java.util.
								   List <
								   CharacterLiteral
								   >
								   alternatives)
  {
    CharacterLiteral.Ambiguity amb =
      new CharacterLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public EscapeSequence.Ambiguity makeEscapeSequenceAmbiguity (java.util.
							       List <
							       EscapeSequence
							       > alternatives)
  {
    EscapeSequence.Ambiguity amb =
      new EscapeSequence.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public StringCharacter.Ambiguity makeStringCharacterAmbiguity (java.util.
								 List <
								 StringCharacter
								 >
								 alternatives)
  {
    StringCharacter.Ambiguity amb =
      new StringCharacter.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public StringLiteral.Ambiguity makeStringLiteralAmbiguity (java.util.List <
							     StringLiteral >
							     alternatives)
  {
    StringLiteral.Ambiguity amb = new StringLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public IntegerLiteral.
    OctalIntegerLiteral makeIntegerLiteralOctalIntegerLiteral (ITree tree)
  {
    IntegerLiteral.OctalIntegerLiteral x =
      new IntegerLiteral.OctalIntegerLiteral (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public IntegerLiteral.
    HexIntegerLiteral makeIntegerLiteralHexIntegerLiteral (ITree tree)
  {
    IntegerLiteral.HexIntegerLiteral x =
      new IntegerLiteral.HexIntegerLiteral (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public IntegerLiteral.Ambiguity makeIntegerLiteralAmbiguity (java.util.
							       List <
							       IntegerLiteral
							       > alternatives)
  {
    IntegerLiteral.Ambiguity amb =
      new IntegerLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public IntegerLiteral.
    DecimalIntegerLiteral makeIntegerLiteralDecimalIntegerLiteral (ITree tree)
  {
    IntegerLiteral.DecimalIntegerLiteral x =
      new IntegerLiteral.DecimalIntegerLiteral (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public LongLiteral.
    OctalLongLiteral makeLongLiteralOctalLongLiteral (ITree tree)
  {
    LongLiteral.OctalLongLiteral x = new LongLiteral.OctalLongLiteral (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public LongLiteral.HexLongLiteral makeLongLiteralHexLongLiteral (ITree tree)
  {
    LongLiteral.HexLongLiteral x = new LongLiteral.HexLongLiteral (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
  public LongLiteral.Ambiguity makeLongLiteralAmbiguity (java.util.List <
							 LongLiteral >
							 alternatives)
  {
    LongLiteral.Ambiguity amb = new LongLiteral.Ambiguity (alternatives);
    if (!table.containsKey (amb))
      {
	table.put (amb, amb);
      }
    return table.get (amb, amb);
  }
  public LongLiteral.
    DecimalLongLiteral makeLongLiteralDecimalLongLiteral (ITree tree)
  {
    LongLiteral.DecimalLongLiteral x =
      new LongLiteral.DecimalLongLiteral (tree);
    if (!table.containsKey (x))
      {
	table.put (x, x);
      }
    return table.get (x);
  }
}
