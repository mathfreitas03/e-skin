import 'package:shared_preferences/shared_preferences.dart';

class AppConfigs {
  static const String _keyLanguage = 'app_language';
  static const String _keyTempScale = 'app_temp_scale';

  late String language;  
  late String temperatureScale;

  // Singleton para AppConfigs
  
  AppConfigs._internal();
  static final AppConfigs _instance = AppConfigs._internal();
  factory AppConfigs() => _instance;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    language = prefs.getString(_keyLanguage) ?? 'pt_BR';
    temperatureScale = prefs.getString(_keyTempScale) ?? 'Celsius';
  }

  Future<void> setLanguage(String newLanguage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, newLanguage);
    language = newLanguage;
  }

  Future<void> setTemperatureScale(String newScale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTempScale, newScale);
    temperatureScale = newScale;
  }

  String formatTemperature(double celsiusValue) {
  switch (temperatureScale) {
    case 'Fahrenheit':
      double f = (celsiusValue * 9 / 5) + 32;
      return "${f.toStringAsFixed(1)} °F";
    case 'Kelvin':
      double k = celsiusValue + 273.15;
      return "${k.toStringAsFixed(1)} K";
    default:
      return "${celsiusValue.toStringAsFixed(1)} °C";
  }
}
}