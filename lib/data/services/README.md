# Data Storage Architecture

This app uses a **local-first system** (SQLite) with a **FastAPI backend** that
brokers all cloud access. Firebase Auth is still used in the app, but Firestore is
**only accessed through the backend**.

## Architecture Overview

```
┌─────────────────┐
│   App Code      │
└────────┬────────┘
         │
         ▼
┌────────────────────┐
│ UnifiedDataService │  ← Main interface for app code
└────────┬───────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ LocalDB │ │ SyncService  │
│ (SQLite)│ │ (HTTP + Auth)│
└─────────┘ └──────┬───────┘
                   │
                   ▼
            ┌────────────────┐
            │ FastAPI Backend│
            │ (Admin SDK)    │
            └──────┬─────────┘
                   │
                   ▼
            ┌──────────────┐
            │  Firestore   │
            └──────────────┘
```

## How It Works

1. **Local First**: All data is saved to SQLite immediately (fast, works offline)
2. **Backend Sync**: SyncService sends changes to the FastAPI backend
3. **Firestore Only via Backend**: The app never touches Firestore directly
4. **Read from Local**: App reads from local DB first (instant, no network delay)
5. **Automatic Sync**: Periodic sync every 30 seconds when authenticated

## Usage

### Initialize Service

In your `main.dart` or app initialization:

```dart
final unifiedService = UnifiedDataService();
await unifiedService.initialize();
```

### Reading Data

```dart
// Get transactions stream (reads from local DB)
final transactionsStream = unifiedService.getTransactions();

// Use in StreamBuilder
StreamBuilder<List<Transaction>>(
  stream: unifiedService.getTransactions(),
  builder: (context, snapshot) {
    // Your UI code
  },
)
```

### Writing Data

```dart
// Add transaction (saves locally immediately, syncs via backend)
await unifiedService.addTransaction(transaction);

// Update transaction
await unifiedService.updateTransaction(transaction);

// Delete transaction
await unifiedService.deleteTransaction(transactionId);
```

### Manual Sync

```dart
// Force a sync (useful for pull-to-refresh)
await unifiedService.syncAll();
```

### Logout

```dart
// Clear local data when logging out
await unifiedService.clearLocalData();
```

## Services

### UnifiedDataService
- **Main interface** for app code
- Provides streams that read from local DB
- Handles writes to both local and Firebase
- Manages periodic syncing

### LocalDatabaseService
- Handles all SQLite operations
- Stores data locally
- Tracks sync status

### SyncService
- Syncs data between local DB and FastAPI
- Sends Firebase ID token for verification
- Manages online/offline state
- Resets sync state on user change

### ApiService
- Low-level HTTP client for backend calls
- Adds Authorization header with Firebase ID token

### FastAPI Backend (external)
- Verifies Firebase ID tokens (Admin SDK)
- Performs validation and upserts
- Controls Firestore access

## Migration Guide

The app no longer uses FirestoreService directly.
All cloud access goes through SyncService + FastAPI.

## Benefits

✅ **Offline Support**: App works completely offline
✅ **Fast Performance**: Instant reads from local DB
✅ **Automatic Sync**: Background syncing when online
✅ **Data Persistence**: Data survives app restarts
✅ **Conflict Resolution**: Handles sync conflicts gracefully

