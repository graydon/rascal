package org.rascalmpl.library.experiments.Compiler.RVM.Interpreter.Instructions;

import org.rascalmpl.library.experiments.Compiler.RVM.Interpreter.CodeBlock;
import org.rascalmpl.library.experiments.Compiler.RVM.Interpreter.Generator;

public class CallConstr extends Instruction {
	
	final String fuid;
	final int arity;
	//final ISourceLocation src;
	
	public CallConstr(CodeBlock ins, String fuid, int arity/*, ISourceLocation src*/) {
		super(ins, Opcode.CALLCONSTR);
		this.fuid = fuid;
		this.arity = arity;
		//this.src = src;
	}
	
	public String toString() { return "CALLCONSTRUCTOR " + fuid + ", " + arity + " [ " + codeblock.getConstructorIndex(fuid) + " ]"; }
	
	public void generate(Generator codeEmittor, boolean dcode){
		codeEmittor.emitCall("insnCALLCONSTR", codeblock.getConstructorIndex(fuid), arity);
		codeblock.addCode2(opcode.getOpcode(), codeblock.getConstructorIndex(fuid), arity);
		//codeblock.addCode(codeblock.getConstantIndex(src));
	}

}
