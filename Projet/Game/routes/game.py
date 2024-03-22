from fastapi import APIRouter, HTTPException, Request
from fastapi.templating import Jinja2Templates


router = APIRouter(tags=["Game"])
templates = Jinja2Templates(directory="templates")

@router.get('/')
def display_home_page(request: Request):
    return templates.TemplateResponse(
        "HomePageGame.html",
        context={'request': request}
    )
