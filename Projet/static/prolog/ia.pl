:- use_module(library(lists)).
:- use_module(library(random)).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                              IA naïve                                 */
/*                                                                       */
/* --------------------------------------------------------------------- */

ia_naive(_, L, _, [Y, C]):-
    random_member(Y, L), 
    random_member(C, [0, 1, 2]).
    
ia_naive_chance(_, _, _, _, C):-
    random_member(C, [0, 1, 2]).
    
ia_naive_defausse(_, L, _, X):-
    random_member(X, L).
    
/* --------------------------------------------------------------------- */
/*                                                                       */
/*                      IA chance + défausse                             */
/*                                                                       */
/* --------------------------------------------------------------------- */
% Défausse toujours la plus petite carte
ia1_defausse(Cards, Choice):-
    min_list(Cards, Choice).
    
% Choisit le mouvement grace à l'heuristique de mouvement
ia1_chance([Team, ID], Current_pos, Players, Cards, Card_chance, C) :-
    Case is Current_pos + Card_chance,
    heu_deplacement_1(Team, ID, [Case, 0], Card_chance, Players, Cards, Score1),
    heu_deplacement_1(Team, ID, [Case, 1], Card_chance, Players, Cards, Score2),
    heu_deplacement_1(Team, ID, [Case, 2], Card_chance, Players, Cards, Score3),
    compare_score(Score1, Score2, Score3, C).
    
ia2_chance([Team, ID], Current_pos, Players, Cards, Card_chance, C) :-
    Case is Current_pos + Card_chance,
    heu_deplacement_2(Team, ID, [Case, 0], Card_chance, Players, Cards, Score1),
    heu_deplacement_2(Team, ID, [Case, 1], Card_chance, Players, Cards, Score2),
    heu_deplacement_2(Team, ID, [Case, 2], Card_chance, Players, Cards, Score3),
    compare_score(Score1, Score2, Score3, C).

% Comparaison des scores
compare_score(Score1, Score2, Score3, 0) :-
    Score1 >= Score2,
    Score1 >= Score3.

compare_score(Score1, Score2, Score3, 1) :-
    Score2 >= Score1,
    Score2 >= Score3.
    
compare_score(Score1, Score2, Score3, 2) :-
    Score3 >= Score1,
    Score3 >= Score2.
    
/* --------------------------------------------------------------------- */
/*                                                                       */
/*                        Base de connaissance                           */
/*                                                                       */
/* --------------------------------------------------------------------- */
case_chance(X):-
    L = [[9, 0], [10,0], [11,0], [12,0], [15,2], [16,2], [19,2], [21,2], [24,0], [26,0], [28,0], [30,0], [32,0], [34,0], [48,0], [57,2], [66,0], [66,2], [74,0]],
    member(X, L).
    
case_valide([Case, Couloir]) :-
    member(Couloir, [0, 1, 2]),
    Case >= 1,
    (Case =< 10 ;       
    Case >= 19, Case =< 35 ;
    Case >= 95, Case =< 105).

case_valide([Case, Couloir]) :-
    member(Couloir, [0, 2]),
    Case >= 11,
    (Case =< 18 ;       
    Case >= 36, Case =< 72 ;
    Case >= 76, Case =< 94).

case_valide([Case, 0]) :-
    Case >= 73,
    Case =< 75.

    
/* --------------------------------------------------------------------- */
/*                                                                       */
/*                        Etat et transitions                            */
/*                                                                       */
/* --------------------------------------------------------------------- */
% Un état c'est :
% [current_player, cards, players]
% Avec :
% current_player: [nb_case, couloir]
% players: list[rank, team, ID, nb_case, couloir]

% Fonction de transition
% IN : 
%   case actuelle
%   liste de carte possible
% OUT:
%   liste de case atteignable [case, couloir, carte]
transition_bis([Case, Couloir], Cards, Transitions) :-
    findall([NewCase, NewCouloir, Card], (
        member(Card, Cards),
        member(NewCouloir, [0, 1, 2]),
        NewCase is Case + Card,
        case_valide([NewCase, NewCouloir])
    ), Transitions).
    
transition([Case, Couloir], Cards, [NewCase, NewCouloir, Card]) :-
    member(Card, Cards),
    member(NewCouloir, [0, 1, 2]),
    NewCase is Case + Card,
    case_valide([NewCase, NewCouloir]).
    
% Transition de joueur
% next_player(Current_player, Running_ordder, New_player)

