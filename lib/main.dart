import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'data/services/unified_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize unified data service (local SQLite + Firebase sync)
  final unifiedService = UnifiedDataService();
  await unifiedService.initialize();

  runApp(const ExpensTra());
}
