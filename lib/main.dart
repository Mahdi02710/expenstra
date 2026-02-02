import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/splash_screen.dart';

//Run Backend Server: uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    ),
  );
}
