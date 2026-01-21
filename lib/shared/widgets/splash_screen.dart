// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../app.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/session_service.dart';
import '../../data/services/settings_service.dart';
import '../../data/services/unified_data_service.dart';
import '../../firebase_options.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await SettingsService().initialize();
      await SessionService().initialize();

      final notificationService = NotificationService();
      await notificationService.initialize();
      if (SettingsService().notificationsEnabled.value &&
          SettingsService().dailyReminderEnabled.value) {
        await notificationService.scheduleDailyReminder(enabled: true);
      }

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await _initializeAppCheck();
      final unifiedService = UnifiedDataService();
      await unifiedService.initialize();

      // Give a minimum display time for splash screen (better UX)
      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted && !_isInitialized) {
        _isInitialized = true;
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const ExpensTra()));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _initializeAppCheck() async {
    if (kIsWeb) return;
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.deviceCheck,
      );
    } catch (_) {
      // Keep startup resilient if App Check is unavailable in debug.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use hardcoded colors to avoid theme dependency
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.navy, AppColors.blueDark, AppColors.blueMedium]
                : [
                    const Color(0xFFF0F4F8),
                    const Color(0xFFE8F0F8),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo (no background)
                Image.asset(
                  'assets/images/ExpensTra-Logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 32),

                // App name - using default text style
                Text(
                  'ExpensTra',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.navy,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Track your expenses, grow your wealth',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 64),

                if (_hasError) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Initialization failed. Tap retry.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _initializeApp,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.gold
                          : AppColors.primary,
                      side: BorderSide(
                        color: isDark ? AppColors.gold : AppColors.primary,
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  // Simple loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? AppColors.gold : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