next_player(Current_player, [Current_player, New_player|_], New_player).

next_player(Current_player, [Player|Ps], New_player):-
    Current_player \= Player,
    next_player(Current_player, Ps, New_player).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                    Heuristique d'évaluation                           */
/*                                                                       */
/* --------------------------------------------------------------------- */

heu_eval(Players, Team, Value):-
    heu_eval_sub(Team, Players, Value).

heu_eval_sub(_, [], 0).

heu_eval_sub(Team, [[Rank, Team, _, _, _]|Players], Result) :-
    heu_eval_sub(Team, Players, Result2),
    Result is Rank + Result2.
    
heu_eval_sub(Team, [[_, Team2, _, _, _]|Players], Result) :-
    Team \= Team2,
    heu_eval_sub(Team, Players, Result).
    
/* --------------------------------------------------------------------- */
/*                                                                       */
/*                  Heuristique de déplacement                           */
/*                                                                       */
/* --------------------------------------------------------------------- */

% Heuristique de chance
heu_chance(Case, 10):-
    case_chance(Case).
heu_chance(_, 0).
    
% Heuristique de chute
heu_chute(Case, Players, -40) :-
    member([_, _, _, X, Y], Players),
    [X, Y] = Case.
heu_chute(_, _, 10).

% Prédicat pour extraire les joueurs d'une équipe
extract_players(_, [], []).
extract_players(Team, [[R, Team, ID, X, Y]|Ps], [[R, Team, ID, X, Y]|Players_of_team]) :-
    extract_players(Team, Ps, Players_of_team).
extract_players(Team, [[_, OtherTeam, _, _, _]|Ps], Players_of_team) :-
    Team \= OtherTeam,
    extract_players(Team, Ps, Players_of_team).
    
% Predicat qui vérifie la carte donnée au joueur
check_player(ID, Card, [[_, _, ID, _, _]|_], [Card|_]).
check_player(ID1, C, [[_, _, ID2, _, _]|Ps], [Card|Cards]) :-
    ID1 \= ID2,
    check_player(ID1, C, Ps, Cards).

% Heuristique stratégie 1
% La carte jouée est la plus grande pour le PREMIER joueur
heu_max_card_first_player(Team, ID, Card, Cards, Players, 10):-
    % Triage des cartes
    msort(Cards, Cards_sorted),
    reverse(Cards_sorted, Cards_sorted_reverse),
    % Extraction des joueurs de l'équipe
    extract_players(Team, Players, Team_players),
    % Verifie si la bonne carte est attribué au bon coureur
    check_player(ID, Card, Team_players, Cards_sorted_reverse).
heu_max_card_first_player(_, _, _, _, _, 0).

% Heuristique stratégie 2
% La carte jouée est la plus grande pour le DERNIER joueur
heu_max_card_last_player(Team, ID, Card, Cards, Players, 10):-
    % Triage des cartes
    msort(Cards, Cards_sorted),
    reverse(Cards_sorted, Cards_sorted_reverse),
    % Extraction des joueurs de l'équipe
    extract_players(Team, Players, Team_players),
    reverse(Team_players, Team_players_reversed),
    % Verifie si la bonne carte est attribué au bon coureur
    check_player(ID, Card, Team_players_reversed, Cards_sorted_reverse).
heu_max_card_last_player(_, _, _, _, _, 0).

% HEURISTIQUE DE DEPLACEMENT 1
% La carte jouée est la plus grande pour le PREMIER joueur
% Position de la case d'arrivée en appliquant Card
heu_deplacement_1(Team, ID, [Case, Couloir], Card, Players, Cards, Score):-
    heu_chance([Case, Couloir], Chance),
    heu_chute([Case, Couloir], Players, Chute),
    heu_max_card_first_player(Team, ID, Card, Cards, Players, Strat),
    
    Score is Chute + Chance + Strat + Card.
    
% HEURISTIQUE DE DEPLACEMENT 2
% La carte jouée est la plus grande pour le DERNIER joueur
% Position de la case d'arrivée en appliquant Card
heu_deplacement_2(Team, ID, [Case, Couloir], Card, Players, Cards, Score):-
    heu_chance([Case, Couloir], Chance),
    heu_chute([Case, Couloir], Players, Chute),
    heu_max_card_last_player(Team, ID, Card, Cards, Players, Strat),
    
    Score is Chute + Chance + Strat + Card.
    

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                              Algo Max^n                               */
/*         Chaque joueur maximise le résulat de son heuristique          */
/*                                                                       */
/* --------------------------------------------------------------------- */

