import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade200,
      child: ElevatedButton(
        onPressed: () {
          print("Iniciar medição (futuro)");
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
        child: const Text("Iniciar Medição (futuro)"),
      ),
    );
  }
}
