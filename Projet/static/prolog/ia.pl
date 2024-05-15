:- use_module(library(lists)).
:- use_module(library(random)).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                                IA                                     */
/*                                                                       */
/* --------------------------------------------------------------------- */

ia1(_, L, _, [Y, C]):-
    random_member(Y, L), 
    random_member(C, [0, 1, 2]).
    
ia1_chance(_, _, _, _, C):-
    random_member(C, [0, 1, 2]).
    
ia1_defausse(_, L, _, X):-
    random_member(X, L).