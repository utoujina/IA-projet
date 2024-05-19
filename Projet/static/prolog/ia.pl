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


/* --------------------------------------------------------------------- */
/*                                                                       */
/*                IA basée sur l'élagage Alpha beta                      */
/*                                                                       */
/* --------------------------------------------------------------------- */

% la stratégie apppliquée ici est de généré un abre ou chaque noeuds correspond a une
% carte appliquable aux joueurs. Puis de repertorier les différentes branches de l'arbre
% et de selectionner la branche qui a le meilleur score et qui ne cause pas de chutes 
% ce parcours ce fait en utilisant l'heuristique d'évaluation de déplacement  qui 
% verifie si il y'a une carte qui cause une chutte puis la stockage dans une liste appélee combiBeta
% et avant de parcourir une branche on verfie si une des cartes de la branche ne se trouve pas dans les
% combinaison beta si c'st le cas elle est eliminée sans faire la verification par l'heuristique

%exemple d'execution : 
% recherche_coup(etat([(belgique,1,19,2,19,1),(belgique,2,10,2,10,2),(belgique,3,5,0,5,3),(italie,1,3,2,3,4)],[(belgique,[1,2,3,4,5]),(italie,[1,2,3,4,5])],[1,2,3,4,5,6,6,8]),belgique,Meilleur,CarteAp,Com).

% Prédicat principal pour trouver les cartes appliquées à chaque joueur
recherche_coup(EtatActuel, Team, MeilleurCoup, CartesAppliquees, CombiBeta) :-
    % generation de l'arbre
    generate_permutations(5,3,Arbre),
    
    % recherche du meilleur coup
    alpha_beta_recherche_meilleur_combinaison_IA(EtatActuel, Team, Arbre, [EtatActuel, -inf], MeilleurCoup, [],CombiBeta),
    
    % recuperation des cartes appliquées pour obtenir ce meilleir coup 
    EtatActuel = etat(CoureursInitiaux, _, _),
    selectionner_coureurs(Team, CoureursInitiaux, CoureursDebut),
    MeilleurCoup = [EtatFinal, _],
    EtatFinal = etat(CoureursFinaux, _, _),
    selectionner_coureurs(Team, CoureursFinaux, CoureursFin),
    trouver_cartes_appliquees(Team, CoureursDebut, CoureursFin, CartesAppliquees).



% Recherche alpha-beta pour la meilleure combinaison de coups
alpha_beta_recherche_meilleur_combinaison_IA(_, _, [],  MeilleurCoup, MeilleurCoup, CombiBeta, CombiBeta). % Cas de base : plus de branches à traverser


% Si la branche contient un nœud foireux, on l'ignore (l' élagage )
alpha_beta_recherche_meilleur_combinaison_IA(EtatActuel, Team, [PremiereBranche|AutresBranches],  MeilleurActuel, MeilleurCoup, CombiBeta, NewCombiBeta) :-

    % Extraire l'état des coureurs et des cartes restantes
    EtatActuel = etat(Coureurs, CartesChaqueEquipe, _),
    
    % Sélectionner les coureurs de la team de l'IA
    selectionner_coureurs(Team, Coureurs, CoureursEquipe),
    
    % Obtenir les cartes de l'équipe
    cartes_equipe(Team, CartesChaqueEquipe, CartesEquipeCourante),

    %verifie que la branche ne contient pas une noued foireux repertorier dans le passé
    \+ check_combi(PremiereBranche,Team,1,CartesEquipeCourante,CombiBeta),

    alpha_beta_recherche_meilleur_combinaison_IA(EtatActuel, Team, AutresBranches, MeilleurActuel, MeilleurCoup, CombiBeta, NewCombiBeta).


