from typing import List, Optional

from pydantic import Field, validator

from .base import APIModel


class TransactionIn(APIModel):
    id: str
    type: str
    amount: float = Field(gt=0)
    currencyCode: str = "USD"
    originalAmount: Optional[float] = None
    exchangeRate: Optional[float] = None
    description: str
    category: str
    icon: str
    date: int
    walletId: str
    note: Optional[str] = None
    tags: Optional[List[str]] = None
    createdAt: Optional[int] = None
    updatedAt: Optional[int] = None

    @validator("type")
    def validate_type(cls, value: str) -> str:
        allowed = {"income", "expense", "transfer"}
        if value not in allowed:
            raise ValueError("Invalid transaction type")
        return value


class TransactionSyncRequest(APIModel):
    items: List[TransactionIn]
    lastSync: Optional[int] = None


class TransactionSyncResponse(APIModel):
    upserts: List[TransactionIn]
    serverTime: int
