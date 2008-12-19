module Bool-rules

data Bool btrue;
data Bool bfalse;
data Bool band(Bool L, Bool R);
data Bool bor(Bool L, Bool R);  

rule a1 band(btrue, Bool B2)  => B2;
rule a2 band(bfalse, Bool B2) => bfalse;

rule o1 bor(btrue, btrue)     => btrue;
rule o2 bor(btrue, bfalse)    => btrue;
rule o3 bor(bfalse, btrue)    => btrue;
rule o4 bor(bfalse, bfalse)   => bfalse;