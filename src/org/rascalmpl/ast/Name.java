package org.rascalmpl.ast; 
import org.eclipse.imp.pdb.facts.INode; 
public abstract class Name extends AbstractAST { 
  static public class Lexical extends Name {
	private final String string;
         protected Lexical(INode node, String string) {
		this.node = node;
		this.string = string;
	}
	public String getString() {
		return string;
	}

 	public <T> T accept(IASTVisitor<T> v) {
     		return v.visitNameLexical(this);
  	}
} static public class Ambiguity extends Name {
  private final java.util.List<org.rascalmpl.ast.Name> alternatives;
  protected Ambiguity(INode node, java.util.List<org.rascalmpl.ast.Name> alternatives) {
	this.alternatives = java.util.Collections.unmodifiableList(alternatives);
         this.node = node;
  }
  public java.util.List<org.rascalmpl.ast.Name> getAlternatives() {
	return alternatives;
  }
  
  public <T> T accept(IASTVisitor<T> v) {
     return v.visitNameAmbiguity(this);
  }
} public abstract <T> T accept(IASTVisitor<T> visitor);
}