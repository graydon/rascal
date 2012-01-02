@license{
  Copyright (c) 2009-2011 CWI
  All rights reserved. This program and the accompanying materials
  are made available under the terms of the Eclipse Public License v1.0
  which accompanies this distribution, and is available at
  http://www.eclipse.org/legal/epl-v10.html
}
@contributor{Jurgen J. Vinju - Jurgen.Vinju@cwi.nl - CWI}
@contributor{Tijs van der Storm - Tijs.van.der.Storm@cwi.nl}
module Set
import List;
import Math;
@doc{
Synopsis: Classify elements in a set.

Examples:
We classify animals by their number of legs.
<screen>
import Set;
// Create a map from animals to number of legs.
legs = ("bird": 2, "dog": 4, "human": 2, "snake": 0, "spider": 8, "millepede": 1000, "crab": 8, "cat": 4);
// Define function `nLegs` that returns the number of legs fro each animal (or `0` when the animal is unknown):
int nLegs(str animal){
    return legs[animal] ? 0;
}
// Now classify a set of animals:
classify({"bird", "dog", "human", "spider", "millepede", "zebra", "crab", "cat"}, nLegs);
</screen>
}
public map[&K,set[&V]] classify(set[&V] input, &K (&V) getClass) {
  set[set[&V]] grouped = 
     group(input,bool (&V a,&V b) { return getClass(a) == getClass(b); });
  return ( getClass(getOneFrom(s)) : s | s <- grouped);
}

@doc{
Synopsis: Pick a random element from a set.

Description: Also see [$Set/takeOneFrom].

Examples:
<screen>
import Set;
getOneFrom({1,2,3,4});
getOneFrom({1,2,3,4});
getOneFrom({1,2,3,4});
getOneFrom({1,2,3,4});
</screen>
}
@javaClass{org.rascalmpl.library.Set}
public java &T getOneFrom(set[&T] st) throws EmptySet;


@doc{
Synopsis: Group elements in a set given an equivalence function.

Examples:
We classify animals by their number of legs.
<screen>
import Set;
// Create a map from animals to number of legs.
legs = ("bird": 2, "dog": 4, "human": 2, "snake": 0, "spider": 8, "millepede": 1000, "crab": 8, "cat": 4);
// Define function `nLegs` that returns the number of legs fro each animal (or `0` when the animal is unknown):
int nLegs(str animal){
    return legs[animal] ? 0;
}
bool similar(str a, str b) = nLegs(a) == nLegs(b);
// Now group a set of animals:
group({"bird", "dog", "human", "spider", "millepede", "zebra", "crab", "cat"}, similar);
</screen>
}
public set[set[&T]] group(set[&T] input, bool (&T a, &T b) similar) {
  sinput = sort(toList(input), bool (&T a, &T b) { return similar(a,b) ? a < b ; } );
  lres = while (!isEmpty(sinput)) {
    h = head(sinput);
    sim = h + 
    takeWhile(tail(sinput),
      bool (&T a) { return similar(a,h); });
	  append toSet(sim);
	  sinput = drop(size(sim),sinput);
  }
  return toSet(lres); 
}


@doc{
Synopsis: Map set elements to a fixed index.

Examples:
<screen>
import Set;
index({"elephant", "zebra", "snake"});
</screen>
}
public map[&T,int] index(set[&T] s) {
  sl = toList(s);
  return (sl[i] : i | i <- index(sl));
}





@doc{
Synopsis: Test whether a set is empty.

Description:
Yields `true` if `s` is empty, and `false` otherwise.

Examples:
<screen>
import Set;
isEmpty({1, 2, 3});
isEmpty({});
</screen>
}
@javaClass{org.rascalmpl.library.Set}
public java bool isEmpty(set[&T] st);

@doc{
Synopsis: Apply a function to all set elements and return set of results.

Description:
Return a set obtained by applying function `fn` to all elements of set `s`.

Examples:
<screen>
import Set;
int incr(int x) { return x + 1; }
mapper({1, 2, 3, 4}, incr);
</screen>
}
public set[&U] mapper(set[&T] st, &U (&T) fn)
{
  return {fn(elm) | &T elm <- st};
}

@doc{
Synopsis: Determine the largest element of a set.

Examples:
<screen>
import Set;
max({1, 3, 5, 2, 4});
max({"elephant", "zebra", "snake"});
</screen>
}
public &T max(set[&T] st) {
	<h,t> = takeOneFrom(st);
	return (h | e > it ? e : it | e <- t);
}

@doc{
Synopsis: Smallest element of a set.

Examples:
<screen>
import Set;
min({1, 3, 5, 2, 4});
min({"elephant", "zebra", "snake"});
</screen>
}
@doc{
Synopsis: Determine the smallest element of a set.

Examples:
<screen>
import Set;
min({1, 3, 5, 4, 2});
</screen>
}
public &T min(set[&T] st) {
	<h,t> = takeOneFrom(st);
	return (h | e < it ? e : it | e <- t);
}

