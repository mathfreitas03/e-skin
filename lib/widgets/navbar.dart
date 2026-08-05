import 'dart:async';

import 'package:eprobe/controllers/language_handler.dart';
import 'package:flutter/material.dart';
import 'package:eprobe/controllers/ble_controller.dart';
import 'package:eprobe/models/connection_status.dart';

class Navbar extends StatefulWidget implements PreferredSizeWidget {
  // Alterado de onConnect para onScan para refletir a nova ação de busca
  final VoidCallback onScan;
  final BleController ble;
  final String title;

  const Navbar({
    super.key,
    required this.onScan,
    required this.ble,
    this.title = 'eProbe',
  });

  @override
  State<Navbar> createState() => _NavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _NavbarState extends State<Navbar> {
  BleConnectionStatus status = BleConnectionStatus.disconnected;
  StreamSubscription? _connectionSub;
  bool wasConnected = false;

  @override
  void initState() {
    super.initState();

    _connectionSub = widget.ble.connectionStream.listen((newStatus) {
      if (!mounted) return;

      setState(() {
        status = newStatus;
      });

      if (newStatus == BleConnectionStatus.connected) {
        wasConnected = true;
      }

      if (wasConnected && newStatus == BleConnectionStatus.disconnected) {
        wasConnected = false; // Corrigido de == para =
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lost connection'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (newStatus == BleConnectionStatus.disconnected) {
        // Esta mensagem agora só aparecerá se o usuário tentar conectar e falhar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to find the device.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }

  Color _statusColor() {
    switch (status) {
      case BleConnectionStatus.connected:
        return Colors.green;

      case BleConnectionStatus.connecting:
      case BleConnectionStatus.scanning:
        return Colors.yellow;

      case BleConnectionStatus.disconnected:
        return Colors.red;
    }
  }

  String _buttonLabel() {
    switch (status) {
      case BleConnectionStatus.connected:
        return LanguageHandler().translate('connected');

      case BleConnectionStatus.scanning:
        return LanguageHandler().translate('searching');

      case BleConnectionStatus.connecting:
        return LanguageHandler().translate('connecting');

      case BleConnectionStatus.disconnected:
        return LanguageHandler().translate('connect'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    // Desabilita o clique se já estiver processando alguma operação de BLE
    final bool isLoading = status == BleConnectionStatus.scanning || 
                         status == BleConnectionStatus.connecting;

    return AppBar(
      backgroundColor: Colors.green,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            // Desabilita o botão enquanto escaneia ou conecta
            onPressed: isLoading ? null : widget.onScan,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(_buttonLabel()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}