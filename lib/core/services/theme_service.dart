import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  final SharedPreferences prefs;
  
  ThemeService(this.prefs);

  static const _themeKey = 'isDarkMode';

  bool get isDarkTheme => prefs.getBool(_themeKey) ?? false;

  ThemeMode get themeMode => isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  void switchTheme() {
    Get.changeThemeMode(isDarkTheme ? ThemeMode.light : ThemeMode.dark);
    prefs.setBool(_themeKey, !isDarkTheme);
  }
}
