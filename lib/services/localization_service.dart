import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService extends GetxService {
  static LocalizationService get to => Get.find();

  static const String _key = 'language_code';
  
  static final locales = [
    const Locale('en', 'US'),
    const Locale('hi', 'IN'),
    const Locale('gu', 'IN'),
    const Locale('ta', 'IN'),
  ];

  static final langs = [
    'English',
    'Hindi',
    'Gujarati',
    'Tamil',
  ];

  late SharedPreferences _prefs;
  final Rx<Locale> _currentLocale = const Locale('en', 'US').obs;

  Locale get currentLocale => _currentLocale.value;

  Future<LocalizationService> init() async {
    _prefs = await SharedPreferences.getInstance();
    String? langCode = _prefs.getString(_key);
    
    if (langCode != null) {
      _currentLocale.value = _getLocaleFromCode(langCode);
    } else {
      _currentLocale.value = Get.deviceLocale ?? locales.first;
    }
    
    return this;
  }

  void changeLocale(String lang) {
    final locale = _getLocaleFromLanguage(lang);
    _currentLocale.value = locale;
    Get.updateLocale(locale);
    _prefs.setString(_key, locale.languageCode);
  }

  Locale _getLocaleFromLanguage(String lang) {
    for (int i = 0; i < langs.length; i++) {
      if (langs[i] == lang) return locales[i];
    }
    return locales.first;
  }

  Locale _getLocaleFromCode(String code) {
    for (var locale in locales) {
      if (locale.languageCode == code) return locale;
    }
    return locales.first;
  }
}