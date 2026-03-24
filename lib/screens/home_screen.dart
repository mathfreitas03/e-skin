import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/graph_card.dart';
import '../controllers/iz_controller.dart';
import '../models/connection_status.dart';

class HomeScreen extends StatelessWidget {

  final ConnectionStatus connStatus;
  final IzController iz;
  final double temperature;
  final int pressure;
  final String selectedDataset;
  final String controlConfirmation;
  final Function(String) onDatasetChanged;

  const HomeScreen({
    super.key,
    required this.connStatus,
    required this.iz,
    required this.temperature,
    required this.pressure,
    required this.selectedDataset,
    required this.controlConfirmation,
    required this.onDatasetChanged,
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

    if (connStatus != ConnectionStatus.connected) {
      return const Center(
        child: Text("Conecte ao dispositivo para ver os dados"),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [

          SizedBox(
            height:220,
            child: GraphCard(
              title: "Real(Z)",
              unit: "Ω",
              spots: realSpots,
              color: Colors.red,
            ),
          ),

          const SizedBox(height:12),

          SizedBox(
            height:220,
            child: GraphCard(
              title: "Imag(Z)",
              unit: "Ω",
              spots: imagSpots,
              color: Colors.green,
            ),
          ),

          const SizedBox(height:12),

          GridView.count(
            crossAxisCount:2,
            shrinkWrap:true,
            physics: const NeverScrollableScrollPhysics(),
            children:[

              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Text("Temp: ${temperature.toStringAsFixed(1)} °C"),
                    Text("Pressão: $pressure g"),
                  ],
                ),
              ),

              Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: "Comando",
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: selectedDataset),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        onDatasetChanged(value); // envia o texto direto
                      }
                    },
                  ),
                  
                ],
              ),
            ),
          )

            ],
          )
        ],
      ),
    );
  }
}