% Si la branche actuelle n'est pas dans CombiBeta, évaluer la branche
alpha_beta_recherche_meilleur_combinaison_IA(EtatActuel, Team, [PremiereBranche|AutresBranches], [EtatActuelMeilleur, MeilleurScoreActuel], MeilleurCoup, CombiBeta, NewCombiBeta) :-

    % Extraire l'état des coureurs et des cartes restantes
    EtatActuel = etat(Coureurs, CartesChaqueEquipe, _),
    
    % Sélectionner les coureurs de la team de l'IA
    selectionner_coureurs(Team, Coureurs, CoureursEquipe),
    
    % Obtenir les cartes de l'équipe
    cartes_equipe(Team, CartesChaqueEquipe, CartesEquipeCourante),

    %verifie que la branche ne contient pas une combie foireuse repertorier dans le passé
    check_combi(PremiereBranche,Team,1,CartesEquipeCourante,CombiBeta),

    % Mettre à jour l'état en déplaçant les coureurs
    update_position(EtatActuel, Team, CartesEquipeCourante, PremiereBranche, 1, NouvelEtatTransit, CombiBeta, NewCombiBetaT, [], ListeChuteDetectee),
    

    contains_true(ListeChuteDetectee,Val),
    
    appel(Val,EtatActuelMeilleur, MeilleurScoreActuel ,NouvelEtatTransit,Result),
    
    NouveauMeilleurCoup = Result,
    
    % Appeler récursivement alpha_beta_recherche_meilleur_combinaison_IA
    alpha_beta_recherche_meilleur_combinaison_IA(EtatActuel, Team, AutresBranches, NouveauMeilleurCoup, MeilleurCoup, NewCombiBetaT, NewCombiBeta).




% Cas de base : plus de coureurs à traiter
update_position(EtatActuel, _,_, [], _,  EtatActuel, CombiBeta, CombiBeta, ListeChute,ListeChute). % Aucun changement et aucune chute

update_position(EtatActuel,Team, Cartes, [Index | ResteIndex],Ind, NouvelEtat, CombiBeta,NewCombiBeta,ListeChuteDetecteeIn, ListChuteDetectee) :-
    % Obtenir la carte correspondant à l'index
    get_carte(Cartes, Index, Carte),
    
    % Extraire l'état des coureurs
    EtatActuel = etat(Coureurs, _, _),
    
    selectionner_coureurs(Team, Coureurs, CoureursEquipe),

    % Obtenir le coureur correspondant à l'index
    coureur_at_index(Ind,CoureursEquipe,Coureur),
    

    % Déplacer le premier joueur
    heuristique_deplacer_alpha_beta(EtatActuel, Coureur, Carte, NouvelEtatTransit, CombiBeta, NewCombiBetaT, ChuteLocale),

    IndT is Ind +1,
    ChuteLocaleT = [ChuteLocale|ListeChuteDetecteeIn],
    % Appeler récursivement update_poesition avec l'état de transition
    update_position(NouvelEtatTransit,Team, Cartes, ResteIndex,IndT, NouvelEtat, NewCombiBetaT, NewCombiBeta,ChuteLocaleT, ListChuteDetectee).
    
% Prédicat deplacer_alpha_beta/7 avec gestion des chutes et mise à jour de CombiBeta
heuristique_deplacer_alpha_beta(EtatActuel, Coureur, Carte, NouvelEtat, CombiBeta, NewCombiBeta, ChuteDetectee) :-
    
    %Extraire l'état des coureurs
    EtatActuel = etat(Coureurs, CartesChaqueEquipe, CartesRestantesJeux) ,
    
    Coureur = (Team, ID, Position,Case, Temps, Classement),

    % Calculer la nouvelle position
    NouvellePosition is Position + Carte,
    NouveauTemps is Temps + Carte,

    select((Team, ID, Position,Case, Temps, Classement), Coureurs, CoureursRest),
    
    % Vérifier les chutes
    check_chutes(NouvellePosition,Position, CoureursRest, ChuteLocale),
    (
        ChuteLocale = true ->
        % Si une chute est détectée, ajouter à CombiBeta
        NewCombiBeta = [(Team, ID, Carte) | CombiBeta],
        NouvelEtat = EtatActuel, % Pas de changement d'état en cas de chute
        ChuteDetectee = true
       ;
        % Si aucune chute n'est détectée, mettre à jour l'état
        NewCombiBeta = CombiBeta,
        ChuteDetectee = false,
        
        % Mettre à jour la liste des coureurs
        random(0,2,CaseT),
        UpdatedCoureurs = [(Team, ID, NouvellePosition, CaseT,NouveauTemps, Classement) | CoureursRest],
        mettre_jour_classement(UpdatedCoureurs, UpdatedCoureursNouveauClassement),
        
        % Mettre à jour les cartes restantes
        remove_carte(Carte, Team, CartesChaqueEquipe, NouvellesCartesEquipeCourante),

        % Créer le nouvel état
        NouvelEtat = etat(UpdatedCoureursNouveauClassement, NouvellesCartesEquipeCourante, CartesRestantesJeux)
    ).

/* --------------------------------------------------------------------- */
/*                                                                       */
/*                                PREDICAT AUXILIAIRES                   */
/*                                                                       */
/* --------------------------------------------------------------------- */


