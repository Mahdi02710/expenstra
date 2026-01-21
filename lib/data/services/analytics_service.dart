import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/analytics_summary.dart';

class AnalyticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  Stream<AnalyticsSummary?> getSummary() {
    if (_userId == null) {
      return Stream.value(null);
    }

    return _db
        .collection('users')
        .doc(_userId)
        .collection('analytics')
        .doc('summary')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return AnalyticsSummary.fromMap(data);
    });
  }
}
