import 'dart:convert';
import 'package:flutter/services.dart';

class LocalizationService {
  late Map<String, dynamic> _localizedStrings;

  Future<void> load(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString('lib/lan/$languageCode.json');
      _localizedStrings = json.decode(jsonString);
    } catch (e) {
      print('Error loading language: $e');
      _localizedStrings = {};
    }
  }

  String translate(String key) {
    List<String> keys = key.split('.');
    dynamic value = _localizedStrings;

    for (String k in keys) {
      if (value is Map<String, dynamic> && value.containsKey(k)) {
        value = value[k];
      } else {
        return key;
      }
    }

    return value is String ? value : key;
  }
}
