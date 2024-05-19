%-----------------------------------------------------------------------------------------------------------------------
% draft du jeu en prolog. n'est plus utiliser dans le code
%-----------------------------------------------------------------------------------------------------------------------



% :- module(predicats_auxiliere_jeux, [remove_carte/4,
%                                     get_carte/3,
%                                     extract_positions/2,
%                                     check_chutes/6,
%                                     dernier_coureur/2,
%                                     selectionner_coureurs/3,
%                                     plus_grande_carte/2,
%                                     insert_sorted/3,
%                                     show_updated_classement/1,
%                                     sort_tuples/2,
%                                     change_classement/5,
%                                     change_classement/2,
%                                     refill_deck_empty/5,
%                                     update_team_card/4,
%                                     remove_card_from_each/5,
%                                     remove_team_card/5,
%                                     move_to_side/2,
%                                     handle_team_crash/4,
%                                     handle_crash/7,
%                                     attempt_to_overtake/4,
%                                     defausser_cartes/2,
%                                     select_n/4,
%                                     echange_carte/,4
%                                     case_echange/8]).

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
    % Continuer à parcourir le reste de la liste.
    remove_carte(Carte, Team, Reste, NouvellesCartesEquipeCourante).

remove_carte(Carte, Team, [EquipeCartes | Reste], [EquipeCartes | NouvellesCartesEquipeCourante]) :-
    % Si l'équipe ne correspond pas, continuer à parcourir la liste sans modification.
    remove_carte(Carte, Team, Reste, NouvellesCartesEquipeCourante).

%--------------------------------------------------------------------------------------------------------------
% Base case: An empty list returns an empty list of positions
extract_positions([], []).

% Recursive case: Extract the position from the head of the list and process the rest
extract_positions([(Team, ID, Pos, Temps, Cls) | Rest], [Pos | Positions]) :-
    extract_positions(Rest, Positions).

%--------------------------------------------------------------------------------------------------------------
% check_chutes(Position, ListePosition, Team, ID, ListeChutes, NewListeChutes)
% Ajoute le tuple (Team, ID, Position) à ListeChutes si Position est dans ListePosition
check_chutes(Position, ListePosition, Team, ID, ListeChutes, NewListeChutes) :-
    member(Position, ListePosition),
    !, % Coupe pour éviter le backtracking après avoir trouvé la position
    NewListeChutes = [(Team, ID, Position) | ListeChutes].

check_chutes(_, _, _, _, ListeChutes, ListeChutes).

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

% Cas de base : une seule entrée dans la liste, c'est le minimum.
dernier_coureur([Coureur], Coureur).

% Cas récursif : comparer les classements et continuer.
dernier_coureur([(Team, ID, Pos,Temps,Cls) | Reste], MinCoureur) :-
    dernier_coureur(Reste, MinCoureurReste),
    MinCoureurReste = (_, _, _, _, MinCls),
    (Cls > MinCls -> MinCoureur = (Team, ID, Pos, Temps, Cls) ; MinCoureur = MinCoureurReste).

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

%--------------------------------------------------------------------------------------------------------------

% le prédicat pour sélectionner les coureurs d'une certaine équipe
selectionner_coureurs(Team, ListeCoureurs, CoureursEquipe) :-
    findall((Team, ID, Position, Temps, Classement),
            member((Team, ID, Position, Temps, Classement), ListeCoureurs),
            CoureursEquipe).
        
%--------------------------------------------------------------------------------------------------------------

% ces deux predicat sont utiliser pour mettre a jour le classement
insert_sorted(Tuple, [], [Tuple]).
insert_sorted((A1, B1, C1, D1, E1), [(A2, B2, C2, D2, E2) | T], [(A1, B1, C1, D1, E1), (A2, B2, C2, D2, E2) | T]) :-
    C1 =< C2.
insert_sorted((A1, B1, C1, D1, E1), [(A2, B2, C2, D2, E2) | T], [(A2, B2, C2, D2, E2) | Sorted]) :-
    C1 > C2,
    insert_sorted((A1, B1, C1, D1, E1), T, Sorted).

% Prédicat pour trier la liste entière
sort_tuples([], []).
sort_tuples([H|T], Sorted) :-
    sort_tuples(T, SortedTail),
    insert_sorted(H, SortedTail, Sorted).

