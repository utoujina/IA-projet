from typing import Tuple
from Game.schemas.player import Player, Card, Type, Team, Players, Counter
from Game.database import database
import random

def get_pos(Team: str, ID: int) -> Tuple[int, int]:
    """
    Return the position of a player
    """
    return database["players"][Team][ID]

def modify_pos(Team: str, ID: int, New_pos: Tuple[int, int]) -> Player:
    """
    Modify the position of a player
    """
    old_pos = database["players"][Team][ID]["position"][0]
    database["players"][Team][ID]["position"][0] = New_pos[0] + old_pos
    database["players"][Team][ID]["position"][1] = New_pos[1]
    
    return database["players"][Team][ID]
    
def get_ranking(Team: str, ID: int) -> int:
    """
    Return the ranking of a player
    """
    return database["players"][Team][ID]["ranking"]

def modify_ranking(Team: str, ID: int, New_rank: int) -> Player:
    """
    Modify the ranking of a player
    """
    database["players"][Team][ID]["ranking"] = New_rank
    return database["players"][Team][ID]

    
def get_cards(Team: str) -> list[Card]:
    """
    Return the set of cards of the player
    """
    return database["cards"][Team]

def push_card(Team: str, value: int) -> Card:
    """
    Add a card, and return the set of cards of the player containning the new card
    """
    database["cards"][Team].append(value)
    return database["cards"][Team]

def pop_card(Team: str, value: int) -> Card:
    """
    Delete the card, and return the set of card without the card
    """
    database["cards"][Team].remove(value)
    return database["cards"][Team]

def get_player_type(Team: str) -> Type:
    """
    Return the type of a player
    
    Notes
    -----
    A player is either a Human, or an IA
    """
    return database["type"][Team]

def modify_player_type(Team: str, New_type: str) -> Type:
    """
    Modify the type of a player
    
    Notes
    -----
    A player is either a Human, or an IA
    """
    database["type"][Team] = New_type
    return database["type"][Team]

def get_current_team() -> Team:
    """
    Get the current player
    
    Notes
    -----
    It is either BEL, DEU, NLD or ITA.
    """
    return database["current_team"]

def modify_current_team(New_team: Team) -> Team:
    """
    Modify the team that is currently playing 
    
    Notes
    -----
    It is either BEL, DEU, NLD or ITA.
    """
    database["current_team"][0] = New_team
    return database["current_team"]

def modify_current_player(New_player: int) -> Team:
    """
    Modify the player that is currently playing 
    
    Notes
    -----
    It is either 1, 2 or 3.
    """
    database["current_team"][1] = New_player
    return database["current_team"]

def get_counter() -> Counter:
    """
    Get the current counter
    """
    return database["counter"]

def modify_counter(New_counter: Counter) -> Counter:
    """
    Modify the current counter
    """
    database["counter"] = New_counter
    return New_counter

def is_game_over() -> bool:
    """
    Variable saying whether the game is over or not 
    """
    return database["game_over"]

def set_game_over() -> bool:
    """
    Function that ends the game
    """
    database["game_over"] = True
    return database["game_over"]

def get_all_players_in_order() -> Players:
    """
    Return all the players participating to the game by order of ranking
    
    Notes:
    -----
    In total, there are 12 players because each team has 3 players.
    """
    # Liste globale de joueur qui sera trié
    list_player = []
    
    # Loop sur les pays
    for country_players in database["players"].values():
        # Loop sur les players
        for player_data in country_players.values():
            # Récupération des paramètres du joueur
            player = Player(ID=player_data["ID"], ranking=player_data["ranking"], position=player_data["position"])
            # On l'ajoute à la liste globale
            list_player.append(player)
    
    # Triage de la liste globale sur base du classement
    sorted_players = sorted(list_player, key=lambda x: x.ranking)
    
    return sorted_players

def tirage_aléatoire() -> list[Card]:
    """
    Return 5 cards from the pack of card
    
    Notes
    -----
    Each card has the same probability of being drawn 
    but the draw chance takes into account the number of similar cards still in play
    """
    paquet = database["cards"]["Pack"]
    tirage = []
    
    for i in range(5):
        if paquet:
            # Calcul des probabilités 
            proba = [1 / len(paquet) for _ in paquet]
            # Tirage aléatoire pondéré en fonction des probabilités
            index = random.choices(range(len(paquet)), weights=proba)[0]
            # Retrait de la carte tirée du paquet
            carte = paquet.pop(index)
            # Ajout de la carte tirée à la liste des tirages
            tirage.append(carte)
            
        else:
            break
        
    database["cards"]["Pack"] = paquet
    return tirage

def best_card(team: Team) -> int:
    """
    Return the value of the best card of a player
    """
    max = 0
    for card in database["cards"][team]:
        if (card > max):
            max = card
    return max

def order_team_by_card() -> list[Team]:
    """
    Return an ordered list of the team based on their best card
    """
    teams = ["BEL", "ITA", "DEU", "NLD"]
    team_card = []
    for team in teams:
        top_card = best_card(team)
        team_card.append([team, top_card])
    
    ordered_teams = sorted(team_card, key=lambda x: x[1], reverse=True)
    ordered_team_names = [team[0] for team in ordered_teams]
    
    return ordered_team_names

def get_running_order():
    """
    Return the current running order
    """
    return database["running_order"]

def change_running_order_placement_phase():
    """
    Change the order of passage for the first phase (the placement of players on the map). 
    This is based on the best second card owned and the order of the players.
    """
    teams = order_team_by_card()
    new_running_order = []
    
    for team in teams:
        for player in database["running_order"]:
            if player.startswith(team):
                new_running_order.append(player)
    
    database["running_order"] = new_running_order
    return database["running_order"]

def change_running_order_classement_phase():
    """
    Change the pass order for the second phase (the dynamic game). 
    This is based on the player ranking.
    """
    order = get_all_players_in_order()
    new_running_order = []
    
    for player in order:
        new_running_order.append(player.ID)
    
    database["running_order"] = new_running_order
    return database["running_order"]

def query_creation(name_of_query: str) -> str:
    """
    Function creating a prolog query
    
    Notes
    -----
    
    """
    current_team = database["current_team"]
    players = get_all_players_in_order()
    cards = get_cards(current_team[0])
    
    players_str = "["
    for player in players:
        team = player.ID[:3]
        id = player.ID[4:]
        x, y = player.position
        players_str += f"[{team}, {id}, {x}, {y}], "
    players_str = players_str.rstrip(', ') 
    players_str += "]"
    
    # Construction de la requête Prolog
    query = "{}([{},{}], {}, {},[X, Y, C]).".format(name_of_query, current_team[0], current_team[1], cards, players_str)
    return query