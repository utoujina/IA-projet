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
    
    service.update_ranking()
    new_counter = service.modify_counter(service.get_counter() + 1)
    print("Counter : " + str(new_counter))
    
    if(new_counter < 4):
        # Phase 1 : On tire les cartes pour les 4 équipes
        # On passe à l'équipe suivante
        ordre = ["ITA", "NLD", "BEL", "DEU"]
        next_team = ordre[new_counter % 4]
        service.modify_current_team(next_team, 0)
        
        return RedirectResponse(url="/game/tirage_carte")
    
    else:
        # Phase 2 : Les équipes font fassent aux choix

        # La partie n'est pas finie
        if (not(service.is_game_over())):
            
            # Définition de l'odre des joueurs pour la phase de placement des joueurs sur la catre
            if(new_counter == 4):
                service.change_running_order_placement_phase()
                print("MAJ BEST")
            
            # On passe par ici tous les 12 tours
            if(new_counter > 15 and (new_counter-4)%12 == 0):
                    
                    # Mise à jour de l'ordre des joueurs en fonction du classement
                    service.change_running_order_classement_phase()
                    print("MAJ CLASSEMENT")
                
            # On récupère l'odre de jeu
            ordre = service.get_running_order()

            # Changement du prochain joueur
            next_tour = ordre[(new_counter-4) % 12]
            team = [next_tour[:3], int(next_tour[4:])]
            service.modify_current_team(team[0], team[1])
            
            # Le joueur passe son tour
            if(service.get_pos(team[0], team[1])[1] == -1):
                return RedirectResponse(url="/game/passe_tour")
            
            # Le joueur est une IA
            elif(service.get_player_type(team[0]) == "IA"):
                return RedirectResponse(url="/game/ia_choice")
            
            # Le joueur est humain
            else:
                return RedirectResponse(url="/game/human_choice")
            
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

@router.get("/game/human_choice")
def human_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    pos = service.get_pos(current_team[0], current_team[1])
    
    return templates.TemplateResponse(
        "human_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'pos': pos}
    )

@router.get("/game/ia_choice")
def IA_choice(request: Request):
    
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    query = service.query_creation("ia1")
        
    return templates.TemplateResponse(
        "ia_game_phase.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'query': query}
    )

@router.get("/game/result")
def game_result(request: Request):
    
    players = service.get_all_players_in_order()
    
    return templates.TemplateResponse(
        "result_phase.html",
        context={'request': request, 'players': players}
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
    
    if(type_player == "Human"):
        return templates.TemplateResponse(
            "human_chute.html",
            context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
        )
    else:
        query = service.query_creation("ia1_defausse")
        print(query)
        return templates.TemplateResponse(
            "ia_chute.html",
            context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'query': query}
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
    
    return templates.TemplateResponse(
        "passe_tour.html",
        context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
    )

@router.get("/game/chance")
def case_chance(request: Request):
    current_team = service.get_current_team()
    players = service.get_all_players_in_order()
    cards = service.get_cards(current_team[0])
    type_player = service.get_player_type(current_team[0])
    
    if(type_player == "Human"):
        return templates.TemplateResponse(
            "human_chance.html",
            context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards}
        )
    
    else:
        query = service.query_creation("ia1_defausse")
        
        return templates.TemplateResponse(
            "ia_chance.html",
            context={'request': request, 'players': players, 'current_team': current_team, 'cards': cards, 'query': query}
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
        
        # Le joueur n'a plus de cartes
        if(len(service.get_cards(current_team[0])) == 0 ):
            return RedirectResponse(url="/game/tirage_carte")
        
        # Le joueur est tombé
        elif(service.get_pos(current_team[0], current_team[1])[1] == -2):
            service.modify_pos(current_team[0], current_team[1], [service.get_pos(current_team[0], current_team[1])[0], -1])
            return RedirectResponse(url="/game/chute")
        
        # Le joueur est sur une case chance
        elif(service.is_chance_case(service.get_pos(current_team[0], current_team[1]))):
            return RedirectResponse(url="/game/chance")
        
    return RedirectResponse(url="/game")