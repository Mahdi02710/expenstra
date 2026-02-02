from typing import Any

from fastapi import Depends, Header, HTTPException, status

from .config import get_settings
from .firebase import get_firestore_client, verify_id_token


def _parse_bearer(authorization: str | None) -> str:
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Authorization header",
        )
    return token


def get_current_user(
    authorization: str | None = Header(default=None),
) -> dict[str, Any]:
    id_token = _parse_bearer(authorization)
    decoded = verify_id_token(id_token)

    settings = get_settings()
    db = get_firestore_client()
    user_doc = db.collection(settings.admin_collection).document(decoded["uid"]).get()
    user_meta = user_doc.to_dict() if user_doc.exists else {}

    status_value = user_meta.get(settings.admin_status_field, "active")
    if status_value == "blocked":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User is blocked",
        )

    decoded["role"] = user_meta.get(settings.admin_role_field, "user")
    decoded["status"] = status_value
    return decoded


def require_admin(user: dict[str, Any] = Depends(get_current_user)) -> dict[str, Any]:
    is_admin_claim = user.get("admin") is True
    is_admin_role = user.get("role") == "admin"
    if not (is_admin_claim or is_admin_role):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return user
