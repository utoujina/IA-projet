from typing import Literal, Tuple, Dict, Set
from pydantic import BaseModel, Field

class Player(BaseModel):
    """
    A class representing a player.
    
    Attributes
    ----------
    ranking: int
    position: Tuple[int, int]
    
    Notes
    -----
    In total, there are 12 players because each team has 3 players.
    """
    ranking: int = Field(ge=1, le=12)
    position: Tuple[int, int]

class Card(BaseModel):
    """
    A class representing a set of cards.
    
    Notes
    -----
    There are 112 possible cards (8 times cards from 1 to 12).
    """
    cards: set[int] = Field(max_length = 10)
    
class Cards(BaseModel):
    """
    A class representing cards for each country.
    """
    BEL: Card
    DEU: Card
    NDL: Card
    ITA: Card
    
class Type(BaseModel):
    """
    A class representing the type of a player
    """
    type: Literal["Human", "IA"]
        
class Country(BaseModel):
    """
    A class representing a country's data in the database.
    """
    players: Dict[int, Player]
    cards: Set[int]
    type: Type

class Database(BaseModel):
    """
    A class representing the entire database.
    """
    BEL: Country
    DEU: Country
    NLD: Country
    ITA: Country