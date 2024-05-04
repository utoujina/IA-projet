from fastapi import APIRouter, HTTPException, Request, Form
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, RedirectResponse
import Game.service.game as service
import time

router = APIRouter(tags=["Game"])
templates = Jinja2Templates(directory="templates")

@router.get('/')
def display_setup_phase(request: Request):
    return templates.TemplateResponse(
        "setup_phase.html",
        context={'request': request}
    )


@router.post("/")
async def submit_choices_setup(request: Request, BEL: str = Form(...), ITA: str = Form(...), DEU: str = Form(...), NLD: str = Form(...)):
    
    service.modify_player_type("BEL", BEL)
    service.modify_player_type("ITA", ITA)
    service.modify_player_type("DEU", DEU)
    service.modify_player_type("NLD", NLD)
    
    players = service.get_all_players_in_order()
    current_team = service.get_current_team()
    
    return templates.TemplateResponse(
        "introduction_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team}
    )

@router.get("/game")
def game(request: Request):
    
    ordre = ["ITA", "NLD", "BEL", "DEU"]
    new_counter = service.modify_counter(service.get_counter() + 1)
    
    print("Counter : " + str(new_counter))
    
    next_team = ordre[new_counter % 4]
    service.modify_current_team(next_team)
    
    if(new_counter < 4):
        # Phase 1 : On tire les cartes pour les 4 équipes
        return RedirectResponse(url="/game/tirage_carte")
    else:
        # Phase 2 : Les équipes font fassent aux choix
        
        # La partie n'est pas finie
        if (not(service.is_game_over())):
            
            # Le joueur n'a plus de cartes
            if(len(service.get_cards(next_team)) == 0 ):
                return RedirectResponse(url="/game/tirage_carte")
            
            # Le joueur est une IA
            elif(service.get_player_type(next_team) == "IA"):
                return RedirectResponse(url="/game/IA_choice")
            
            # Le joueur est humain
            else:
                return RedirectResponse(url="/game/Human_choice")
            
        else:
            # La partie est terminée
            return RedirectResponse(url="/game/result")
        

@router.get("/game/tirage_carte")
def tirage_carte(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    
    # Tirage des cartes
    cards = service.tirage_aléatoire()
    
    # Ajout aux cartes du joueur
    for card in cards:
        service.push_card(current_team, card)
        
    return templates.TemplateResponse(
        "card_draw_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.get("/game/Human_choice")
def human_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team)
    
    return templates.TemplateResponse(
        "Human_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.get("/game/IA_choice")
def IA_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team)
    
    return templates.TemplateResponse(
        "IA_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.get("/game/result")
def game_result(request: Request):
    
    players = service.get_all_players_in_order()
    
    return templates.TemplateResponse(
        "result_phase.html",
        context={'request': request, 'players': players}
    )

@router.post("/Human_choice")
async def submit_human_choice(request: Request, card: str = Form(...), case: str = Form(...)):
    
    card = int(card)
    case = int(case)
    
    print(card)
    print(case)
    
    current_team = service.get_current_team()
    
    print(service.get_pos(current_team,3))
    
    service.modify_pos(current_team, 3, [card, case])
    
    print(service.get_pos(current_team,3))
    
    return 1


@router.post("/IA_choice")
async def submit_IA_choice(request: Request):
    
    return RedirectResponse(url="/game", status_code=303)