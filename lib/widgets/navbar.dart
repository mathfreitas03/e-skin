import 'dart:async';

import 'package:flutter/material.dart';
import 'package:eprobe/controllers/ble_controller.dart';
import 'package:eprobe/models/connection_status.dart';

class Navbar extends StatefulWidget implements PreferredSizeWidget {

  final VoidCallback onConnect;
  final BleController ble;

  final String title;

  const Navbar({
    super.key,
    required this.onConnect,
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

      if (wasConnected &&
          newStatus == BleConnectionStatus.disconnected) {
          wasConnected == false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conexão perdida'),
            duration: Duration(seconds: 2),
          ),
        );
      }
        else if(newStatus == BleConnectionStatus.disconnected){
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível encontrar o dispositivo.'),
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

      case BleConnectionStatus.connecting || BleConnectionStatus.scanning:
        return Colors.yellow;

      case BleConnectionStatus.disconnected:
        return Colors.red;
    }
  }

  String _buttonLabel() {
    switch (status) {
      case BleConnectionStatus.connected:
        return 'Conectado';

      case BleConnectionStatus.scanning:
        return 'Procurando...';

      case BleConnectionStatus.connecting:
        return 'Conectando...';

      case BleConnectionStatus.disconnected:
        return 'Conectar';
    }
  }

  @override
  Widget build(BuildContext context) {

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
            onPressed: widget.onConnect,

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