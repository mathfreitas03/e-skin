import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/models/found_ble_device.dart';
import 'package:flutter/material.dart';

class DeviceCard extends StatelessWidget {
  final FoundBleDevice device;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = device.discoveredDevice.name.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(
            Icons.bluetooth,
            color: Colors.blue.shade700,
          ),
        ),
        title: Text(
          hasName ? device.discoveredDevice.name : "Unknown device",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: hasName ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
        // MAC ADDRESS
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                device.discoveredDevice.id,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              if (!device.isValid)
                Padding(
                  padding: EdgeInsets.only(top: 2.0),
                  child: Text(
                    LanguageHandler().translate('incompatible_device'),
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}