% Split un string en 2
% split_string_custom(String, Separator, Left, Right)
split_string_custom(String, Separator, L, R) :-
    atom_chars(String, Chars),
    append(LeftChars, [Separator | RightChars], Chars),
    atom_chars(L, LeftChars),
    atom_chars(R, RightChars).

% Détermine le prochain joueur
% next_player(Running_order, Current_player, New_player)
% Ex Running_order : ['ITA 1', 'ITA 2', 'ITA 3', 'BEL 1', 'BEL 2', 'BEL 3', 'DEU 1', 'DEU 2', 'DEU 3', 'NLD 1', 'NLD 2', 'NLD 3']
next_team([P1, P2|Ps], [Team1, ID1], [Team2, ID2]) :-
    split_string_custom(P1, ' ', Team1, ID1),
    split_string_custom(P2, ' ', Team2, ID2).
    
next_team([P1|Ps], [Team2, ID2], Next_player) :-
    split_string_custom(P1, ' ', Team1, ID1),
    Team1 \= Team2,
    ID1 \= ID2,
    next_team(Ps, [Team2, ID2], Next_player).

% Extrait les cartes de l'équipe
% extract_cards(Team, Cards, Team_cards)
extract_cards('BEL', [BEL, DEU, NLD, ITA], BEL).
extract_cards('DEU', [BEL, DEU, NLD, ITA], DEU).
extract_cards('NLD', [BEL, DEU, NLD, ITA], NLD).
extract_cards('ITA', [BEL, DEU, NLD, ITA], ITA).

% apply_move(Move, [Team, ID], Players, New_players)
% Modifie la variable players en appliquant le move passé en paramètre
apply_move(_, _, [], []).

apply_move(Move, [Team, ID], [[Rank, Team, IDP, X, Y]|Ps], [[Rank, Team, IDP, X, Y]|New_players]) :-
    ID \= IDP,
    apply_move(Move, [Team, ID], Ps, New_players).

apply_move(Move, [Team, ID], [[Rank, TeamP, IDP, X, Y]|Ps], [[Rank, TeamP, IDP, X, Y]|New_players]) :-
    Team \= TeamP,
    apply_move(Move, [Team, ID], Ps, New_players).

apply_move([Case, Couloir, Card], [Team, ID], [[Rank, Team, ID, X, Y]|Ps], [[Rank, Team, ID, Case, Couloir]|Ps]).
    
% Get the position of the player          
% get_pos(Players, [Team, ID], [Case, Couloir])

get_pos([[_, Team, ID, X, Y]|_], [Team, ID], [X, Y]).

get_pos([[_, Team1, ID1, _, _]|Ps], [Team, ID], Pos) :-
    Team1 \= Team,
    get_pos(Ps, [Team, ID], Pos).

get_pos([[_, Team, ID1, _, _]|Ps], [Team, ID], Pos) :-
    ID1 \= ID,
    get_pos(Ps, [Team, ID], Pos).
    
% Minimum
minimum(X, Y, X) :-
    nonvar(X),
    (   nonvar(Y), X =< Y
    ;   var(Y)
    ).
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Max_n %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

max_n([Players, Cards, Running_order], 0, [Team, ID], Current_pos, EvalSoFar, Value, Choice) :-
    heu_eval(Players, Team, Value).

max_n([Players, Cards, []], _, _, _, _, _, _).

max_n([Players, Cards, Running_order], Depth, [Team, ID], Current_pos, EvalSoFar, Value, Choice) :-
    Depth > 0,
    extract_cards(Team, Cards, Team_cards),
    findall([New_case, New_couloir, Card],
            (transition(Current_pos, Team_cards, [New_case, New_couloir, Card]),
             heu_deplacement_1(Team, ID, [New_case, New_couloir], Card, Players, Team_cards, Score),
             Score > 10),
            Possibilities),
    sort(Possibilities, Possibilities_sorted), % On élimine les doublons
    evaluate_move(Possibilities_sorted, Depth, Team_cards, [Team, ID], Current_pos, [Players, Cards, Running_order], EvalSoFar, BestEval, BestChoice),
    Value is BestEval,
    Choice = BestChoice.

% On a exploré tous les mouvements possibles
evaluate_move([], _, _, _, _, _, EvalSoFar, EvalSoFar, _).

