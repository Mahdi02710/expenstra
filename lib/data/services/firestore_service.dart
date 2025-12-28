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
          (snapshot) => snapshot.docs
              .map((doc) => model.Transaction.fromMap(doc.data(), doc.id))
              .toList(),
        );
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
