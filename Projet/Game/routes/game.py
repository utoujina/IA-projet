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
    next_team = ordre[new_counter % 4]
    service.modify_current_team(next_team)
    
    if(new_counter < 4):
        # Phase 1 : On tire les cartes pour les 4 équipes
        return RedirectResponse(url="/tirage_carte")
    else:
        # Phase 2 : Les équipes font fassent aux choix
        
        # La partie n'est pas finie
        if (not(service.is_game_over())):
            
            # Le joueur n'a plus de cartes
            if(len(service.get_cards(next_team)) == 0 ):
                return RedirectResponse(url="/tirage_carte")
            
            # Le joueur est une IA
            elif(service.get_player_type(next_team) == "IA"):
                return RedirectResponse(url="/IA_choice")
            
            # Le joueur est humain
            else:
                return RedirectResponse(url="/Human_choice")
            
        else:
            # La partie est terminée
            return RedirectResponse(url="/result")
        

@router.get("/tirage_carte")
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

@router.get("/Human_choice")
def human_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team)
    
    return templates.TemplateResponse(
        "Human_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.get("/IA_choice")
def IA_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team)
    
    return templates.TemplateResponse(
        "IA_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.get("/result")
def game_result(request: Request):
    
    players = service.get_all_players_in_order()
    
    return templates.TemplateResponse(
        "result_phase.html",
        context={'request': request, 'players': players}
    )