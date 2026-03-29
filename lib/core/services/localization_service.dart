import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends GetxService {
  final SharedPreferences prefs;

  LocalizationService(this.prefs);

  static const String _langKey = 'lang_code';

  Locale get currentLanguage {
    String? lang = prefs.getString(_langKey);
    if (lang == 'en') return const Locale('en', 'US');
    return const Locale('ar', 'SA');
  }

  void changeLocale(String langCode) {
    if (langCode == 'ar') {
      Get.updateLocale(const Locale('ar', 'SA'));
      prefs.setString(_langKey, 'ar');
    } else {
      Get.updateLocale(const Locale('en', 'US'));
      prefs.setString(_langKey, 'en');
    }
  }
}
