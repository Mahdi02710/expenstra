import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _guestKey = 'session_guest_mode';
  static final SessionService _instance = SessionService._internal();

  factory SessionService() => _instance;

  SessionService._internal();

  final ValueNotifier<bool> isGuestMode = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    isGuestMode.value = prefs.getBool(_guestKey) ?? false;
  }

  Future<void> setGuestMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, value);
    isGuestMode.value = value;
  }
}
