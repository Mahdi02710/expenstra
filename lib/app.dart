import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

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
      home: const HomeScreen(),
    );
  }
}
