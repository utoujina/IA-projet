from fastapi import APIRouter, HTTPException, Request, Form
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse, RedirectResponse
import Game.service.game as service

router = APIRouter(tags=["Game"])
templates = Jinja2Templates(directory="templates")

@router.get('/')
def display_home_page(request: Request):
    return templates.TemplateResponse(
        "parameters_page.html",
        context={'request': request}
    )


@router.post("/")
async def submit_choices(request: Request, BEL: str = Form(...), ITA: str = Form(...), DEU: str = Form(...), NLD: str = Form(...)):
    
    service.modify_player_type("BEL", BEL)
    service.modify_player_type("ITA", ITA)
    service.modify_player_type("DEU", DEU)
    service.modify_player_type("NLD", NLD)
    
    players = service.get_all_players_in_order()
    current_team = service.get_current_team()
    
    return templates.TemplateResponse(
        "basic_home_page.html",
        context={'request': request, 'players': players, 'current_team': current_team}
    )