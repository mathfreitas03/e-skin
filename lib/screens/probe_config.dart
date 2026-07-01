import 'package:eprobe/controllers/language_handler.dart';
import 'package:flutter/material.dart';

class IzConfigCard extends StatefulWidget {
  final Map<String, String> config;

  const IzConfigCard({
    super.key,
    required this.config,
  });

  @override
  State<IzConfigCard> createState() => _IzConfigCardState();
}

class _IzConfigCardState extends State<IzConfigCard> {
  @override
  Widget build(BuildContext context) {
    if (widget.config.isEmpty) {
      return Center(
        child: Text(LanguageHandler().translate('no_settings_available'))//Text("Nenhuma configuração disponível"),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    // "Configuração da Sonda",
                    LanguageHandler().translate('probe_settings'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              ...widget.config.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.value,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}