%--------------------------------------------------------------------------------------------------------------
% Prédicat auxiliaire pour obtenir la carte à l'index donné, en tenant compte de l'indexation commençant à 1
get_carte([Carte | _], 1, Carte). % Cas de base : index 1, retourner la première carte
get_carte([_ | RestCartes], Index, Carte) :-
    Index > 1,
    NextIndex is Index - 1,
    get_carte(RestCartes, NextIndex, Carte).

%--------------------------------------------------------------------------------------------------------------
% remove_carte(Carte, Team, CartesChaqueEquipe, NouvellesCartesEquipeCourante)
% Prend une carte et une équipe, puis retire cette carte de la liste des cartes de l'équipe spécifiée.
remove_carte(_, _, [], []). % Cas de base : si la liste est vide, le résultat est une liste vide.
remove_carte(Carte, Team, [(Team, Cartes) | Reste], [(Team, NouvellesCartes) | NouvellesCartesEquipeCourante]) :-
    % Si l'équipe correspond à celle spécifiée, retirer la carte de sa liste de cartes.
    select(Carte, Cartes, NouvellesCartes),
    remove_carte(Carte, Team, Reste, NouvellesCartesEquipeCourante).
remove_carte(Carte, Team, [AutreEquipe | Reste], [AutreEquipe | NouvellesCartesEquipeCourante]) :-
    % Si ce n'est pas l'équipe spécifiée, continuer la recherche.
    remove_carte(Carte, Team, Reste, NouvellesCartesEquipeCourante).

%--------------------------------------------------------------------------------------------------------------
% extract_positions/2
% Extrait toutes les positions des coureurs dans une liste de coureurs.
extract_positions([], []).
extract_positions([(_, _, Position, _, _, _) | RestCoureurs], [Position | RestPositions]) :-
    extract_positions(RestCoureurs, RestPositions).

%--------------------------------------------------------------------------------------------------------------
% Base case: An empty list returns an empty list of positions
extract_classements([], []).

% Recursive case: Extract the position from the head of the list and process the rest
extract_classements([(_, _,_, _, _, Cls) | Rest], [Cls | Classement]) :-
    extract_classements(Rest, Classement).


%--------------------------------------------------------------------------------------------------------------
% cartes_equipe(Team, CartesChaqueEquipe, CartesEquipe)
% Prend une équipe et retourne la liste des cartes de cette équipe.

cartes_equipe(_, [], []) :- % Cas de base : si la liste est vide, le résultat est une liste vide.
!, fail. % Échoue si l'équipe n'est pas trouvée.

cartes_equipe(Team, [(Team, Cartes) | _], Cartes) :- % Si l'équipe correspond, retourner ses cartes.
!.

cartes_equipe(Team, [_ | Reste], CartesEquipe) :- % Si l'équipe ne correspond pas, continuer à parcourir la liste.
cartes_equipe(Team, Reste, CartesEquipe).

%--------------------------------------------------------------------------------------------------------------
% check_chutes/4

% Vérifie si une position est plus grande ou égale à une des positions dans une liste
check_chutes(NouvellePosition,InitPosition, [], false). % Cas de base : aucune position dans la liste

check_chutes(NouvellePosition,InitPosition, [(_, _, Position,Case, _, _) | RestePositions], ChuteDetectee) :-
    (
        ((\+ Position =< InitPosition ), NouvellePosition >= Position) -> 
        ChuteDetectee = true
    ;
        check_chutes(NouvellePosition, InitPosition,RestePositions, ChuteDetectee)
    ).
%--------------------------------------------------------------------------------------------------------------
% Cas de base : une liste vide ne contient pas de true
contains_true([], V):- V = false.

% Si la tête de la liste est true, retourner true
contains_true([true|_], V) :- V = true.

% Si la tête de la liste n'est pas true, vérifier le reste de la liste
contains_true([_|Rest], Result) :-
    contains_true(Rest, Result).
%-----------------------------------------------------------------------------------
% Cas de base : une seule entrée dans la liste, c'est le minimum.
dernier_coureur([Coureur], Coureur).

% Cas récursif : comparer les classements et continuer.
dernier_coureur([(Team, ID, Pos,Case,Temps,Cls) | Reste], MinCoureur) :-
    dernier_coureur(Reste, MinCoureurReste),
    MinCoureurReste = (_, _, _,_, _, MinCls),
    (Cls > MinCls -> MinCoureur = (Team, ID, Pos,Case, Temps, Cls) ; MinCoureur = MinCoureurReste).

% Prédicat pour trouver le coureur avec le classement le plus bas
dernier_coureur(ListeCoureurs, CoureurAvecMinClassement) :-
    dernier_coureur(ListeCoureurs, CoureurAvecMinClassement).

