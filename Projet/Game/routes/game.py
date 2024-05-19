from fastapi import APIRouter, HTTPException, Request, Form
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, RedirectResponse
import Game.service.game as service

router = APIRouter(tags=["Game"])
templates = Jinja2Templates(directory="templates")

@router.get('/')
def display_setup_phase(request: Request):
    
    return templates.TemplateResponse(
        "setup_phase.html",
        context={'request': request}
    )


@router.post("/")
async def submit_choices_setup(request: Request, BEL: str = Form(...), ITA: str = Form(...), DEU: str = Form(...),
                               NLD: str = Form(...)):
    service.modify_player_type("BEL", BEL)
    service.modify_player_type("ITA", ITA)
    service.modify_player_type("DEU", DEU)
    service.modify_player_type("NLD", NLD)

    players = service.get_all_players_in_order()
    current_team = service.get_current_team()
    map_positions = service.get_current_map_positions()

    return templates.TemplateResponse(
        "introduction_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'map_positions': map_positions}
    )


@router.get("/game")
def game(request: Request):

    service.update_ranking()
    new_counter = service.modify_counter(service.get_counter() + 1)
    
    print("Counter : " + str(new_counter))
    
    # Phase 1 : Draw cards for all 4 teams
    if(new_counter < 4):
        
        ordre = ["ITA", "NLD", "BEL", "DEU"]
        next_team = ordre[new_counter % 4]
        service.modify_current_team(next_team, 0)
        
        return RedirectResponse(url="/game/tirage_carte")
    
    # Phase 2 : Teams make choices
    else:
        
        # The game is not over
        if (not(service.is_game_over())):
            
            # Definition of the players' odre for the placement phase of the players on the catre
            if(new_counter == 4):
                service.change_running_order_placement_phase()
                print("MAJ BEST")
            
            # We go through here every 12 laps
            if(new_counter > 15 and (new_counter-4)%12 == 0):
                    
                    # Update the order of players according to the ranking
                    service.change_running_order_classement_phase()
                    print("MAJ CLASSEMENT")
                
            # We get the game odre
            ordre = service.get_running_order()

            # # We move on to the next player
            next_tour = ordre[(new_counter-4) % 12]
            team = [next_tour[:3], int(next_tour[4:])]
            service.modify_current_team(team[0], team[1])
            
            # The player passes his turn
            if(service.get_pos(team[0], team[1])[1] == 3):
                return RedirectResponse(url="/game/passe_tour")
            
            # The player fell because of another player
            elif(service.get_pos(team[0], team[1])[1] == 4):
                service.modify_pos(team[0], team[1], [service.get_pos(team[0], team[1])[0], 3])
                return RedirectResponse(url="/game/chute")
            
            # The player is an AI
            elif(service.get_player_type(team[0]) == "Human"):
                return RedirectResponse(url="/game/human_choice")
            
            # The player is human
            else:
                return RedirectResponse(url="/game/ia_choice")
            
        else:
            # The game is over
            return RedirectResponse(url="/game/result")
        

@router.get("/game/tirage_carte")
def tirage_carte(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    map_positions = service.get_current_map_positions()
    
    # Drawing cards
    cards = service.tirage_aléatoire()
    
    # Adding cards to the player
    for card in cards:
        service.push_card(current_team[0], card)
        
    return templates.TemplateResponse(
        "card_draw_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'map_positions': map_positions}
    )

@router.get("/game/human_choice")
def human_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    pos = service.get_pos(current_team[0], current_team[1])
    map_positions = service.get_current_map_positions()
    
    return templates.TemplateResponse(
        "human_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'pos': pos, 'map_positions': map_positions}
    )

@router.get("/game/ia_choice")
def IA_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    type_player = service.get_player_type(current_team[0])
    map_positions = service.get_current_map_positions()

    
    query = service.query_creation(type_player)
    print(query)
    return templates.TemplateResponse(
        "ia_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'query': query, 'map_positions': map_positions}
    )

@router.get("/game/result")
def game_result(request: Request):
    
    players = service.get_final_classement_team()
    winner_team = service.get_winner_team()
    map_positions = service.get_current_map_positions()

    return templates.TemplateResponse(
        "result_phase.html",
        context={'request': request, 'players': players, 'winner': winner_team, 'map_positions': map_positions}
    )


@router.post("/choice")
async def submit_choice(request: Request, card: str = Form(...), case: str = Form(...)):
    
    current_team = service.get_current_team()
    position = service.get_pos(current_team[0], current_team[1])
    
    chute = service.check_chute(position, int(case), int(card))
    service.pop_card(current_team[0], int(card))
    service.modify_pos(current_team[0], current_team[1], [int(card), int(case)])
    
    if(chute != -1):
        service.apply_chute(chute, current_team)
        
    return 1

@router.get("/game/chute")
def chute(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    type_player = service.get_player_type(current_team[0])
    map_positions = service.get_current_map_positions()
    
    if(type_player == "Human"):
        return templates.TemplateResponse(
            "human_chute.html",
            context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'map_positions': map_positions}
        )
    else:
        query = service.query_creation_defausse("ia1_defausse")
        
        print(query)
        return templates.TemplateResponse(
            "ia_chute.html",
            context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'query': query, 'map_positions': map_positions}
        )

@router.post("/chute")
async def submit_chute_choice(request: Request, card: str = Form(...)):
    
    current_team = service.get_current_team()
    service.pop_card(current_team[0], int(card))
    
    return 1

@router.get("/game/passe_tour")
def passe_tour(request: Request):
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    service.modify_couloir(current_team[0], current_team[1], 0)
    map_positions = service.get_current_map_positions()
    
    return templates.TemplateResponse(
        "passe_tour.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'map_positions': map_positions}
    )

@router.get("/game/chance")
def case_chance(request: Request):
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    type_player = service.get_player_type(current_team[0])
    map_positions = service.get_current_map_positions()
    
    if(type_player == "Human"):
        return templates.TemplateResponse(
            "human_chance.html",
            context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'map_positions': map_positions}
        )
    
    else:
        type_player = service.get_player_type(current_team[0])
        query = service.query_creation_chance(type_player + "_chance")
        
        print(query)
        
        return templates.TemplateResponse(
            "ia_chance.html",
            context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'query': query, 'map_positions': map_positions}
        )

@router.post("/chance")
async def apply_chance(request: Request, chance_card: int = Form(...), case: int = Form(...)):
    
    current_team = service.get_current_team()
    print(current_team)
    position = service.get_pos(current_team[0], current_team[1])
    
    chute = service.check_chute(position, int(case), int(chance_card))
    service.modify_pos(current_team[0], current_team[1], [int(chance_card), int(case)])
    
    if(chute != -1):
        service.apply_chute(chute, current_team)
        
    return 1

@router.get("/intermediate_phase")
def intermediate_phase(request: Request):
    
    service.update_ranking()
    current_team = service.get_current_team()
    counter = service.get_counter()
    
    if(counter > 4):
        
        # The player has no more cards
        if(len(service.get_cards(current_team[0])) == 0 ):
            return RedirectResponse(url="/game/tirage_carte")
        
        # The player fell
        elif(service.get_pos(current_team[0], current_team[1])[1] == 4):
            service.modify_pos(current_team[0], current_team[1], [service.get_pos(current_team[0], current_team[1])[0], 3])
            return RedirectResponse(url="/game/chute")
        
        # The player is on a luck square
        elif(service.is_chance_case(service.get_pos(current_team[0], current_team[1]))):
            return RedirectResponse(url="/game/chance")
        
    return RedirectResponse(url="/game")