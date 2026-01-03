import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction.dart' as model;

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Stream<List<model.Transaction>> getTransactions() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) {
            try {
              return snapshot.docs
                  .map((doc) {
                    try {
                      return model.Transaction.fromMap(doc.data(), doc.id);
                    } catch (e) {
                      print('Error parsing transaction ${doc.id}: $e');
                      return null;
                    }
                  })
                  .whereType<model.Transaction>()
                  .toList();
            } catch (e) {
              print('Error processing transactions: $e');
              return <model.Transaction>[];
            }
          },
        )
        .handleError((error) {
          print('Error loading transactions: $error');
        });
  }

  Future<void> addTransaction(model.Transaction transaction) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .add(transaction.toMap());
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }
}