@doc{
Synopsis: Determine the powerset of a set.

Description:
Returns a set with all subsets of `s`.

Examples:
<screen>
import Set;
power({1,2,3,4});
</screen>
}
public set[set[&T]] power(set[&T] st)
{
  // the power set of a set of size n has 2^n-1 elements 
  // so we enumerate the numbers 0..2^n-1
  // if the nth bit of a number i is 1 then
  // the nth element of the set should be in the
  // ith subset 
  stl = toList(st);
  i = 0;
  res = while(i < pow(2,size(st))) {
	j = i;
	elIndex = 0;
	sub = while(j > 0) {;
	  if(j mod 2 == 1) {
		append stl[elIndex];
	  }
	  elIndex += 1;
	  j /= 2;
	}
	append toSet(sub);
	i+=1;
  }
  return toSet(res);
}

@doc{
Synopsis: The powerset (excluding the empty set) of a set value.

Description:
Returns all subsets (excluding the empty set) of `s`.

Examples:
<screen>
import Set;
power1({1,2,3,4});
</screen>
}
public set[set[&T]] power1(set[&T] st) = power(st) - {{}};

@doc{
Synopsis: Apply a function to successive elements of a set and combine the results (__deprecated__).

Description:
Apply the function `fn` to successive elements of set `s` starting with `unit`.

Examples:
<screen>
import Set;
int add(int x, int y) { return x + y; }
reducer({10, 20, 30, 40}, add, 0); 
</screen>

Pitfalls:
This function is __deprecated__, use a [$Expressions/Reducer] instead.
}
public &T reducer(set[&T] st, &T (&T,&T) fn, &T unit) =
	(unit | fn(it,elm) | elm <- st);

@doc{
Synopsis:  Determine the number of elements in a set.

Examples:
<screen>
import Set;
size({1,2,3,4});
size({"elephant", "zebra", "snake"});
size({});
</screen>

Questions:
QValue:
prep: import Set;
make: N = int[0,5]
hint: <N> values separated by commas
test: size({ <?> }) == <N>
}
@javaClass{org.rascalmpl.library.Set}
public java int size(set[&T] st);

@doc{
Synopsis: Pick an arbitrary element from a set, returns the element and the set without the selected element.

Description: Also see [$Set/getOneFrom].

Examples:

<screen>
import Set;
getOneFrom({"elephant", "zebra", "snake"});
getOneFrom({"elephant", "zebra", "snake"});
getOneFrom({"elephant", "zebra", "snake"});
getOneFrom({"elephant", "zebra", "snake"});
</screen>
}
@doc{
Synopsis:  Remove an arbitrary element from a set, returns the element and a set without that element.

Description:
Remove an arbitrary element from set `s` and return a tuple consisting of the element and a set without that element.

Examples:
<screen>
import Set;
takeOneFrom({1, 2, 3, 4});
takeOneFrom({1, 2, 3, 4});
takeOneFrom({1, 2, 3, 4});
</screen>
}
@javaClass{org.rascalmpl.library.Set}
public java tuple[&T, set[&T]] takeOneFrom(set[&T] st) throws EmptySet;
  
@doc{
Synopsis: Convert a set to a list.

Examples:
<screen>
import Set;
toList({1, 2, 3, 4});
toList({"elephant", "zebra", "snake"});
</screen>

Pitfalls:
Recall that the elements of a set are unordered and that there is no guarantee in which order the set elements will be placed in the resulting list.
}
@javaClass{org.rascalmpl.library.Set}
public java list[&T] toList(set[&T] st);

@doc{
Synopsis: Convert a set of tuples to a map; each key is associated with a set of values.

Description:
Convert a set of tuples to a map in which the first element of each tuple 
is associated with the set of second elements of all tuples with the same first element.

Examples:
<screen>
import Set;
toMap({<"a", 1>, <"b", 2>, <"a", 10>});
</screen>
}
@javaClass{org.rascalmpl.library.Set}
public java map[&A,set[&B]] toMap(rel[&A, &B] st);

@doc{
Synopsis: Convert a set of tuples to a map (provided that there are no multiple keys).

Description:
Convert a set of tuples to a map. The result should be a legal map (i.e., without multiple keys).

Examples:
<screen errors>
import Set;
toMapUnique({<"a", 1>, <"b", 2>, <"c", 10>});
// Now explore an erroneous example:
toMapUnique({<"a", 1>, <"b", 2>, <"a", 10>});
</screen>
}
@javaClass{org.rascalmpl.library.Set}
public java map[&A,&B] toMapUnique(rel[&A, &B] st) throws MultipleKey;

@doc{
Synopsis: Convert a set to a string.

Examples:
<screen>
import Set;
toString({1, 2, 3});
toString({"elephant", "zebra", "snake"});
</screen>

Pitfalls:
Recall that the elements of a set are unordered and that there is no guarantee in which order the set elements will be placed in the resulting string.
}
@javaClass{org.rascalmpl.library.Set}
public java str toString(set[&T] st);

