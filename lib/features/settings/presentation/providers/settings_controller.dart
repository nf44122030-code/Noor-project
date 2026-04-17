import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  // SharedPreferences keys
  static const String _notificationsKey    = 'notificationsEnabled';
  static const String _emailNotifKey       = 'emailNotifications';
  static const String _pushNotifKey        = 'pushNotifications';
  static const String _autoSaveKey         = 'autoSave';
  static const String _languageKey         = 'appLanguage';

  // Reactive state
  final RxBool notificationsEnabled = true.obs;
  final RxBool emailNotifications   = true.obs;
  final RxBool pushNotifications    = true.obs;
  final RxBool autoSave             = true.obs;
  final RxString currentLanguage    = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled.value = prefs.getBool(_notificationsKey) ?? true;
    emailNotifications.value   = prefs.getBool(_emailNotifKey)    ?? true;
    pushNotifications.value    = prefs.getBool(_pushNotifKey)     ?? true;
    autoSave.value             = prefs.getBool(_autoSaveKey)      ?? true;
    currentLanguage.value      = prefs.getString(_languageKey)    ?? 'en';
    
    // Sync GetX's locale engine with the persisted language on startup
    Get.updateLocale(Locale(currentLanguage.value));
  }

  Future<void> changeLanguage(String langCode) async {
    currentLanguage.value = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, langCode);
    
    // Update GetX locale — use the correct Locale constructor
    final newLocale = Locale(langCode);
    Get.updateLocale(newLocale);
    
    // Force a complete widget tree rebuild to ensure all .tr calls re-evaluate
    Future.microtask(() => Get.forceAppUpdate());
  }

  Future<void> setNotificationsEnabled(bool v) async {
    notificationsEnabled.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, v);
  }

  Future<void> setEmailNotifications(bool v) async {
    emailNotifications.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotifKey, v);
  }

  Future<void> setPushNotifications(bool v) async {
    pushNotifications.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotifKey, v);
  }

  Future<void> setAutoSave(bool v) async {
    autoSave.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, v);
  }
}
