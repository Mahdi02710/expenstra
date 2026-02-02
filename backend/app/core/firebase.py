import json
from typing import Any

import firebase_admin
from firebase_admin import auth, credentials, firestore

from .config import get_settings


def initialize_firebase() -> None:
    settings = get_settings()
    if firebase_admin._apps:
        return

    if settings.firebase_credentials_json:
        service_account_info = json.loads(settings.firebase_credentials_json)
        cred = credentials.Certificate(service_account_info)
        firebase_admin.initialize_app(cred)
    elif settings.firebase_credentials_path:
        cred = credentials.Certificate(settings.firebase_credentials_path)
        firebase_admin.initialize_app(cred)
    else:
        firebase_admin.initialize_app()


def get_firestore_client() -> firestore.Client:
    initialize_firebase()
    return firestore.client()


def verify_id_token(id_token: str) -> dict[str, Any]:
    initialize_firebase()
    return auth.verify_id_token(id_token)
