import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  final RxBool _isDarkMode = false.obs;
  static const String _themeKey        = 'isDarkMode';
  static const String _userSetThemeKey = 'hasUserSetTheme';

  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final hasUserSetTheme = prefs.getBool(_userSetThemeKey) ?? false;

    if (hasUserSetTheme) {
      // User explicitly chose a theme — respect it
      _isDarkMode.value = prefs.getBool(_themeKey) ?? false;
    } else {
      // First launch — follow the system setting
      final brightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode.value = brightness == Brightness.dark;
    }

    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode.value);
    await prefs.setBool(_userSetThemeKey, true); // Remember that user chose manually
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
}
