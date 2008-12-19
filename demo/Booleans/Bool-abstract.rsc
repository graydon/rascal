module Bool-abstract

data Bool btrue;
data Bool bfalse;
data Bool band(Bool L, Bool R);
data Bool bor(Bool L, Bool R);  

Bool reduce(Bool B) {
    Bool B1, B2;
    return bottom-up visit(B) {
      case band(btrue, B2)      => B2     // Use Variables
      case band(bfalse, B2)     => bfalse
      case bor(btrue, btrue)    => btrue  // Use a truth table
      case bor(btrue, bfalse)   => btrue
      case bor(bfalse, btrue)   => btrue
      case bor(bfalse, bfalse)  => bfalse
    };
}