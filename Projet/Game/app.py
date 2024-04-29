from fastapi import FastAPI
from fastapi.templating import Jinja2Templates
from fastapi.exceptions import RequestValidationError
from fastapi.staticfiles import StaticFiles

from Game.routes.game import router as game_router

app = FastAPI(title="Books")
app.include_router(game_router)
app.mount("/static", StaticFiles(directory="../Projet/static"), name="static")
templates = Jinja2Templates(directory="templates")

@app.on_event('startup')
def on_startup():
    print("Server started.")


def on_shutdown():
    print("Bye bye!")