% On évalue le mouvement
evaluate_move([[Case, Couloir, Card] | Possibilities], Depth, Team_cards, Player, Current_pos, [Players, Cards, Running_order], EvalSoFar, BestEval, BestChoice) :-
    Depth > 0,
    Depth_Next is Depth - 1,
    
    apply_move([Case, Couloir, Card], Player, Players, New_players), % On met a jour Players avec le nouveau move
    next_team(Running_order, Player, New_player), % On passe au joueur suivant
    get_pos(Players, Player, Pos_new_player),  % On prend la position actuelle du joueur suivant
    
    max_n([New_players, Cards, Running_order], Depth_Next, New_player, Pos_new_player, _, Eval, [Case, Couloir, Card]), 
    
    % min_score(Team, EvalSoFar, Eval, NewEvalSoFar),
    minimum(Eval, EvalSoFar, NewEvalSoFar),
    evaluate_move(Possibilities, Depth, Team_cards, Player, Current_pos, [Players, Cards, Running_order], NewEvalSoFar, BestEval, [Case, Couloir, Card]).

    

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                                IA                                     */
/*                                                                       */
/* --------------------------------------------------------------------- */
        
% cas de base
best_possibily(_, _, [], Score, Score, BestPossibility, BestPossibility).

% Evaluation de chaque possibilité
best_possibily([Players, Team_cards], [Team, ID], [[Case, Couloir, Card]|Ps], ScoreSoFar, BestScore, BestPossibilitySoFar, BestPossibility) :-
    apply_move([Case, Couloir, Card], [Team, ID], Players, New_players),
    heu_eval(New_players, Team, Value),
    
    % Maj des score et du move
    (   Value < ScoreSoFar 
    ->  NewScore = Value,
        NewBestPossibility = [Couloir, Card]
    ;   NewScore = ScoreSoFar,
        NewBestPossibility = BestPossibilitySoFar
    ),
    
    % Appel récursif
    best_possibily([Players, Team_cards], [Team, ID], Ps, NewScore, BestScore, NewBestPossibility, BestPossibility).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                               Appel IA                                */
/*                                                                       */
/* --------------------------------------------------------------------- */

% Appel de l'IA 1
% On utilise l'heuristique d'évaluation de déplacement 1

% Cas ou il ne reste qu'une carte dans le paquet du joueur
% On fait comme pour une case chance -> choisir le couloir
ia1([Players, [Card]], [Team, ID], [Case, Couloir1], [Couloir, Card]) :-
    ia1_chance([Team, ID], Case, Players, [Card], Card, Couloir).

% Cas ou il y a plusieur cartes dans le paquet
ia1([Players, Cards], [Team, ID], Current_pos, Best_possibility) :-
    
    findall([New_case, New_couloir, Card],
            (   transition(Current_pos, Cards, [New_case, New_couloir, Card]),
                heu_deplacement_1(Team, ID, [New_case, New_couloir], Card, Players, Cards, Score),
                Score > 10),
            Possibilities),
    sort(Possibilities, Possibilities_sorted), % On élimine les doublons
            
    % Initialiser le score au pire possible car on minimise la fonctio d'évaluation
    InitialScore = 1000000,
    best_possibily([Players, Cards], [Team, ID], Possibilities_sorted, InitialScore, BestScore, _, Best_possibility).

    
% Appel de l'IA 2
% On utilise l'heuristique d'évaluation de déplacement 2

% Cas ou il ne reste qu'une carte dans le paquet du joueur
% On fait comme pour une case chance -> choisir le couloir
ia2([Players, [Card]], [Team, ID], [Case, Couloir1], [Couloir, Card]) :-
    ia2_chance([Team, ID], Case, Players, [Card], Card, Couloir).
    
ia2([Players, Cards], [Team, ID], Current_pos, Best_possibility) :-
    
    findall([New_case, New_couloir, Card],
            (   transition(Current_pos, Cards, [New_case, New_couloir, Card]),
                heu_deplacement_2(Team, ID, [New_case, New_couloir], Card, Players, Cards, Score),
                Score > 10),
            Possibilities),
    sort(Possibilities, Possibilities_sorted), % On élimine les doublons
            
    % Initialiser le score au pire possible car on minimise la fonctio d'évaluation
    InitialScore = 1000000,
    best_possibily([Players, Cards], [Team, ID], Possibilities_sorted, InitialScore, BestScore, _, Best_possibility).