% Prédicat de base qui initialise l'indice à 1 et le classement précédent à celui du premier élément.
change_classement([(A, B, C, FirstCls, E) | T], UpdatedList) :-
    change_classement(T, [(A, B, C, FirstCls, 1)], FirstCls, 1, UpdatedList).

% Prédicat d'assistance avec gestion du classement précédent et de l'indice.
% Cas de base : liste vide.
change_classement([], Acc, _, _, Acc).

% Cas récursif : traiter chaque élément de la liste en vérifiant le classement.
change_classement([(A, B, C, Cls, _) | T], Acc, PrevCls, PrevIndex, UpdatedList) :-
    (Cls = PrevCls ->
        Index = PrevIndex;  % Garde le même indice si le classement est identique
        Index is PrevIndex + 1  % Incrémente l'indice si le classement change
    ),
    change_classement(T, [(A, B, C, Cls, Index) | Acc], Cls, Index, UpdatedList).



%afficher le classement mis à jour
show_updated_classement([]).

show_updated_classement([Move|Moves]) :-
    write(Move), nl,

show_updated_classement(Moves).

%--------------------------------------------------------------------

%Vérifie si la position est une case chance, et si oui pioche une carte dans les cartes du jeux
case_chance(Team ,ID ,Position ,CartesRestantesJeux , ListCaseChance, Carte, NouvellesCarteRestantesJeux ) :-
    member(Position, ListCaseChance),
    piocher_carte(CartesRestantesJeux , Carte , NouvellesCarteRestantesJeux ).

%Piocher une carte de CartesRestantesJeux
piocher_carte([Carte| RestCartes], Carte, RestCartes).

%------------------------------------------------------------------
%exemple d'utilisation 
%case_echange(bel,[3,7],[2,6,5,4,4,5,6,7],X,Y). avec X qui donne les cartes updated
%échange ou défausse 3 cartes à l'equipe du coureur
case_echange(Team ,AnciennesCarte, CartesRestantesJeux, UpdatedCarte, NouvellesCarteRestantesJeux):-
    (length(AnciennesCarte, Len), 
    Len < 3 -> echange_carte(AnciennesCarte , CartesRestantesJeux , UpdatedCarte , NouvellesCarteRestantesJeux);
     defausser_cartes(Team, CartesRestantesJeux, AnciennesCarte, UpdatedCarte, NouvellesCarteRestantesJeux)).

%--------------------------------------------------------------------------------
% %permet l'échange des carte lorsqu'on tombe sur une case échange avec moins de 2 cartes
echange_carte(AnciennesCarte , CartesRestantesJeux , NouvellesCarte , NouvellesCarteRestantesJeux):-
    length(AnciennesCarte , Len),
    Echange is Len, 
    select_n(Echange, CartesRestantesJeux, NouvellesCarte, NouvellesCarteRestant),
    append(AnciennesCarte, NouvellesCarteRestant , NouvellesCarteRestantesJeux).

%-----------------------------------------------------------------------


% Défausser 3 cartes de l'équipe. Si le deck devient vide, le remplir avec 5 nouvelles cartes de CartesRestantesJeux.
defausser_cartes(Team, CartesRestantesJeux, AnciennesCarte, NouvelleCartesCoureurs, NouvellesCartesRestantesJeux) :-
    select_n(3, AnciennesCarte, _, TempUpdatedCartes),
    ( TempUpdatedCartes = []
    -> refill_deck_empty(Team, 5, CartesRestantesJeux, NouvelleCartesCoureurs, NouvellesCartesRestantesJeux)
    ;  (NouvelleCartesCoureurs = TempUpdatedCartes,
        NouvellesCartesRestantesJeux = CartesRestantesJeux)
    ).


%selection les n premier nombre d'une liste
%exemple d'utilisation select_n(5,[2,5,4,6,3,5],X,Y)
select_n(0, Liste , [] , Liste).
select_n(N , [H|T] , [H|Selectiner],Rest) :-
    N > 0,
    N1 is N - 1 ,
    select_n(N1 , T , Selectiner , Rest).

%-----------------------------------------------------------------------

