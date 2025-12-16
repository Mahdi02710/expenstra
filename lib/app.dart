import 'package:expensetra/features/home/home_screen.dart';
import 'package:expensetra/login_page/login_page.dart';
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
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
