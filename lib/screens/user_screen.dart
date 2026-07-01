import 'package:eprobe/controllers/app_configs.dart';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:flutter/material.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final AppConfigs _configs = AppConfigs();
  final LanguageHandler _langHandler = LanguageHandler();

  late String _selectedLanguage;
  late String _selectedScale;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _configs.language;
    _selectedScale = _configs.temperatureScale;
  }

  Future<void> _updateLanguage(String newLang) async {
    await _configs.setLanguage(newLang); // Salva na cache
    await _langHandler.init();           // Recarrega o JSON correspondente
    setState(() {
      _selectedLanguage = newLang;
    });

    // Feedback visual opcional
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_langHandler.translate("config_saved") != "config_saved" 
            ? _langHandler.translate("config_saved") 
            : "Configurações atualizadas!"),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _updateScale(String newScale) async {
    await _configs.setTemperatureScale(newScale); // Salva na cache
    setState(() {
      _selectedScale = newScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _langHandler.translate; 

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Cabeçalho da Tela
          const SizedBox(height: 10),
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.person, size: 35),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t("user_profile") != "user_profile" ? t("user_profile") : "Perfil de Usuário",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text("eProbe App v1.0.0", style: TextStyle(color: Colors.grey)),
                ],
              )
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),

          // Seção de Preferências / Configurações
          Text(
            t("preferences") != "preferences" ? t("preferences") : "Preferências",
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.primary
            ),
          ),
          const SizedBox(height: 12),

          // CARD Seleção de Idioma
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              // title: Text(t("language") != "language" ? t("language") : "Idioma"),
              title: Text(LanguageHandler().translate("language")),
              subtitle: Text(_selectedLanguage == "pt_BR" ? "Português" : "English"),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(), // Remove a linha padrão do Dropdown
                items: const [
                  DropdownMenuItem(value: "pt_BR", child: Text("Português (PT-BR)")),
                  DropdownMenuItem(value: "en_US", child: Text("English (EN-US)")),
                  DropdownMenuItem(value: "es_LA", child: Text("Español (ES-LA)")),
                ],
                onChanged: (String? value) {
                  if (value != null && value != _selectedLanguage) {
                    _updateLanguage(value);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // CARD Seleção de Escala de Temperatura
          Card(
            child: ListTile(
              leading: const Icon(Icons.thermostat),
              title: Text(t("temperature_scale") != "temperature_scale" ? t("temperature_scale") : "Escala Térmica"),
              subtitle: Text(_selectedScale),
              trailing: DropdownButton<String>(
                value: _selectedScale,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: "Celsius", child: Text("Celsius (°C)")),
                  DropdownMenuItem(value: "Fahrenheit", child: Text("Fahrenheit (°F)")),
                  DropdownMenuItem(value: "Kelvin", child: Text("Kelvin (K)")),
                ],
                onChanged: (String? value) {
                  if (value != null && value != _selectedScale) {
                    _updateScale(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}