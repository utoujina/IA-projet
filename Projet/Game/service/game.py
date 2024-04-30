from typing import Tuple
from Game.schemas.player import Player, Card, Type, Team, Players
from Game.database import database

def get_pos(Team: str, ID: int) -> Tuple[int, int]:
    """
    Return the position of a player
    """
    return database["players"][Team][ID]

def modify_pos(Team: str, ID: int, New_pos: Tuple[int, int]) -> Player:
    """
    Modify the position of a player
    """
    database["players"][Team][ID]["position"] = New_pos
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

    
def get_cards(Team: str) -> Card:
    """
    Return the set of cards of the player
    """
    return database["cards"][Team]

def push_card(Team: str, value: int) -> Card:
    """
    Add a card, and return the set of cards of the player containning the new card
    """
    database["cards"][Team].add(value)
    return database["cards"][Team]

def pop_card(Team: str, value: int) -> Card:
    """
    Delete the card, and return the set of card without the card
    """
    database["cards"][Team].discard(value)
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
    database["current_team"] = New_team
    return database["current_team"]

def get_all_players_in_order() -> Players:
    """
    Return all the players participating to the game by order of ranking
    
    Notes:
    -----
    In total, there are 12 players because each team has 3 players.
    """
    list_player = []
    for country_players in database["players"].values():
        for player_data in country_players.values():
            player = Player(ID=player_data["ID"], ranking=player_data["ranking"], position=player_data["position"])
            list_player.append(player)
    
    # On trie les joueur par classement
    sorted_players = sorted(list_player, key=lambda x: x.ranking)
    
    return sorted_players