%--------------------------------------------------------------------------------------------------------------
%determine la plus grande carte parmis les cartes du joueurs 
% Cas de base : le maximum d'une liste avec un seul élément est cet élément.
% exemple d'utilisation plus_grande_carte([1, 3, 7, 2, 5], Max).        
% Max = 7
plus_grande_carte([X], X).

% Cas récursif : comparer le premier élément avec le maximum du reste de la liste.
plus_grande_carte([H|T], Max) :-
    plus_grande_carte(T, MaxTail),
    ( H > MaxTail -> Max = H ; Max = MaxTail ).

%---------------------------------------------------------------------------

% plus_grande_carte/2
% Trouve la plus grande carte dans une liste.
plus_grande_carte([Carte], Carte).
plus_grande_carte([Carte | RestCartes], MaxCarte) :-
    plus_grande_carte(RestCartes, TempMaxCarte),
    (Carte > TempMaxCarte -> MaxCarte = Carte; MaxCarte = TempMaxCarte).

%--------------------------------------------------------------------------------------------------------------

% selectionner_coureurs/3
% Sélectionne et trie les coureurs d'une équipe donnée.
selectionner_coureurs(Team, ListeCoureurs, CoureursEquipeSorted) :-
    findall((Team, ID, Position, Case, Temps, Classement),
            member((Team, ID, Position, Case, Temps, Classement), ListeCoureurs),
            CoureursEquipe),
    sort(2, @=<, CoureursEquipe, CoureursEquipeSorted).

%--------------------------------------------------------------------------------------------------------------

% Prédicat pour récupérer l'élément à un index donné dans une liste
coureur_at_index(1, [Coureur|_], Coureur) :- !.
coureur_at_index(Index, [_|Reste], Coureur) :-
    Index > 1,
    Index1 is Index - 1,
    coureur_at_index(Index1, Reste, Coureur).

%--------------------------------------------------------------------------------------------------------------
% insert_sorted/3
% Insère un élément dans une liste triée de manière à conserver l'ordre trié.
insert_sorted(Element, [], [Element]).
insert_sorted((Team, ID, Position, Case, Temps, Classement), [(Team1, ID1, Position1, Case1, Temps1, Classement1) | Rest], [(Team, ID, Position, Case, Temps, Classement), (Team1, ID1, Position1, Case1, Temps1, Classement1) | Rest]) :-
    (Position + (Case/10)) =< (Position1 + (Case1/10)).
insert_sorted((Team, ID, Position, Case, Temps, Classement), [(Team1, ID1, Position1, Case1, Temps1, Classement1) | Rest], [(Team1, ID1, Position1, Case1, Temps1, Classement1) | Sorted]) :-
    (Position + (Case/10)) > (Position1 + (Case1/10)),
    insert_sorted((Team, ID, Position, Case, Temps, Classement), Rest, Sorted).

% Prédicat pour trier la liste entière
sort_tuples([], []).
sort_tuples([H|T], Sorted) :-
    sort_tuples(T, SortedTail),
    insert_sorted(H, SortedTail, Sorted).



% Prédicat de base qui initialise l'indice à 1 et le classement précédent à celui du premier élément.
change_classement([(A, B, C,P, FirstCls, E) | T], UpdatedList) :-
    change_classement(T, [(A, B, C,P, FirstCls, 1)], FirstCls, 1, UpdatedList).

% Prédicat d'assistance avec gestion du classement précédent et de l'indice.
% Cas de base : liste vide.
change_classement([], Acc, _, _, Acc).

% Cas récursif : traiter chaque élément de la liste en vérifiant le classement.
change_classement([(A, B, C,P, Cls, _) | T], Acc, PrevCls, PrevIndex, UpdatedList) :-
    (Cls = PrevCls -> 
        Index = PrevIndex;  % Garde le même indice si le classement est identique
        Index is PrevIndex + 1  % Incrémente l'indice si le classement change
    ),
    change_classement(T, [(A, B, C,P, Cls, Index) | Acc], Cls, Index, UpdatedList).

%--------------------------------------------------------------------------------------------------------------
% score/2
% Calcule le score total d'un classement.
points(1, 10).
points(2, 9).
points(3, 8).
points(4, 7).
points(5, 6).
points(6, 5).
points(7, 4).
points(8, 3).
points(9, 2).
points(10, 1).
points(11, 0).
points(12, 0).

