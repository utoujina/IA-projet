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
regle_rep(commence, ["qui", "commence", "le", "jeu"], rep_commence).
regle_rep(joueur, ["quel", "joueur", "commence"], rep_joueur).
regle_rep(equipe, ["combien", "joueur", "equipe"], rep_nb_joueur).
regle_rep(equipe, ["bonjour"], rep_bonjour).
regle_rep(equipe, ["salut"], rep_bonjour).
regle_rep(equipe, ["hello"], rep_bonjour).
regle_rep(equipe, ["Bonjour"], rep_bonjour).
regle_rep(equipe, ["Salut"], rep_bonjour).
regle_rep(equipe, ["Hello"], rep_bonjour).

% Réponses correspondants aux règles
rep_bonjour('Bonjour ! Je suis le bot du Tour de France. Comment puis-je vous aider ?').
rep_commence('C\'est au joueur ayant la plus haute carte secondes de commencer.').
rep_joueur('Le joueur avec la plus haute carte secondes commence.').
rep_nb_joueur(Reponse) :-
    nb_coureurs(X),
    atomic_list_concat(['Il y a actuellement', X, 'coureurs dans chaque équipe.'], ' ', Reponse).

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
   member(Question, [["fin"], ["Fin"]]), !.
    
produire_reponse(Question, Reponse) :-
    regle_rep(Mot, Pattern, Rep),
    subset(Pattern, Question), 
    call(Rep, Reponse), !.

produire_reponse(_, Reponse):-
   random_member(Reponse, ['Je n\'ai pas compris la question. Pourriez-vous reformuler ?', 'Je ne sais pas, désolé.', 'Pourriez-vous reformuler de manière différente ?.']).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                         PREDICAT PRINCIPAL                            */
/*                                                                       */
/* --------------------------------------------------------------------- */

tour2france(L_Mots, ReponseString) :- 
   produire_reponse(L_Mots,ReponseString).
