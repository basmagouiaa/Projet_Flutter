import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _darkMode = false;
  bool get darkMode => _darkMode;

  bool _music = false;
  bool get music => _music;

  String _language = 'fr';
  String get language => _language;

  Function(String)? onLanguageChanged;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('Dark') ?? false;
    _music = prefs.getBool('Music') ?? false;
    _language = prefs.getString('currentLanguage') ?? 'fr';
    notifyListeners();
  }

  Future<void> updateDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('Dark', value);
    notifyListeners();
  }

  Future<void> updateMusic(bool value) async {
    _music = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('Music', value);
    notifyListeners();
  }

  Future<void> updateLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentLanguage', value);
    notifyListeners();
    if (onLanguageChanged != null) {
      onLanguageChanged!(value);
    }
  }
}