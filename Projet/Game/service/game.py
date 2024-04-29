from typing import Tuple
from Game.schemas.player import Player, Card, Type
from Game.database import database

def get_pos(Team: str, ID: int) -> Tuple[int, int]:
    """
    Return the position of a player
    """
    return database[Team]["players"][ID]["position"]

def modify_pos(Team: str, ID: int, New_pos: Tuple[int, int]) -> Player:
    """
    Modify the position of a player
    """
    database[Team]["players"][ID]["position"] = New_pos
    return database[Team]["players"][ID]
    

def get_ranking(Team: str, ID: int) -> int:
    """
    Return the ranking of a player
    """
    return database[Team]["players"][ID]["ranking"]

def modify_ranking(Team: str, ID: int, New_rank: int) -> Player:
    """
    Modify the ranking of a player
    """
    database[Team]["players"][ID]["ranking"] = New_rank
    return database[Team]["players"][ID]

    
def get_cards(Team: str) -> Card:
    """
    Return the set of cards of the player
    """
    return database[Team]["cards"]

def push_card(Team: str, value: int) -> Card:
    """
    Add a card, and return the set of cards of the player containning the new card
    """
    database[Team]["cards"].add(value)
    return database[Team]["cards"]

def pop_card(Team: str, value: int) -> Card:
    """
    Delete the card, and return the set of card without the card
    """
    database[Team]["cards"].discard(value)
    return database[Team]["cards"]

def get_player_type(Team: str) -> Type:
    """
    Return the type of a player
    
    Notes
    -----
    A player is either a Human, or an IA
    """
    return database[Team]["type"]

def modify_player_type(Team: str, New_type: str) -> Type:
    """
    Modify the type of a player
    
    Notes
    -----
    A player is either a Human, or an IA
    """
    database[Team]["type"] = New_type
    return database[Team]["type"]