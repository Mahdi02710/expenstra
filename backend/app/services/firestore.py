from typing import Any

from firebase_admin import auth

from ..core.config import get_settings
from ..core.firebase import get_firestore_client


def get_user_doc(uid: str) -> dict[str, Any]:
    settings = get_settings()
    db = get_firestore_client()
    doc = db.collection(settings.admin_collection).document(uid).get()
    return doc.to_dict() if doc.exists else {}


def set_user_status(uid: str, status: str) -> None:
    settings = get_settings()
    db = get_firestore_client()
    db.collection(settings.admin_collection).document(uid).set(
        {settings.admin_status_field: status},
        merge=True,
    )


def list_users() -> list[dict[str, Any]]:
    settings = get_settings()
    db = get_firestore_client()
    results: list[dict[str, Any]] = []

    page = auth.list_users()
    for user in page.users:
        meta = db.collection(settings.admin_collection).document(user.uid).get()
        meta_data = meta.to_dict() if meta.exists else {}
        results.append(
            {
                "uid": user.uid,
                "email": user.email,
                "role": meta_data.get(settings.admin_role_field, "user"),
                "status": meta_data.get(settings.admin_status_field, "active"),
            }
        )
    return results


def aggregate_counts() -> dict[str, int]:
    settings = get_settings()
    db = get_firestore_client()
    users = list_users()
    transactions_count = 0
    wallets_count = 0
    budgets_count = 0
    for user in users:
        uid = user["uid"]
        transactions_count += (
            db.collection(settings.admin_collection)
            .document(uid)
            .collection("transactions")
            .count()
            .get()[0][0].value
        )
        wallets_count += (
            db.collection(settings.admin_collection)
            .document(uid)
            .collection("wallets")
            .count()
            .get()[0][0].value
        )
        budgets_count += (
            db.collection(settings.admin_collection)
            .document(uid)
            .collection("budgets")
            .count()
            .get()[0][0].value
        )
    return {
        "usersCount": len(users),
        "transactionsCount": transactions_count,
        "walletsCount": wallets_count,
        "budgetsCount": budgets_count,
    }
