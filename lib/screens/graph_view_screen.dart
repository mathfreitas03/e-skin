import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/iz_controller.dart';
import '../widgets/graph_card.dart';

class GraphViewScreen extends StatelessWidget {
  final IzController iz;
  final String title;

  const GraphViewScreen({
    super.key,
    required this.iz,
    required this.title,
  });

  List<FlSpot> _spots(List<double> x, List<double> y) {
    List<FlSpot> s = [];
    int min = x.length < y.length ? x.length : y.length;

    for (int i = 0; i < min; i++) {
      s.add(FlSpot(x[i], y[i]));
    }

    return s;
  }

  @override
  Widget build(BuildContext context) {
    final realSpots = _spots(iz.freq, iz.real);
    final imagSpots = _spots(iz.freq, iz.imag);

    if (iz.freq.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: Text("Nenhum dado encontrado no arquivo"),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            SizedBox(
              height: 220,
              child: GraphCard(
                title: "Real(Z)",
                unit: "Ω",
                spots: realSpots,
                color: Colors.red,
                
                
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: GraphCard(
                title: "Imag(Z)",
                unit: "Ω",
                spots: imagSpots,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}