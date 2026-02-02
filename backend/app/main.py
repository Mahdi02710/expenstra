from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import get_settings
from .core.firebase import initialize_firebase
from .routers import admin, sync


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title=settings.api_title, version=settings.api_version)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(sync.router)
    app.include_router(admin.router)

    @app.on_event("startup")
    def _startup() -> None:
        initialize_firebase()

    return app


app = create_app()
