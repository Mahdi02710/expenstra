# Data Storage Architecture

This app uses a **dual storage system** - SQLite (local) + Firebase (cloud) for optimal performance and offline support.

## Architecture Overview

```
┌─────────────────┐
│   App Code      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ UnifiedDataService │  ← Main interface for app code
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌─────────┐ ┌──────────────┐
│ LocalDB │ │ SyncService  │
│ (SQLite)│ │              │
└─────────┘ └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │ FirestoreService│
            │   (Firebase)  │
            └──────────────┘
```

## How It Works

1. **Local First**: All data is saved to SQLite immediately (fast, works offline)
2. **Background Sync**: Data syncs to Firebase in the background when online
3. **Read from Local**: App reads from local DB first (instant, no network delay)
4. **Automatic Sync**: Periodic sync every 30 seconds when authenticated

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
// Add transaction (saves locally immediately, syncs to Firebase in background)
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
- Syncs data between local DB and Firebase
- Handles conflict resolution
- Manages online/offline state

### FirestoreService
- Handles Firebase operations
- Used by SyncService for cloud operations

## Migration Guide

To migrate existing code from FirestoreService to UnifiedDataService:

**Before:**
```dart
final firestoreService = FirestoreService();
StreamBuilder(
  stream: firestoreService.getTransactions(),
  ...
)
```

**After:**
```dart
final unifiedService = UnifiedDataService();
await unifiedService.initialize(); // Once at app start
StreamBuilder(
  stream: unifiedService.getTransactions(),
  ...
)
```

## Benefits

✅ **Offline Support**: App works completely offline
✅ **Fast Performance**: Instant reads from local DB
✅ **Automatic Sync**: Background syncing when online
✅ **Data Persistence**: Data survives app restarts
✅ **Conflict Resolution**: Handles sync conflicts gracefully

