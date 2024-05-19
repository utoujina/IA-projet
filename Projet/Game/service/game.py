from Game.schemas.player import Player, Card, Type, Team, Players, Counter, Case, Chute
from Game.database import database
import random
from Game.database import map_positions


def couple_to_float(Couple) -> float:
    """
    Return the float of the couple
    
    Ex:
    [10, 2] -> 10.2
    """
    string = str(Couple[0]) + "." + str(Couple[1])
    return float(string)

def float_to_couple(float) -> list[int, int]:
    """
    Return the of couple of the float
    
    Ex:
    10.2 -> [10,2]
    9 -> [9,0]
    """
    if("." in str(float)):
        couple_string = str(float).split(".")
    else:
        couple_string = [float, "0"]
    return [int(couple_string[0]), int(couple_string[1])]

def get_pos(Team: str, ID: int) -> Case:
    """
    Return the position of a player
    """
    pos = database["players"][Team][ID]["position"]
    
    return float_to_couple(pos)

def modify_pos(Team: str, ID: int, New_pos: Case) -> Player:
    """
    Modify the position of a player by increasing the old position
    """
    old_pos = get_pos(Team, ID)
    new_pos = [old_pos[0] + New_pos[0], New_pos[1]]
    database["players"][Team][ID]["position"] = couple_to_float(new_pos)
    
    return database["players"][Team][ID]

def modify_straight_pos(Team: str, ID: int, New_pos: Case) -> Player:
    """
    Modify the position of a player without increasing the old position
    """
    database["players"][Team][ID]["position"] = couple_to_float(New_pos)
    
    return database["players"][Team][ID]

def modify_couloir(Team: str, ID: int, new_couloir : int) -> Player:
    """
    Modify the couloir of a player
    """
    current_pos = get_pos(Team, ID)
    new_pos = [current_pos[0], new_couloir]
    database["players"][Team][ID]["position"] = couple_to_float(new_pos)
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
    A player is either a Human, or an IA (ia1 or ia2)
    """
    return database["type"][Team]

def modify_player_type(Team: str, New_type: str) -> Type:
    """
    Modify the type of a player
    
    Notes
    -----
    A player is either a Human, or an IA (ia1 or ia2)
    """
    database["type"][Team] = New_type
    return database["type"][Team]

def get_current_map_positions() -> list:
    return map_positions

def get_current_team() -> list[Team, int]:
    """
    Get the current player
    
    Notes
    -----
    It is either BEL, DEU, NLD or ITA.
    """
    return database["current_team"]

def modify_current_team(new_team: Team, id_player: int) -> Team:
    """
    Modify the team that is currently playing 
    
    Notes
    -----
    It is either BEL, DEU, NLD or ITA.
    """
    database["current_team"] = [new_team, id_player]
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
    Function saying whether the game is over or not
    
    Notes
    -----
    The game is over if there are no more cards in the main deck
    or if a player has reached the last case
    """
    if (len(database["cards"]["Pack"]) == 0):
        return True
    
    else:
        return is_player_on_or_above_105()

def is_player_on_or_above_105():
    """
    Function checking if a player is above the 105 case
    Return true if yes, false otherwise
    """
    for team, players in database["players"].items():
        for player_id, player_info in players.items():
            position = player_info["position"]
            if position >= 105:
                return True
    return False

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
            couloir = ""
            if round(player_data["position"] - int(player_data["position"]), 1) == 0:
                couloir = "Gauche"
            elif round(player_data["position"] - int(player_data["position"]), 1) == 0.1:
                couloir = "Milieu"
            elif round(player_data["position"] - int(player_data["position"]), 1) == 0.2:
                couloir = "Droite"
            elif round(player_data["position"] - int(player_data["position"]), 1) == 0.3:
                couloir = "Bas-côté"
            elif round(player_data["position"] - int(player_data["position"]), 1) == 0.4:
                couloir = "Chute"
            else:
                couloir = "Problème"
            # Récupération des paramètres du joueur
            player = {
                "ID": player_data["ID"],
                "ranking": player_data["ranking"],
                "position": float_to_couple(float(player_data["position"])),
                "position_float": player_data["position"],
                "couloir": couloir
            }

            # On l'ajoute à la liste globale
            list_player.append(player)


    # Triage de la liste globale sur base du classement
    sorted_players = sorted(list_player, key=lambda x: x["ranking"])

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
        new_running_order.append(player["ID"])
    
    database["running_order"] = new_running_order
    return database["running_order"]

def query_creation(name_of_query: str) -> str:
    """
    Function that creates the move Prolog query
    
    Notes
    -----
    It contains : 
    - the players list
    - the cards of a player
    - the current player ID
    - the current player position
    """
    current_team = database["current_team"]
    players = get_all_players_in_order()
    cards = get_cards(current_team[0])
    current_pos = get_pos(current_team[0], current_team[1])
    
    players_str = "["
    for player in players:
        print(player)
        team = player["ID"][:3]
        id = player["ID"][4:]
        x, y = player["position"]
        rank = player["ranking"]
        players_str += f"[{rank}, '{team}', {id}, {x}, {y}], "
    players_str = players_str.rstrip(', ') 
    players_str += "]"
    
    # Construction of the Prolog query
    query = "{}([{},{}], ['{}', {}], [{}, {}] ,[Case, Card]).".format(name_of_query, players_str, cards, current_team[0], current_team[1], current_pos[0], current_pos[1])
    return query

