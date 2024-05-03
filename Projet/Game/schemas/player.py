from typing import Literal, Tuple, Dict
from pydantic import BaseModel, Field

class Player(BaseModel):
    """
    A class representing a player.
    
    Attributes
    ----------
    ID: str
    ranking: int
    position: Tuple[int, int]
    
    Notes
    -----
    In total, there are 12 players because each team has 3 players.
    """
    ID: str
    ranking: int = Field(ge=1, le=12)
    position: Tuple[int, int]

class Players(BaseModel):
    """
    A class representing all the players in the game
    """
    players: Dict[str, Dict[int, Player]]

class Card(BaseModel):
    """
    A class representing a set of cards.
    
    Notes
    -----
    There are 112 possible cards (8 times cards from 1 to 12).
    """
    cards: list[int]
    
class Cards(BaseModel):
    """
    A class representing cards for each country.
    """
    Pack: set[int] = Field(max_length = 96)
    BEL: Card
    DEU: Card
    NDL: Card
    ITA: Card
    
class Type(BaseModel):
    """
    A class representing the type of a player
    """
    type: Literal["Human", "IA"]

class Types(BaseModel):
    """
    A class representing cards for each country.
    """
    BEL: Type
    DEU: Type
    NDL: Type
    ITA: Type
    
class Team(BaseModel):
    """
    A class representing the different teams
    """
    team: Literal["BEL", "DEU", "NLD", "ITA"]
    
class Counter(BaseModel):
    """
    A class repreenting a counter of lap.
    """
    counter: int