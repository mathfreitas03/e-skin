import 'package:eprobe/controllers/dataset_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:eprobe/controllers/app_configs.dart';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/services/drive_backup_service.dart';

class UserScreen extends ConsumerStatefulWidget {
  const UserScreen({super.key});
  @override
  ConsumerState<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends ConsumerState<UserScreen> {
  final AppConfigs _configs = AppConfigs();
  final LanguageHandler _langHandler = LanguageHandler();

  late String _selectedLanguage;
  late String _selectedScale;
  bool _isDriveBackupEnabled = false;
  bool _isSyncing = false;

  GoogleSignInAccount? _currentUser;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope,
      drive.DriveApi.driveFileScope,
    ],
  );

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _configs.language;
    _selectedScale = _configs.temperatureScale;
    _isDriveBackupEnabled = _configs.isDriveBackupEnabled;

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
    });

    _signInSilently();
  }

  Future<void> _signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null && _isDriveBackupEnabled) {
        await _toggleDriveBackup(false);
      }
    } catch (e) {
      debugPrint("Erro no silent sign-in: $e");
    }
  }

  Future<void> _triggerSyncProcess() async {
    if (_currentUser == null) return;

    setState(() => _isSyncing = true);

    await DriveBackupService.performSyncWithDecision(
      context,
      _currentUser!,
      onStatusMessage: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
          );
        }
      },
    );

    ref.invalidate(datasetProvider);

    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

Future<void> _handleSignIn() async {
  setState(() => _isSyncing = true);
  try {
    // 1. Tenta o login com os escopos já passados na instância _googleSignIn
    GoogleSignInAccount? account = await _googleSignIn.signIn();

    if (account != null) {
      // 2. Garante que os escopos foram solicitados explicitamente
      final bool scopeGranted = await _googleSignIn.requestScopes([
        drive.DriveApi.driveAppdataScope,
      ]);

      if (!scopeGranted) {
        throw Exception("A permissão para salvar no Google Drive foi negada.");
      }

      await _toggleDriveBackup(true);

      if (mounted) {
        await _triggerSyncProcess();
      }
    } else {
      await _toggleDriveBackup(false);
    }
  } catch (error) {
    debugPrint("Erro no login do Google: $error");
    await _toggleDriveBackup(false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${LanguageHandler().translate('auth_failed')}: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }
}

  Future<void> _handleSignOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      await _googleSignIn.signOut();
    }
    await _toggleDriveBackup(false);
  }

  Future<void> _toggleDriveBackup(bool value) async {
    await _configs.setDriveBackupEnabled(value);
    setState(() {
      _isDriveBackupEnabled = value;
    });
  }

  Future<void> _updateLanguage(String newLang) async {
    await _configs.setLanguage(newLang);
    await _langHandler.init();
    setState(() {
      _selectedLanguage = newLang;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageHandler().translate("config_saved") != "config_saved"
                ? _langHandler.translate("config_saved")
                : "Configurações atualizadas!",
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _updateScale(String newScale) async {
    await _configs.setTemperatureScale(newScale);
    setState(() {
      _selectedScale = newScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _langHandler.translate;

    final String userName = _currentUser?.displayName ??
        (t("user_profile") != "user_profile" ? t("user_profile") : "Perfil de Usuário");
    final String userEmail = _currentUser?.email ?? "eProbe App v1.0.0";
    final String? photoUrl = _currentUser?.photoUrl;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 10),

          // Perfil do Usuário
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? const Icon(Icons.person, size: 35) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      userEmail,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(),
          ),

          // Seção Nuvem & Backup
          Text(
            t("cloud_and_backup") != "cloud_and_backup" ? t("cloud_and_backup") : "Nuvem e Backup",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Card Google Drive
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: Text(
                    "Google Drive Backup"
                  ),
                  subtitle: Text(
                    _isDriveBackupEnabled
                        ? (_currentUser != null
                            ? "${LanguageHandler().translate('connected_as')} ${_currentUser!.email}"
                            : "Sincronização ativa")
                        : "${LanguageHandler().translate('synchronization')} offline",
                  ),
                  trailing: _isSyncing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: _isDriveBackupEnabled,
                          onChanged: (bool value) async {
                            if (value) {
                              if (_currentUser == null) {
                                await _handleSignIn();
                              } else {
                                await _toggleDriveBackup(true);
                                await _triggerSyncProcess();
                              }
                            } else {
                              await _handleSignOut();
                            }
                          },
                        ),
                ),
                if (_isDriveBackupEnabled && _currentUser != null) ...[
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.sync),
                    title: Text(LanguageHandler().translate('sync_now')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _isSyncing ? null : _triggerSyncProcess,
                  ),
                ]
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Preferências
          Text(
            t("preferences") != "preferences" ? t("preferences") : "Preferências",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Card Idioma
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(LanguageHandler().translate("language")),
              subtitle: Text(LanguageHandler().translate('selected_language')),
              trailing: DropdownButton<String>(
                value: _selectedLanguage,
                underline: const SizedBox(),
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

          // Card Escala Térmica
          Card(
            child: ListTile(
              leading: const Icon(Icons.thermostat),
              title: Text(
                t("temperature_scale") != "temperature_scale"
                    ? t("temperature_scale")
                    : "Escala Térmica",
              ),
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