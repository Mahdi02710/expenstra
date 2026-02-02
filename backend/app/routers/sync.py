from datetime import datetime, timezone

from fastapi import APIRouter, Depends

from ..core.security import get_current_user
from ..models.budget import BudgetSyncRequest, BudgetSyncResponse
from ..models.transaction import TransactionSyncRequest, TransactionSyncResponse
from ..models.wallet import WalletSyncRequest, WalletSyncResponse
from ..services.sync import sync_collection
from ..core.firebase import get_firestore_client

router = APIRouter(prefix="/sync", tags=["sync"])


@router.post("/transactions", response_model=TransactionSyncResponse)
def sync_transactions(
    payload: TransactionSyncRequest,
    user=Depends(get_current_user),
):
    upserts = sync_collection(
        user["uid"],
        "transactions",
        [item.dict() for item in payload.items],
        payload.lastSync,
    )
    return TransactionSyncResponse(
        upserts=upserts,
        serverTime=int(datetime.now(tz=timezone.utc).timestamp() * 1000),
    )


@router.post("/wallets", response_model=WalletSyncResponse)
def sync_wallets(
    payload: WalletSyncRequest,
    user=Depends(get_current_user),
):
    upserts = sync_collection(
        user["uid"],
        "wallets",
        [item.dict() for item in payload.items],
        payload.lastSync,
    )
    return WalletSyncResponse(
        upserts=upserts,
        serverTime=int(datetime.now(tz=timezone.utc).timestamp() * 1000),
    )


@router.post("/budgets", response_model=BudgetSyncResponse)
def sync_budgets(
    payload: BudgetSyncRequest,
    user=Depends(get_current_user),
):
    upserts = sync_collection(
        user["uid"],
        "budgets",
        [item.dict() for item in payload.items],
        payload.lastSync,
    )
    return BudgetSyncResponse(
        upserts=upserts,
        serverTime=int(datetime.now(tz=timezone.utc).timestamp() * 1000),
    )


@router.delete("/transactions/{transaction_id}")
def delete_transaction(transaction_id: str, user=Depends(get_current_user)):
    db = get_firestore_client()
    (
        db.collection("users")
        .document(user["uid"])
        .collection("transactions")
        .document(transaction_id)
        .delete()
    )
    return {"status": "deleted", "id": transaction_id}


@router.delete("/wallets/{wallet_id}")
def delete_wallet(wallet_id: str, user=Depends(get_current_user)):
    db = get_firestore_client()
    (
        db.collection("users")
        .document(user["uid"])
        .collection("wallets")
        .document(wallet_id)
        .delete()
    )
    return {"status": "deleted", "id": wallet_id}


@router.delete("/budgets/{budget_id}")
def delete_budget(budget_id: str, user=Depends(get_current_user)):
    db = get_firestore_client()
    (
        db.collection("users")
        .document(user["uid"])
        .collection("budgets")
        .document(budget_id)
        .delete()
    )
    return {"status": "deleted", "id": budget_id}
