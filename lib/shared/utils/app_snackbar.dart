import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      action: action,
      duration: duration,
    ),
  );
}