% attempt_to_overtake/4
%exemple d'utilisation attempt_to_overtakes(2,5,[(bel,2,4,8,6),(it,2,5,7,6)],X).
% Détermine si un dépassement aura lieu en trouvant la plus petite position parmi les coureurs entre AnciennePosition et NouvellePosition.
attempt_to_overtake(AnciennePosition, NouvellePosition, Coureurs, MinPosition) :-
    attempt_to_overtake_helper(Coureurs, AnciennePosition, NouvellePosition, inf, MinPosition).

% attempt_to_overtake_helper/5
% Parcourt la liste des coureurs pour trouver la plus petite position entre AnciennePosition et NouvellePosition.
attempt_to_overtake_helper([], _, _, Min, Min) :- Min \= inf.
attempt_to_overtake_helper([], _, _, inf, 0).  % Si aucun coureur n'est trouvé dans la plage, retourner 0.
attempt_to_overtake_helper([(Team, ID, OtherPosition, Temps, Classement) | Rest], AnciennePosition, NouvellePosition, CurrentMin, MinPosition) :-
    ( OtherPosition >= AnciennePosition,
      OtherPosition =< NouvellePosition
    -> NewMin is min(CurrentMin, OtherPosition)
    ;  NewMin = CurrentMin
    ),
    attempt_to_overtake_helper(Rest, AnciennePosition, NouvellePosition, NewMin, MinPosition).
    

% gére une chute
%exemple d'utilisation handle_crash(5,[(bel,2,5,4,6),(it,2,5,5,7),(hol,2,5,4,5),(ger,2,6,8,3)],[2,5,4,6,3,5,4],[(bel,[2,5]),(it,[5]),(hol,[1,2,5,4]),(ger,[2])],X,Y,Z).
handle_crash(Position, Coureurs, CartesRestantesJeux ,CartesCoureurs ,UpdatedCoureurs,FinalCartesCoureurs,FinalCartesRestantJeux) :-
    % etat(Coureurs, CartesEquipeCourante , CartesRestantesJeux , CartesEquipe2 , CartesEquipe3, CartesEquipe4 ) = EtatActuel,

    handle_team_crash(Position,Coureurs,Crashers,NonCrashers),

    move_to_side(Crashers , UpdatedCrashers), % move racers to the side of the board
    remove_card_from_each(Crashers, CartesRestantesJeux, CartesCoureurs, FinalCartesCoureurs, FinalCartesRestantJeux),

    append(UpdatedCrashers,NonCrashers , UpdatedCoureurs). %met à jour la liste des coureurs 



% permet de classer les équipes entre ceux qui sont sur la case du crash et non
partition_racers(Position, (T, Id, Pos, Temps, C), (Cr, NCr), (UpdatedCr, UpdatedNCr)) :-
    (   Pos = Position
    ->  UpdatedCr = [(T, Id, Pos, Temps, C) | Cr], UpdatedNCr = NCr
    ;   UpdatedNCr = [(T, Id, Pos, Temps, C) | NCr], UpdatedCr = Cr).

handle_team_crash(Position, Coureurs, Crashers, NonCrashers) :-
    % utilisation de foldl pour partitioner les coureurs
    foldl(partition_racers(Position), Coureurs, ([], []), (Crashers, NonCrashers)).

 
%move to side crashed racers 
move_to_side([] , []).
move_to_side([(Team, ID, Position, Classement, Temps) | Tail], [(Team, ID, SidePosition, Classement, Temps) | UpdatedTail]) :-
    SidePosition is Position + 0.1,  % Assuming decimal positions are allowed to represent side movement
    move_to_side(Tail, UpdatedTail).


%----------------------------------------------------------------------
% enlève une carte dans les cartes de l'équipe 
remove_team_card(Team, CartesRestantesJeux, CartesCoureurs, NouvelleCartesCoureurs,NouvelleCartesRestantesJeux) :-
    cartes_equipe(Team ,CartesCoureurs, CartesEquipeCourante),
    select(_, CartesEquipeCourante, TempUpdatedCartes),
    (TempUpdatedCartes = [ ] -> refill_deck_empty(Team , 5 , CartesRestantesJeux , NouvelleCartesCoureurs, NouvelleCartesRestantesJeux )
    ; CartesRestantesJeux = NouvelleCartesRestantesJeux,
    NouvelleCartesCoureurs = TempUpdatedCartes).


