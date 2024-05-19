:- use_module(library(lists)).
:- use_module(library(random)).


/* --------------------------------------------------------------------- */
/*                                                                       */
/*        PRODUIRE_REPONSE(L_Mots,L_Lignes_reponse) :                    */
/*                                                                       */
/*        Input : une liste de mots L_Mots representant la question      */
/*                de l'utilisateur                                       */
/*        Output : une liste de liste de mots correspondant a la         */
/*                 reponse fournie par le bot                            */
/*                                                                       */
/*        NB Pour l'instant le predicat retourne dans tous les cas       */
/*            [  [je, ne, sais, pas, '.'],                               */
/*               [les, etudiants, vont, m, '\'', aider, '.'],            */
/*               ['vous le verrez !']                                    */
/*            ]                                                          */
/*                                                                       */
/*        Je ne doute pas que ce sera le cas ! Et vous souhaite autant   */
/*        d'amusement a coder le predicat que j'ai eu a ecrire           */
/*        cet enonce et ce squelette de solution !                       */
/*                                                                       */
/*        J.-M. Jacquet, janvier 2022                                    */
/*                                                                       */
/* --------------------------------------------------------------------- */

/*                      !!!    A MODIFIER   !!!                          */

nb_coureurs(3).
nb_equipes(4).

% Règles de réponse
% regle_rep(+MotClé, +Motif, -Reponse)
% Associe un mot-clé à un motif et à une réponse correspondante.
regle_rep(commence, ['qui', 'commence', 'le', 'jeu'], rep_commence).
regle_rep(commence, ['qui', 'commence', 'la', 'partie'], rep_commence).
regle_rep(joueur, ['quel', 'joueur', 'commence'], rep_joueur).
regle_rep(equipe, ['combien', 'joueur', 'équipe'], rep_nb_joueur).
regle_rep(equipe, ['combien', 'équipe'], rep_nb_equipe).
regle_rep(equipe, ['bonjour'], rep_bonjour).
regle_rep(equipe, ['salut'], rep_bonjour).
regle_rep(equipe, ['hello'], rep_bonjour).


% Base case: The intersection of an empty list with any list is an empty list.
intersection([], _, []).

% Cas récursif : Si X est un membre de la deuxième liste, inclure X dans le résultat.
intersection([X|XS], YS, [X|ZS]) :-
    member(X, YS) ,
    intersection(XS, YS, ZS).

% Cas récursif : Si X n'est pas un membre de la deuxième liste, nous n'allons pas l'inclure X dans le résultat.
intersection([X|XS], YS, ZS) :-
    \+ member(X, YS),
    intersection(XS, YS, ZS).

%Liste de mot clé possible des question dans le jeu
liste_mot_cle([depasser,hello ,case,coureurs,combien,coureur,equipe,commence,qui,jeu,dessus,deplacer,occupee,autre, coureur,dessus,conseillez,carte, secondes,groupe,jouer,joue,italie,belgique,hollande,allemagne,couleur,maillot,bonjour,bonsoir,salut]).

select_answer(Mtrouve,Answer):- (member(qui,Mtrouve),member(commence,Mtrouve),Answer= ' C est au joueur ayant la plus haute carte secondes qui commence le jeu.';
member(equipe,Mtrouve),member(combien,Mtrouve),Answer= 'il y trois coureur dans chaque equipe';
member(depasser,Mtrouve),member(dessus,Mtrouve),Answer='oui, il est permis de doubler en bas de la route pour autant que le coureur arrive sur une place inoccupée. si ce n est pas le cas, le coureur tombe et entraîne avec lui le groupe de coureurs qu il voulait doubler.';
%Puis-je deplacer un coureur sur une case occupee par un autre coureur ?
member(deplacer,Mtrouve),member(coureur,Mtrouve),member(occupee,Mtrouve), Answer= 'Non il n est pas possible';
member(hello,Mtrouve), Answer= 'Bonjour ! Je suis le bot du Tour de France. Comment puis-je vous aider' ;
member(bonjour,Mtrouve), Answer= 'Bonjour ! Je suis le bot du Tour de France. Comment puis-je vous aider' ;
member(salut,Mtrouve), Answer= 'Bonjour ! Je suis le bot du Tour de France. Comment puis-je vous aider' ) .

produire_reponses(Mot,Answer) :- trouve_mot_cle(Mot,Mtrouve),select_answer(Mtrouve,Answer), !.


%trouver les mots clés du jeu
trouve_mot_cle(Mot,Mtrouve) :- liste_mot_cle(MotCle) , intersection(Mot,MotCle,Mtrouve).


