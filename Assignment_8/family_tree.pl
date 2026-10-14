/*  family_tree.pl - Assignment 8: Family Tree in Prolog

    Load:   swipl family_tree.pl
    Demo:   ?- demo.

    The tree spans four generations:

        george + elizabeth
        |-- john   + karen   -> mary, james
        |                        mary + thomas -> lucas, sophia
        |-- linda  + paul    -> emma, noah
        |                        emma + daniel -> ava
        `-- robert + nancy   -> olivia
*/

:- discontiguous parent/2, male/1, female/1.

/* ------------------------------------------------------------------
   Facts: parent(Parent, Child), male(Person), female(Person)
   ------------------------------------------------------------------ */

% Generation 1
male(george).
female(elizabeth).

parent(george, john).
parent(george, linda).
parent(george, robert).
parent(elizabeth, john).
parent(elizabeth, linda).
parent(elizabeth, robert).

% Generation 2 and spouses
male(john).
female(karen).
female(linda).
male(paul).
male(robert).
female(nancy).

parent(john, mary).
parent(john, james).
parent(karen, mary).
parent(karen, james).

parent(linda, emma).
parent(linda, noah).
parent(paul, emma).
parent(paul, noah).

parent(robert, olivia).
parent(nancy, olivia).

% Generation 3 and spouses
female(mary).
male(james).
male(thomas).
female(emma).
male(noah).
male(daniel).
female(olivia).

parent(mary, lucas).
parent(mary, sophia).
parent(thomas, lucas).
parent(thomas, sophia).

parent(emma, ava).
parent(daniel, ava).

% Generation 4
male(lucas).
female(sophia).
female(ava).

/* ------------------------------------------------------------------
   Derived relationships
   ------------------------------------------------------------------ */

child(Child, Parent) :-
    parent(Parent, Child).

father(Father, Child) :-
    parent(Father, Child),
    male(Father).

mother(Mother, Child) :-
    parent(Mother, Child),
    female(Mother).

% ancestor_at(A, D, N): A is exactly N generations above D.
% Base case: one generation up is a parent. Recursive case: step down
% through a child and look for an ancestor N-1 generations above D.
ancestor_at(A, D, 1) :-
    parent(A, D).
ancestor_at(A, D, N) :-
    integer(N),
    N > 1,
    parent(A, Middle),
    N1 is N - 1,
    ancestor_at(Middle, D, N1).

% A grandparent is an ancestor exactly two generations up.
grandparent(X, Y) :-
    ancestor_at(X, Y, 2).

great_grandparent(X, Y) :-
    ancestor_at(X, Y, 3).

% X and Y share at least one parent and are different people.
% Siblings share two parents, so the raw conjunction would answer
% every pair twice; distinct/2 keeps each pair once.
sibling(X, Y) :-
    distinct(X-Y, ( parent(P, X), parent(P, Y), X \== Y )).

brother(X, Y) :-
    sibling(X, Y),
    male(X).

sister(X, Y) :-
    sibling(X, Y),
    female(X).

% X and Y are cousins when a parent of X is a sibling of a parent of Y.
cousin(X, Y) :-
    distinct(X-Y, ( parent(PX, X), parent(PY, Y), sibling(PX, PY) )).

% ancestor/2 is the transitive closure of parent/2. The non-recursive
% clause comes first and the recursive call comes after parent/2, so
% each step consumes one fact and the search always terminates.
ancestor(A, D) :-
    parent(A, D).
ancestor(A, D) :-
    parent(A, Middle),
    ancestor(Middle, D).

descendant(D, A) :-
    ancestor(A, D).

/* ------------------------------------------------------------------
   Query helpers: collect every answer into a sorted, duplicate-free
   list. findall/3 + sort/2 returns [] instead of failing when a
   person has no matches (setof/3 would fail).
   ------------------------------------------------------------------ */

children_of(Parent, Children) :-
    findall(C, parent(Parent, C), Cs),
    sort(Cs, Children).

siblings_of(Person, Siblings) :-
    findall(S, sibling(Person, S), Ss),
    sort(Ss, Siblings).

cousins_of(Person, Cousins) :-
    findall(C, cousin(Person, C), Cs),
    sort(Cs, Cousins).

grandchildren_of(Person, Grandchildren) :-
    findall(G, grandparent(Person, G), Gs),
    sort(Gs, Grandchildren).

great_grandchildren_of(Person, GreatGrandchildren) :-
    findall(G, great_grandparent(Person, G), Gs),
    sort(Gs, GreatGrandchildren).

ancestors_of(Person, Ancestors) :-
    findall(A, ancestor(A, Person), As),
    sort(As, Ancestors).

descendants_of(Person, Descendants) :-
    findall(D, descendant(D, Person), Ds),
    sort(Ds, Descendants).

/* ------------------------------------------------------------------
   demo/0: runs the sample queries listed in sample_queries.md and
   prints each answer the way the interactive top level would.
   ------------------------------------------------------------------ */

demo :-
    forall(demo_query(Label, Text), run_demo_query(Label, Text)).

run_demo_query(Label, Text) :-
    term_string(Goal, Text, [variable_names(Bindings)]),
    format("% ~w~n?- ~w.~n", [Label, Text]),
    (   call(Goal)
    ->  print_bindings(Bindings)
    ;   format("false.~n~n")
    ).

print_bindings([]) :-
    format("true.~n~n").
print_bindings([B|Bs]) :-
    forall(member(Name = Value, [B|Bs]),
           format("~w = ~q~n", [Name, Value])),
    nl.

demo_query('Children of john',                "children_of(john, Children)").
demo_query('Children of george',              "children_of(george, Children)").
demo_query('Children of olivia (none)',       "children_of(olivia, Children)").
demo_query('Mother of mary',                  "mother(M, mary)").
demo_query('Grandchildren of george',         "grandchildren_of(george, Grandchildren)").
demo_query('Is karen a grandparent of sophia?', "grandparent(karen, sophia)").
demo_query('Is george a grandparent of lucas?', "grandparent(george, lucas)").
demo_query('Great-grandchildren of george',   "great_grandchildren_of(george, L)").
demo_query('Siblings of linda',               "siblings_of(linda, Siblings)").
demo_query('Siblings of olivia (only child)', "siblings_of(olivia, Siblings)").
demo_query('Is mary a sister of james?',      "sister(mary, james)").
demo_query('Cousins of mary',                 "cousins_of(mary, Cousins)").
demo_query('Is emma a cousin of olivia?',     "cousin(emma, olivia)").
demo_query('Is mary a cousin of james?',      "cousin(mary, james)").
demo_query('Ancestors of sophia',             "ancestors_of(sophia, Ancestors)").
demo_query('Descendants of george',           "descendants_of(george, Descendants)").
demo_query('Descendants of linda',            "descendants_of(linda, Descendants)").
demo_query('Is ava a descendant of elizabeth?', "descendant(ava, elizabeth)").
