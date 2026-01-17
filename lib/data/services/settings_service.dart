import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _defaultCurrencyKey = 'settings_default_currency';
  static const _lbpRateKey = 'settings_lbp_rate';
  static const _themeModeKey = 'settings_theme_mode';
  static const _autoSyncKey = 'settings_auto_sync';
  static const _notificationsEnabledKey = 'settings_notifications_enabled';
  static const _dailyReminderEnabledKey = 'settings_daily_reminder_enabled';
  static const _passcodeKey = 'settings_passcode';
  static const _biometricsEnabledKey = 'settings_biometrics_enabled';

  static final SettingsService _instance = SettingsService._internal();

  factory SettingsService() => _instance;

  SettingsService._internal();

  final ValueNotifier<String> defaultCurrency =
      ValueNotifier<String>('USD');
  final ValueNotifier<double> lbpRate = ValueNotifier<double>(90000.0);
  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);
  final ValueNotifier<bool> autoSyncEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> dailyReminderEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> biometricsEnabled = ValueNotifier<bool>(false);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    defaultCurrency.value = prefs.getString(_defaultCurrencyKey) ?? 'USD';
    lbpRate.value = prefs.getDouble(_lbpRateKey) ?? 90000.0;
    themeMode.value = _themeModeFromString(
      prefs.getString(_themeModeKey) ?? 'system',
    );
    autoSyncEnabled.value = prefs.getBool(_autoSyncKey) ?? false;
    notificationsEnabled.value =
        prefs.getBool(_notificationsEnabledKey) ?? true;
    dailyReminderEnabled.value =
        prefs.getBool(_dailyReminderEnabledKey) ?? false;
    biometricsEnabled.value =
        prefs.getBool(_biometricsEnabledKey) ?? false;
  }

  Future<void> setDefaultCurrency(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultCurrencyKey, code);
    defaultCurrency.value = code;
  }

  Future<void> setLbpRate(double rate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lbpRateKey, rate);
    lbpRate.value = rate;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
    themeMode.value = mode;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
    autoSyncEnabled.value = enabled;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
    notificationsEnabled.value = enabled;
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, enabled);
    dailyReminderEnabled.value = enabled;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, enabled);
    biometricsEnabled.value = enabled;
  }

  Future<void> setPasscode(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null || code.isEmpty) {
      await prefs.remove(_passcodeKey);
    } else {
      await prefs.setString(_passcodeKey, code);
    }
  }

  Future<String?> getPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passcodeKey);
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
