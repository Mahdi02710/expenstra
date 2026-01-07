import 'package:expensetra/features/home/home_screen.dart';
import 'package:expensetra/login_page/login_page.dart';
import 'package:expensetra/shared/widgets/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class ExpensTra extends StatelessWidget {
  const ExpensTra({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpensTra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show beautiful splash screen while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          // Show error if there's an error
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Retry by rebuilding
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const ExpensTra()),
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
          
          // Show appropriate screen based on auth state
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
