module Library


function main[1,1,args] { return next(init(create("TRUE"))); }

function TRUE[0,0,] { return true; }   // should be true
 
function FALSE[0,0,] { return false; }


function AND_U_U[2,2,lhs,rhs]{
  return prim("and_bool_bool", lhs, rhs);
}

function AND_M_U[2,2,lhs,rhs,clhs]{
   clhs = init(create(lhs));
   while(hasNext(clhs)){
     if(next(clhs)){
        if(rhs){
           yield 1;
        };
     };          
   };
   return 0;
}

function AND_U_M[2,2,lhs,rhs,crhs]{
   if(lhs){
      crhs = init(create(rhs));
      while(hasNext(crhs)){
        if(next(crhs)){
           yield 1;
        } else {
          return 0;
        };
      };         
   };
   return 0;
}

function AND_M_M[2,2,lhs,rhs,clhs,crhs]{
   clhs = init(create(lhs));
   while(hasNext(clhs)){
     if(next(clhs)){
        crhs = init(create(rhs));
        while(hasNext(crhs)){
          if(next(crhs)){
             yield 1;
          } else {
            return 0;
          };
        };       
     };          
   };
   return 0;
}

function ONE[1,1,arg, carg]{
   carg = init(create(arg));
   return next(arg);
}

function ALL[1,1,arg,carg]{
   carg = init(create(arg));
   while(hasNext(carg)){
        yield next(carg);
   };
   return false;
}        

// Pattern matching

function MATCH[1,3,pat,subject,cpat]{
   cpat = init(create(pat), subject);
   while(hasNext(cpat)){
      if(next(cpat)){
         yield true;
      } else {
        return false;
      };
   };
   return false;
}

function MATCH_INT[1,2,pat,subject]{
   return prim("equals_num_num", pat, subject);
}

function make_matcher[1,4,pats,n,subject,cursor]{
   return init(create(prim("subscript_list_int", pats, n)), subject, cursor);
}

function MATCH_LIST[1, 2, pat,subject,patlen,sublen,
						  p,cursor,forward,matcher,
						  matchers,pats,success,nextCursor]{

     patlen = prim("size_list", pats);
     sublen = prim("size_list", subject);
     p = 0; 
     cursor = 0;
     forward = true;
     matcher = make_matcher(pats, subject, cursor);
     matchers = prim("make_list", 0);
     while(true){
         while(hasNext(matcher)){
        	[success, nextCursor] = next(matcher,forward);
            if(success){
               forward = true;
               cursor = nextCursor;
               matchers = prim("addition_elm_list", matcher, matchers);
               p = prim("addition_num_num", p, 1);
               if(prim("and_bool_bool",
                       prim("equals_num_num", p, patlen),
                       prim("equals_num_num", cursor, sublen))) {
              	   yield true; 
               } else {
                   matcher = make_matcher(pats, p, subject, cursor);
               };    
            };
         };
         if(prim("greater_num_num", p, 0)){
               p = prim("subtraction_num_num", p, 1);
               matcher = prim("head_list", matchers);
               matchers = prim("tail_list", matchers);
               forward = false;
         } else {
               return false;
         };
     };
}

function MATCH_PAT_IN_LIST[1, 3, pat, subject, start,cpat]{
    cpat = init(create(pat), subject, start);
    /*
    while(hasNext(cpat)){
       if(next(cpat)){
          return [true, prim("addition_num_num", start, 1]>;
       };   
    };
    return <false, start>
  */  
} 
 
 /*
 coroutine MATCH_LIST_VAR (VAR) (subject, start){
    int pos = start;
    while(pos < size(subject)){
        VAR = subject[start .. pos];
        yield <true, pos>;
     }
     return <false, start>;
 }
*/