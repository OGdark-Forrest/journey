# main.py
from fastapi import FastAPI
import uvicorn

from .serverAlgo import router as AlgoRouter
from .serverDB import router as DBRouter
from .serverRec import router as AIRouter

app = FastAPI()
app.include_router(AlgoRouter)
app.include_router(DBRouter)
app.include_router(AIRouter)

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)