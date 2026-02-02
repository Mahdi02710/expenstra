from pydantic import BaseModel


class APIModel(BaseModel):
    class Config:
        extra = "forbid"
