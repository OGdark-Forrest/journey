from fastapi import FastAPI
import uvicorn

from .serverAlgo import router as AlgoRouter
from .serverDB import router as DBRouter

app = FastAPI()

app.include_router(AlgoRouter)
app.include_router(DBRouter)

uvicorn.run(app)