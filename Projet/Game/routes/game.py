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

@router.get("/tirage_carte")
def tirage_carteITA(request: Request):
    
    # Passage au joueur suivant
    
    cards = service.tirage_aléatoire()
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    
    return templates.TemplateResponse(
        "card_draw_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.post("/human_choice")
def human_choice(request: Request):
    return 0

@router.post("/IA_choice")
def IA_choice(request: Request):
    return 0