% Prédicat pour calculer le score d'une liste de classements
calculer_scores([], []).
calculer_scores([Rang | Rangs], [Score | Scores]) :-
    points(Rang, Score),
    calculer_scores(Rangs, Scores).

score(Classement, TotalScore) :-
    calculer_scores(Classement, Scores),
    sum_list(Scores, TotalScore).

%--------------------------------------------------------------------------------------------------------------
% appel/5
% Appel principal pour déterminer l'état et le score
appel(true, EtatActuel, MeilleurScoreActuel, _, Result) :-
    Result = [EtatActuel, MeilleurScoreActuel].

appel(false, EtatActuel, MeilleurScoreActuel, NouvelEtatTransit, Result) :-
    NouvelEtatTransit = etat(CoureursT, CartesChaqueEquipe, _),
    selectionner_coureurs(Team, CoureursT, CoureursEquipe),
    % Extraire les classements des coureurs après déplacement
    extract_classements(CoureursT, Classement),
    % Calculer le score basé sur le classement
    score(Classement, Score),
    % Comparer le score actuel avec le meilleur score trouvé jusqu'à présent
    appelCom(Score, MeilleurScoreActuel, Val),
    Result = [NouvelEtatTransit, Val].

appelCom(Score, MeilleurScoreActuel, Result) :-
    Score > MeilleurScoreActuel,
    Result = Score.
appelCom(Score, MeilleurScoreActuel, Result) :-
    Score =< MeilleurScoreActuel,
    Result = MeilleurScoreActuel.

%--------------------------------------------------------------------------------------------------------------
% check_combi/5
% Prédicat principal qui vérifie que les cartes aux index donnés ne sont pas déjà dans CombiBeta pour l'équipe donnée
check_combi([], _, _, _, _). % Cas de base : la liste d'index est vide, tout va bien
check_combi([Index | Rest], Team, ID, Cartes, CombiBeta) :-
    get_carte(Cartes, Index, Carte),
    \+ member((Team, ID, Carte), CombiBeta), % Vérifie que la carte n'est pas déjà associée à l'équipe dans CombiBeta
    IDT is ID + 1,
    check_combi(Rest, Team, IDT, Cartes, CombiBeta).

%--------------------------------------------
% Prédicat pour extraire les deux derniers éléments des tuples où le deuxième élément est égal à ID
trouver_elements([], _, []).  % Cas de base : liste vide retourne une liste vide
trouver_elements([(Pays, ID, X, Y) | Reste], ID, [(X, Y) | Resultat]) :- 
    trouver_elements(Reste, ID, Resultat).
trouver_elements([(Pays, ID2, X, Y) | Reste], ID, Resultat) :- 
    ID \= ID2,
    trouver_elements(Reste, ID, Resultat).


%--------------------------------------------------------------------------------------------------------------

% generate_permutations(N, K, Perms) generates all possible permutations of K elements chosen from 1 to N.
generate_permutations(N, K, Perms) :-
    findall(Perm, permutation(N, K, Perm), Perms).

% permutation(N, K, Perm) defines a permutation of K elements chosen from 1 to N.
permutation(N, K, Perm) :-
    numlist(1, N, List),
    permute(List, K, Perm).

% permute(List, K, Perm) generates permutations of length K from List.
permute(_, 0, []).
permute(List, K, [H|T]) :-
    K > 0,
    select(H, List, Rest),
    K1 is K - 1,
    permute(Rest, K1, T).

% numlist(Low, High, List) generates a list of numbers from Low to High.
numlist(Low, High, []) :- Low > High.
numlist(Low, High, [Low|T]) :-
    Low =< High,
    Low1 is Low + 1,
    numlist(Low1, High, T).

% Prédicat pour trouver les cartes appliquées en comparant les états initiaux et finaux des coureurs
trouver_cartes_appliquees(_, [], [], []).

trouver_cartes_appliquees(Team, [(Team, ID, PosInit,_, _, _)|RestInit], [(Team, ID, PosFinal,CaseF, _, _)|RestFinal], [(Team, ID,CaseF, CarteAppliquee)|RestCartes]) :-
    CarteAppliquee is PosFinal - PosInit,
    trouver_cartes_appliquees(Team, RestInit, RestFinal, RestCartes).

trouver_cartes_appliquees(Team, [_|RestInit], [_|RestFinal], RestCartes) :-
    trouver_cartes_appliquees(Team, RestInit, RestFinal, RestCartes).

%permet de mettre à jour les classements
mettre_jour_classement(Coureurs,Result):-
    sort_tuples(Coureurs, Sorted),
    reverse(Sorted, ReversedList),
    change_classement(ReversedList,Result).
