package org.meta_environment.rascal.ast;
import org.eclipse.imp.pdb.facts.ITree;
import java.util.Collections;
public abstract class Match extends AbstractAST
{
  public class Replacing extends Match
  {
/* match:Pattern "=>" replacement:Expression -> Match {cons("Replacing")} */
    private Replacing ()
    {
    }
    /*package */ Replacing (ITree tree, Pattern match, Expression replacement)
    {
      this.tree = tree;
      this.match = match;
      this.replacement = replacement;
    }
    public IVisitable accept (IASTVisitor visitor)
    {
      return visitor.visitMatchReplacing (this);
    }
    private Pattern match;
    public Pattern getMatch ()
    {
      return match;
    }
    private void $setMatch (Pattern x)
    {
      this.match = x;
    }
    public Replacing setMatch (Pattern x)
    {
      Replacing z = new Replacing ();
      z.$setMatch (x);
      return z;
    }
    private Expression replacement;
    public Expression getReplacement ()
    {
      return replacement;
    }
    private void $setReplacement (Expression x)
    {
      this.replacement = x;
    }
    public Replacing setReplacement (Expression x)
    {
      Replacing z = new Replacing ();
      z.$setReplacement (x);
      return z;
    }
  }
  public class Ambiguity extends Match
  {
    private final java.util.List < Match > alternatives;
    public Ambiguity (java.util.List < Match > alternatives)
    {
      this.alternatives = Collections.unmodifiableList (alternatives);
    }
    public java.util.List < Match > getAlternatives ()
    {
      return alternatives;
    }
  }
  public class Arbitrary extends Match
  {
/* match:Pattern ":" statement:Statement -> Match {cons("Arbitrary")} */
    private Arbitrary ()
    {
    }
    /*package */ Arbitrary (ITree tree, Pattern match, Statement statement)
    {
      this.tree = tree;
      this.match = match;
      this.statement = statement;
    }
    public IVisitable accept (IASTVisitor visitor)
    {
      return visitor.visitMatchArbitrary (this);
    }
    private Pattern match;
    public Pattern getMatch ()
    {
      return match;
    }
    private void $setMatch (Pattern x)
    {
      this.match = x;
    }
    public Arbitrary setMatch (Pattern x)
    {
      Arbitrary z = new Arbitrary ();
      z.$setMatch (x);
      return z;
    }
    private Statement statement;
    public Statement getStatement ()
    {
      return statement;
    }
    private void $setStatement (Statement x)
    {
      this.statement = x;
    }
    public Arbitrary setStatement (Statement x)
    {
      Arbitrary z = new Arbitrary ();
      z.$setStatement (x);
      return z;
    }
  }
}
