from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth, warehouse, routes

app = FastAPI(title="VendingBackpack Mock API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth, prefix="/api", tags=["Auth"])
app.include_router(warehouse, prefix="/api", tags=["Warehouse"])
app.include_router(routes, prefix="/api", tags=["Routes"])

@app.get("/")
async def root():
    return {"message": "VendingBackpack Mock API Running"}


@app.get("/health")
async def health():
    return {"status": "ok"}
