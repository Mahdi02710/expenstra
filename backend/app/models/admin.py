from typing import Optional

from .base import APIModel


class UserSummary(APIModel):
    uid: str
    email: Optional[str] = None
    role: str = "user"
    status: str = "active"


class AdminSummary(APIModel):
    usersCount: int
    transactionsCount: int
    walletsCount: int
    budgetsCount: int
