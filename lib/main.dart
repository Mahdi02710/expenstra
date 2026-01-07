import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/services/unified_data_service.dart';
import 'shared/widgets/splash_screen.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show splash screen immediately with basic theme
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.system,
    home: const SplashScreen(),
  ));

  // Initialize Firebase and services in the background
  _initializeApp();
}

Future<void> _initializeApp() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize unified data service (local SQLite + Firebase sync)
    final unifiedService = UnifiedDataService();
    await unifiedService.initialize();

    // Navigate to main app after initialization
    // This will be handled by the app's StreamBuilder
  } catch (e, stackTrace) {
    // Print error for debugging
    print('Initialization error: $e');
    print('Stack trace: $stackTrace');
    // Error will be handled by the app's error handling
  }
}
