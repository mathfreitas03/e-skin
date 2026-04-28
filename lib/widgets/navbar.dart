// lib/ui/navbar.dart
import 'package:flutter/material.dart';
import 'package:e_skin/models/connection_status.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onConnect;
  final ConnectionStatus status;
  final String title;
  final String assetLogoPath; // ex: 'assets/images/logo_teste.jpg'

  const Navbar({
    super.key,
    required this.onConnect,
    required this.status,
    this.title = 'eProbe',
    this.assetLogoPath = 'assets/images/logo_teste.jpg',
  });

  Color _statusColor() {
    switch (status) {
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.connecting:
      case ConnectionStatus.scanning:
        return Colors.yellow;
      case ConnectionStatus.disconnected:
      return Colors.red;
    }
  }

  String _buttonLabel() {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Conectado';
      case ConnectionStatus.scanning:
        return 'Procurando...';
      case ConnectionStatus.connecting:
        return 'Conectando...';
      case ConnectionStatus.disconnected:
      return 'Conectar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green,
      elevation: 2,
      title: Row(
        children: [
          // Logo (use Image.asset para PNG/JPG, SvgPicture.asset para SVG com flutter_svg)
          // Image.asset(
          //   assetLogoPath,
          //   height: 32,
          //   errorBuilder: (context, error, stackTrace) {
          //     // fallback simples se asset não existir
          //     return const Icon(Icons.bluetooth, size: 32);
          //   },
          // ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              children: [
                // bolinha de status
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      )
                    ],
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

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
