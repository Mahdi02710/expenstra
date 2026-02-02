from typing import List, Optional

from pydantic import Field, validator

from .base import APIModel


class BudgetIn(APIModel):
    id: str
    name: str
    spent: float = 0
    limit: float = Field(gt=0)
    icon: str
    color: str
    period: str
    category: str
    startDate: int
    endDate: int
    isActive: bool = True
    alertThreshold: Optional[float] = None
    includedCategories: Optional[List[str]] = None
    createdAt: Optional[int] = None
    updatedAt: Optional[int] = None

    @validator("period")
    def validate_period(cls, value: str) -> str:
        allowed = {"weekly", "monthly", "yearly"}
        if value not in allowed:
            raise ValueError("Invalid budget period")
        return value


class BudgetSyncRequest(APIModel):
    items: list[BudgetIn]
    lastSync: Optional[int] = None


class BudgetSyncResponse(APIModel):
    upserts: list[BudgetIn]
    serverTime: int
