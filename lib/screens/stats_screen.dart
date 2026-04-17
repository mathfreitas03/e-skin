import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../controllers/iz_controller.dart';
import 'graph_view_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  final List<String> logs = const [
    "ble_communication_20260330_213100.txt",
    "log2.txt",
    "log3.txt",
    "log4.txt",
  ];

  Future<void> _openLog(BuildContext context, String fileName) async {
    final data = await rootBundle.loadString("assets/logs/$fileName");

    final iz = IzController();
    iz.process(data);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GraphViewScreen(
          title: fileName,
          iz: iz,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: logs.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemBuilder: (context, index) {
          final file = logs[index];

          return GestureDetector(
            onTap: () => _openLog(context, file),
            child: Card(
              elevation: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.show_chart, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    file,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}