%---------------------------------------------------------------------------------------------------------------------
%Logique utilisant la distance de levenshtein (donne mais prend enormement de temps pour trouver le cas qui nous intéresse quand la question est posé)
%---------------------------------------------------------------------------------------------------------------------
levenshtein_member([], _, _, []).
levenshtein_member([H1|T1], List2, MaxDist, [H2|T]) :-
    member(H2, List2),
    levenshtein_distance(H1, H2, D),
    D < MaxDist,
    levenshtein_member(T1, List2, MaxDist, T).

levenshtein_member([_|T1], List2, MaxDist, Result) :-
    levenshtein_member(T1, List2, MaxDist, Result).


levenshtein_distance(S1, S2, D) :-
    string_chars(S1, L1),
    string_chars(S2, L2),
    levenshtein(L1, L2, D).

% Levenshtein distance calculation with memoization
levenshtein([], [], 0).
levenshtein([], L, D) :-
    length(L, D).
levenshtein(L, [], D) :-
    length(L, D).

memo(a, b, c).

% Recursive case: calculate the minimum distance considering insertion, deletion, and substitution
levenshtein([H1|T1], [H2|T2], D) :-
    ( memo([H1|T1], [H2|T2], D) ->
        true
    ;   levenshtein(T1, [H2|T2], D1),
        levenshtein([H1|T1], T2, D2),
        levenshtein(T1, T2, D3),
        ( H1 == H2 -> Cost = 0 ; Cost = 1 ),
        D is min(D1 + 1, min(D2 + 1, D3 + Cost)),
        assertz(memo_levenshtein([H1|T1], [H2|T2], D))
    ).


% Helper predicate to find the minimum element in a list
min_list([L], L).
min_list([L|Ls], Min) :-
    min_list(Ls, MinTail),
    Min is min(L, MinTail).

% Finding the solution with the maximum number of elements
max_solution(Solutions, MaxSolution) :-
    maplist(length, Solutions, Lengths),
    max_list(Lengths, MaxLength),
    nth1(Index, Lengths, MaxLength),
    nth1(Index, Solutions, MaxSolution).


%--------------------------------------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------------------------------------


% Réponses correspondants aux règles
rep_bonjour('Bonjour ! Je suis le bot du Tour de France. Comment puis-je vous aider ?').
rep_commence('C\'est au joueur ayant la plus haute carte secondes de commencer.').
rep_joueur('Le joueur avec la plus haute carte secondes commence.').
rep_nb_joueur(Reponse) :-
    nb_coureurs(X),
    atomic_list_concat(['Il y a actuellement', X, 'coureurs dans chaque équipe.'], ' ', Reponse).
rep_nb_equipe(Reponse) :-
    nb_equipes(X),
    atomic_list_concat(['Il y a', X, 'equipes qui participent au tour de France.'], ' ', Reponse).

% On a pas de fonction delete donc on l'implémente ici
% delete(+Element, +Liste, -NouvelleListe)
% Supprime toutes les occurrences de l'élément
delete(X, [X|Tail], Tail).
delete(X, [Y|Tail], [Y|NewTail]) :-
    delete(X, Tail, NewTail).

% match_pattern(+Motif, +Question)
% Vérifie si le motif correspond à la question
match_pattern([], _).
match_pattern([Mot|Pattern], Question) :-
    member(Mot, Question),
    delete(Question, Mot, NewQuestion),
    match_pattern(Pattern, NewQuestion).

% Pareil que pour delete
% subset(+SousEnsemble, +Ensemble)
% Vérifie si la liste est un sous-ensemble
subset([], _).
subset([X|Xs], Y) :-
    member(X, Y),
    subset(Xs, Y).

% produire_reponse(+Question, -Reponse)
% Produit une réponse en fonction de la question
produire_reponse(Question, 'Merci de m\'avoir consulté.') :-
   member(Question, [['fin']]), !.

produire_reponse(Question, Reponse) :-
    trouve_mot_cle(Question,Mtrouve),
    select_answer(Mtrouve,Reponse), !.
    % regle_rep(Mot, Pattern, Rep),
    % subset(Pattern, Question),
    % call(Rep, Reponse), !.

produire_reponse(_, Reponse):-
   random_member(Reponse, ['Je n\'ai pas compris la question. Pourriez-vous reformuler ?', 'Je ne sais pas, désolé.', 'Pourriez-vous reformuler la question ?']).

lower_string([], []).
lower_string([String|Strings], [LString|LStrings]):-
   downcase_atom(String, LString),
   lower_string(Strings, LStrings).
    
/* --------------------------------------------------------------------- */
/*                                                                       */
/*                         PREDICAT PRINCIPAL                            */
/*                                                                       */
/* --------------------------------------------------------------------- */

tour2france(L_Mots, ReponseString) :-
   lower_string(L_Mots, L_Mots_Lower),
   produire_reponse(L_Mots_Lower,ReponseString).

    