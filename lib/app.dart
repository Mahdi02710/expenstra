import 'package:expensetra/features/home/home_screen.dart';
import 'package:expensetra/login_page/login_page.dart';
import 'package:expensetra/shared/widgets/splash_screen.dart';
import 'package:expensetra/shared/widgets/passcode_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'data/services/session_service.dart';
import 'data/services/settings_service.dart';

class ExpensTra extends StatelessWidget {
  const ExpensTra({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService().themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'ExpensTra',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const ExpensTra(),
                                ),
                              );
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasData) {
                return const PasscodeGate(child: HomeScreen());
              }
              return ValueListenableBuilder<bool>(
                valueListenable: SessionService().isGuestMode,
                builder: (context, isGuest, _) {
                  if (isGuest) {
                    return const PasscodeGate(child: HomeScreen());
                  }
                  return const LoginPage();
                },
              );
            },
          ),
        );
      },
    );
  }
}
