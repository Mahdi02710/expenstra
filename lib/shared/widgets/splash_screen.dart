import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../app.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for Firebase to be initialized (it's being initialized in main.dart)
    while (Firebase.apps.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Give a minimum display time for splash screen (better UX)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Navigate to main app
    if (mounted && !_isInitialized) {
      _isInitialized = true;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const ExpensTra()));
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
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? const LinearGradient(
                            colors: [Color(0xFFD2AB17), Color(0xFFEDC047)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF163473), Color(0xFF162647)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? AppColors.gold : AppColors.primary)
                            .withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/ExpensTra-Logo.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
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
            ),
          ),
        ),
      ),
    );
  }
}