def query_creation_chance(name_of_query: str) -> str:
    """
    Function that creates the chance Prolog query.
    
    Notes
    -----
    It contains : 
    - the players list
    - the cards of a player
    - the current player ID
    - the chance card
    - the current player card
    """
    current_team = database["current_team"]
    players = get_all_players_in_order()
    cards = get_cards(current_team[0])
    current_pos = get_pos(current_team[0], current_team[1])
    
    players_str = "["
    for player in players:
        team = player["ID"][:3]
        id = player["ID"][4:]
        x, y = player["position"]
        rank = player["ranking"]
        players_str += f"[{rank}, '{team}', {id}, {x}, {y}], "
    players_str = players_str.rstrip(', ') 
    players_str += "]"
    
    # Construction of the Prolog query
    query = "{}(['{}',{}], {}, {}, {}, Chance_card, Couloir).".format(name_of_query, current_team[0], current_team[1], current_pos[0], players_str, cards)
    return query

def query_creation_defausse(name_of_query: str) -> str:
    """
    Function that creates the defausse Prolog query.
    
    Notes
    -----
    It contains : 
    - the players cards
    """
    current_team = database["current_team"]
    cards = get_cards(current_team[0])
    
    # Construction of the Prolog query
    query = "{}({}, Card).".format(name_of_query, cards)
    return query

def update_ranking():
    """
    Update the ranking thanks to the players position
    """
    
    all_players = []

    for team in database['players']:
        for player_id, player_info in database['players'][team].items():
            all_players.append(player_info)

    # Sort players according to the coordinate of their square (position[0])
    sorted_players = sorted(all_players, key=lambda x: x['position'], reverse=True)

    # Update the ranking of players in the database
    for i, player in enumerate(sorted_players, 1):
        database["players"][player['ID'][:3]][int(player['ID'][4:])]['ranking'] = i

    return 1

def is_occupied(case: Case) -> bool:
    """
    Return true if a case is arleady occupied, false otherise
    """
    for team in database['players']:
        
        for id in database['players'][team]:

            if (get_pos(team, id) == case):
                return True
    return False

def couloir_is_occupied(num_case: int) -> bool:
    """
    Return true if the couloir is occupied
    """
    if(is_occupied([num_case, 0]) and is_occupied([num_case, 1]) and is_occupied([num_case, 2])):
        return True
    else:
        return False
    
def is_chance_case(case: Case) -> bool:
    """
    Return true if it is a chance case, false otherwise
    """
    chance_cases = [[9, 0], [10,0], [11,0], [12,0], [15,2], [16,2], [19,2], [21,2], [24,0], [26,0], [28,0], [30,0], [32,0], [34,0], [48,0], [57,2], [66,0], [66,2], [74,0]]
    return list(case) in chance_cases

def get_chance() -> int:
    return random.randint(-3, 3)

def check_chute(current_case: Case, new_couloir: int, card: Card) -> int:
    """
    Return the value of the case if there is a chute, -1 otherwise
    """
    new_case = [current_case[0] + card, new_couloir]
    
    if (is_occupied(new_case)):
        return new_case[0]
    
    else:
        for i in range(current_case[0] - card, new_case[0]):
            if (couloir_is_occupied(i)):
                return i
    return -1

def apply_chute(nb_case: int, player: list[Team, int]):
    """
    Apply a chute
    """
    players = get_all_players_in_order()
    for player in players:
        
        if player["position"][0] == nb_case:
            modify_straight_pos(player["ID"][:3], int(player["ID"][4:]), [nb_case, 4])
            

def get_chute() -> Chute:
    """
    Returning the variable chute
    """
    return database["chute"]

def modify_chute(new_chute: Chute) -> Chute:
    """
    Modifyign the variable chute
    """
    database["chute"] = new_chute
    return database["chute"]


def get_final_classement_team():
    """
    Return the final classement based on the cumulative time of the teams
    """
    players = get_all_players_in_order()
    
    scores = {"BEL": 0, "DEU": 0, "NLD": 0, "ITA": 0}
    team_players = {"BEL": [], "DEU": [], "NLD": [], "ITA": []}
    
    for player in players:
        team_code = player["ID"][:3]
        scores[team_code] += player["ranking"]
        team_players[team_code].append(player)
    
    sorted_scores = sorted(scores.items(), key=lambda x: x[1])
    
    sorted_players = []
    for team, _ in sorted_scores:
        team_players[team].sort(key=lambda x: x["ranking"])
        sorted_players.extend(team_players[team])
    
    return sorted_players

def get_winner_team():
    """
    Return the winner team
    """
    player = get_final_classement_team()    
    return player[0]["ID"][:3]
