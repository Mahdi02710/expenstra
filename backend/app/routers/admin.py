from fastapi import APIRouter, Depends, HTTPException

from ..core.security import require_admin
from ..models.admin import AdminSummary, UserSummary
from ..services.firestore import aggregate_counts, list_users, set_user_status

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/users", response_model=list[UserSummary])
def get_users(_admin=Depends(require_admin)):
    return [UserSummary(**user) for user in list_users()]


@router.get("/summary", response_model=AdminSummary)
def get_summary(_admin=Depends(require_admin)):
    return AdminSummary(**aggregate_counts())


@router.post("/user/{uid}/status")
def update_user_status(uid: str, status: str, _admin=Depends(require_admin)):
    if status not in {"active", "blocked"}:
        raise HTTPException(status_code=400, detail="Invalid status value")
    set_user_status(uid, status)
    return {"uid": uid, "status": status}
