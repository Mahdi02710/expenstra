from typing import Optional

from pydantic import Field, validator

from .base import APIModel


class WalletIn(APIModel):
    id: str
    name: str
    balance: float
    type: str
    icon: str
    color: str
    accountNumber: Optional[str] = None
    bankName: Optional[str] = None
    creditLimit: Optional[float] = None
    isActive: bool = True
    createdAt: Optional[int] = None
    lastTransactionDate: Optional[int] = None
    isMonthlyRollover: bool = False
    rolloverToWalletId: Optional[str] = None
    lastRolloverAt: Optional[int] = None
    updatedAt: Optional[int] = None

    @validator("type")
    def validate_type(cls, value: str) -> str:
        allowed = {"bank", "savings", "credit", "cash", "investment"}
        if value not in allowed:
            raise ValueError("Invalid wallet type")
        return value


class WalletSyncRequest(APIModel):
    items: list[WalletIn]
    lastSync: Optional[int] = None


class WalletSyncResponse(APIModel):
    upserts: list[WalletIn]
    serverTime: int
