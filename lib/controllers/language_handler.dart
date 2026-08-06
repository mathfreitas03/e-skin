import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_configs.dart';

class LanguageHandler extends ChangeNotifier {
  // Singleton para o Handler
  LanguageHandler._internal();
  static final LanguageHandler _instance = LanguageHandler._internal();
  factory LanguageHandler() => _instance;

  Map<String, String> _localizedStrings = {};

  /// Inicializa e carrega o arquivo JSON baseado no idioma ativo da cache
  Future<void> init() async {
    // Pega o idioma atual salvo na cache (Ex: "pt_BR")
    String currentLanguage = AppConfigs().language;

    
    String jsonString = await rootBundle.loadString('assets/lang/$currentLanguage.json');
          Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    notifyListeners();
    
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}