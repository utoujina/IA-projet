from typing import Literal, Tuple, Dict
from pydantic import BaseModel, Field


class Case(BaseModel):
    """
    A class representing a case

    Notes
    -----
    [number_of_the_case, couloir] where couloir is 0, 1 or 2
    0 = gauche
    1 = milieu
    2 = droite
    -1 = sur le coté
    """
    case: Tuple[int, int]


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
    ranking: int = Field(ge=0, le=12)
    position: float
    couloir: str


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
    Pack: set[int] = Field(max_length=96)
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


class Running_order(BaseModel):
    """
    A class representing the order of passage of players in the game.

    Notes
    -----
    It can be determined by the best second card owned or by the ranking of players.
    """
    running_order: list[str]


class Chute(BaseModel):
    """
    A class reprenting the fact that there is a chute

    Notes
    -----
    chute[0] = is there a chute
    chute[1] = case of the chute
    """
    chute: Tuple[bool, int]