% permet de retirer une carte dans chaque équipe ou le ayant eu un crash
%exemple D'utilisation remove_card_from_each([(bel,2,5,4,6),(it,2,5,5,6),(hol,2,5,4,6)],[2,5,4,7,5,6],[(bel,[2,5]),(it,[5]),(hol,[1,2,5,4])],X,Y).
remove_card_from_each([], CartesRestantesJeux, CartesCoureurs,CartesCoureurs,CartesRestantesJeux).
remove_card_from_each([(Team, ID, Pos,  Temps, Cls) | Tail], CartesRestantesJeux , CartesCoureurs , FinalCartesCoureurs, FinalCartesRestantJeux) :-
    remove_team_card(Team, CartesRestantesJeux, CartesCoureurs, NouvelleCartesEquipe, NouvellesCarteRestantesJeux),
    update_team_card(Team, NouvelleCartesEquipe, CartesCoureurs, NouvelleCartesCoureurs),
    remove_card_from_each(Tail, NouvellesCarteRestantesJeux , NouvelleCartesCoureurs , FinalCartesCoureurs, FinalCartesRestantJeux).


%mettre à jour la liste des cartes de l'équipe dans la structure global
update_team_card(Team, NewCards, CartesCoureurs, UpdatedCartesCoureurs) :-
    select((Team, _), CartesCoureurs, ResteTeams),
    UpdatedCartesCoureurs = [(Team,NewCards) | ResteTeams ].

%remplis les cartes d'une equipe si ces cartes finissent
refill_deck_empty(Team, NumCartes , CartesRestantesJeux, NewCarte, UpdatedCartesRestantesJeux) :-
    select_n(NumCartes, CartesRestantesJeux , NewCarte , UpdatedCartesRestantesJeux).


etat(Etat) :- Etat = (Coureurs, CartesRestantesJeux, CartesCoureurs).

cartes :- between(0, 95, X).

%transition entre état
deplacer(EtatActuel,Team,ID,Position,ListCaseEchange,NouvelEtat,UpdatedCarte,NouvellesCarteRestantesJeux) :-
    
    %on récupère Coureurs et  CartesRestantes dans EtatActuel à l'aide de l'unification
    %Par exemple, si EtatActuel est etat([(BEL, 1, 5, 1, 6) , (IT, 1, 2, 1, 9)], [5, 3, 2]), alors après cette ligne :
    %Coureurs sera [(BEL, 1, 5, 1, 6) , (IT, 1, 2, 1, 9)]
    %CartesRestantes sera [5, 3, 2] 
    %liste de position
    etat(Coureurs, CartesRestantesJeux, CartesCoureurs) = EtatActuel,

    % Trouver le coureur à déplacer
    member((Team, ID, Position, Temps,Classement), Coureurs),
    
    % %on attribut les information recuperé à coureur
    Coureur = (Team, ID, Position,Temps, Classement),

    cartes_equipe(Team,CartesCoureurs,CartesEquipeCourante),

    select(Carte,CartesEquipeCourante,NouvelleCartesEquipeCourante),

    NewPosition is Position + Carte ,

    %vérifie si New position est une case Echange 
    ( member(NewPosition , ListCaseEchange) ->
    case_echange(Team,NouvelleCartesEquipeCourante ,CartesRestantesJeux ,UpdatedCarte,NouvellesCarteRestantesJeux)  ).







    % % Calculer la nouvelle position
    % NouvellePosition is Position + Carte,

    % %cumuler le temps du coureur
    % NouveauTemps is Temps + Carte,

 
    % % Mettre à jour la liste des coureurs
    % %on retire les anciennes information
    % select((Team, ID, Position, Temps, Classement), Coureurs, CoureursRest),
    
    % %on met a jours
    % UpdatedCoureurs = [(Team, ID, NouvellePosition, NouveauTemps, Classement) | CoureursRest],

    % mettre_jour_classement(UpdatedCoureurs, UpdatedCoureursNouveauClassement),
    
    % % on  Met à jour les cartes restantes
    % select(Carte, CartesEquipeCourante, NouvellesCartesEquipeCourante),


    % % Créer le nouvel état
    % NouvelEtat = etat(UpdatedCoureursNouveauClassement, NouvellesCartesEquipeCourante,  CartesRestantesJeux).

%--------------------------------------------------------------------------------------------------------------