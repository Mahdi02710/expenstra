from datetime import datetime, timezone
from typing import Any, Iterable

from ..core.firebase import get_firestore_client


def _upsert_collection(
    user_id: str,
    collection: str,
    items: Iterable[dict[str, Any]],
) -> None:
    db = get_firestore_client()
    batch = db.batch()
    server_time = int(datetime.now(tz=timezone.utc).timestamp() * 1000)
    for item in items:
        created_at = _to_millis(item.get("createdAt")) or server_time
        updated_at = _to_millis(item.get("updatedAt")) or server_time
        item["createdAt"] = created_at
        item["updatedAt"] = updated_at
        doc_ref = (
            db.collection("users")
            .document(user_id)
            .collection(collection)
            .document(item["id"])
        )
        batch.set(doc_ref, item, merge=True)
    batch.commit()


def _fetch_updates(
    user_id: str,
    collection: str,
    last_sync: int | None,
) -> list[dict[str, Any]]:
    db = get_firestore_client()
    collection_ref = (
        db.collection("users")
        .document(user_id)
        .collection(collection)
    )
    snapshots = collection_ref.stream()
    server_time = int(datetime.now(tz=timezone.utc).timestamp() * 1000)
    results: list[dict[str, Any]] = []

    for doc in snapshots:
        data = doc.to_dict() or {}
        updated_at = _to_millis(data.get("updatedAt"))
        created_at = _to_millis(data.get("createdAt"))

        if updated_at is None:
            updated_at = server_time
            doc.reference.set({"updatedAt": updated_at}, merge=True)
        if created_at is None:
            created_at = server_time
            doc.reference.set({"createdAt": created_at}, merge=True)

        if last_sync is None or (updated_at is not None and updated_at > last_sync):
            data["updatedAt"] = updated_at
            data["createdAt"] = created_at
            results.append(_serialize_firestore(data))

    results.sort(key=lambda item: item.get("updatedAt", 0), reverse=True)
    return results


def _serialize_firestore(data: dict[str, Any]) -> dict[str, Any]:
    serialized: dict[str, Any] = {}
    for key, value in data.items():
        if isinstance(value, datetime):
            serialized[key] = int(value.replace(tzinfo=timezone.utc).timestamp() * 1000)
        else:
            serialized[key] = value
    return serialized


def _to_millis(value: Any) -> int | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        return int(value.replace(tzinfo=timezone.utc).timestamp() * 1000)
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    return None


def sync_collection(
    user_id: str,
    collection: str,
    items: list[dict[str, Any]],
    last_sync: int | None,
) -> list[dict[str, Any]]:
    if items:
        _upsert_collection(user_id, collection, items)
    return _fetch_updates(user_id, collection, last_sync)
