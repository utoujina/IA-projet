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
    
    new_counter = service.modify_counter(service.get_counter() + 1)
    print("Counter : " + str(new_counter))

    if(new_counter < 4):
        # Phase 1 : On tire les cartes pour les 4 équipes
        # On passe à l'équipe suivante
        ordre = ["ITA", "NLD", "BEL", "DEU"]
        next_team = ordre[new_counter % 4]
        service.modify_current_team(next_team)
        
        return RedirectResponse(url="/game/tirage_carte")
    
    else:
        # Phase 2 : Les équipes font fassent aux choix
        
        # La partie n'est pas finie
        if (not(service.is_game_over())):
            
            # Définition de l'odre des joueurs pour la phase de placement des joueurs sur la catre
            if(new_counter == 4):
                service.change_running_order_placement_phase()
                print("MAJ BEST")
            
            # Définiiotn de l'ordre des joueurs pour la phase qui se base sur le classement
            # Donc on passe par là tous les 12 tours pour mettre à jour le classement
            if(new_counter > 15 and (new_counter-4)%12 == 0):
                # (new_counter-4) % 16 == 0
                service.change_running_order_classement_phase()
                print("MAJ CLASSEMENT")
                
            # On récupère l'odre de jeu
            ordre = service.get_running_order()
            
            # Changement du prochain joueur
            next_tour = ordre[(new_counter-4) % 12]
            service.modify_current_team(next_tour[:3])
            service.modify_current_player(int(next_tour[4:]))
            
            next_team = service.get_current_team()
            
            # Le joueur n'a plus de cartes
            if(len(service.get_cards(next_team[0])) == 0 ):
                return RedirectResponse(url="/game/tirage_carte")
            
            # Le joueur est une IA
            elif(service.get_player_type(next_team[0]) == "IA"):
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
        service.push_card(current_team[0], card)
        
    return templates.TemplateResponse(
        "card_draw_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.get("/game/Human_choice")
def human_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    
    return templates.TemplateResponse(
        "Human_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.get("/game/IA_choice")
def IA_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    query = service.query_creation("ia1")
    
    return templates.TemplateResponse(
        "IA_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'query': query}
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
    
    current_team = service.get_current_team()
    
    service.modify_pos(current_team[0], current_team[1], [int(card), int(case)])
    service.pop_card(current_team[0], int(card))
    
    return 1


@router.post("/IA_choice")
async def submit_IA_choice(request: Request, card: str = Form(...), case: str = Form(...)):
    
    current_team = service.get_current_team()
    
    service.modify_pos(current_team[0], current_team[1], [int(card), int(case)])
    service.pop_card(current_team[0], int(card))
    
    return 1