import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/graph_card.dart';
import '../controllers/iz_controller.dart';
import '../models/connection_status.dart';

// class HomeScreen extends StatelessWidget {

//   final ConnectionStatus connStatus;
//   final IzController iz;
//   final double temperature;
//   final int pressure;
//   final String selectedDataset;
//   final String controlConfirmation;
//   final Function(String) onDatasetChanged;

//   const HomeScreen({
//     super.key,
//     required this.connStatus,
//     required this.iz,
//     required this.temperature,
//     required this.pressure,
//     required this.selectedDataset,
//     required this.controlConfirmation,
//     required this.onDatasetChanged,
//   });

//   List<FlSpot> _spots(List<double> x, List<double> y) {
//     List<FlSpot> s = [];
//     int min = x.length < y.length ? x.length : y.length;
//     for (int i = 0; i < min; i++) {
//       s.add(FlSpot(x[i], y[i]));
//     }
//     return s;
//   }

//   @override
//   Widget build(BuildContext context) {

//     final realSpots = _spots(iz.freq, iz.real);
//     final imagSpots = _spots(iz.freq, iz.imag);

//     if (connStatus != ConnectionStatus.connected) {
//       return const Center(
//         child: Text("Conecte ao dispositivo para ver os dados"),
//       );
//     }

//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: ListView(
//         children: [

//           SizedBox(
//             height:220,
//             child: GraphCard(
//               title: "Real(Z)",
//               unit: "Ω",
//               spots: realSpots,
//               color: Colors.red,
//             ),
//           ),

//           const SizedBox(height:12),

//           SizedBox(
//             height:220,
//             child: GraphCard(
//               title: "Imag(Z)",
//               unit: "Ω",
//               spots: imagSpots,
//               color: Colors.green,
//             ),
//           ),

//           const SizedBox(height:12),

//           GridView.count(
//             crossAxisCount:2,
//             shrinkWrap:true,
//             physics: const NeverScrollableScrollPhysics(),
//             children:[

//               Card(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children:[
//                     Text("Temp: ${temperature.toStringAsFixed(1)} °C"),
//                     Text("Pressão: $pressure g"),
//                   ],
//                 ),
//               ),

//               Card(
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: [
//                   TextField(
//                     decoration: const InputDecoration(
//                       labelText: "Comando",
//                       border: OutlineInputBorder(),
//                     ),
//                     controller: TextEditingController(text: selectedDataset),
//                     onSubmitted: (value) {
//                       if (value.isNotEmpty) {
//                         onDatasetChanged(value); // envia o texto direto
//                       }
//                     },
//                   ),
                  
//                 ],
//               ),
//             ),
//           )

//             ],
//           )
//         ],
//       ),
//     );
//   }
// }

class HomeScreen extends StatefulWidget {
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

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedDataset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FlSpot> _spots(List<double> x, List<double> y) {
    int min = x.length < y.length ? x.length : y.length;
    return List.generate(min, (i) => FlSpot(x[i], y[i]));
  }

  @override
  Widget build(BuildContext context) {
    final iz = widget.iz;

    final realSpots = _spots(iz.freq, iz.real);
    final imagSpots = _spots(iz.freq, iz.imag);
     final List<ChartData> realData =
    realSpots.map((e) => ChartData(e.x, e.y)).toList();
    final List<ChartData> imagData =
    imagSpots.map((e) => ChartData(e.x, e.y)).toList();
    
     if (widget.connStatus != ConnectionStatus.connected) {
       return const Center(
         child: Text("Conecte ao dispositivo para ver os dados"),
       );
     }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [

          if (iz.freq.isNotEmpty) ...[
            SizedBox(
              height: 220,
              child: GraphCard(
                title: "Real(Z)",
                unit: "Ω",
                data: realData,
                color: Colors.red,
                axis: 'logarithmic',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: GraphCard(
                title: "Imag(Z)",
                unit: "Ω",
                data: imagData,
                axis: "logarithmic",
                color: Colors.green,
              ),
            ),
          ] else ...[
            const Center(child: Text("Aguardando dados IZ...")),
            const SizedBox(height: 20),
          ],

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text("Temperatura",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${widget.temperature.toStringAsFixed(1)} °C"),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text("Pressão",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("${widget.pressure} g"),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text("Enviar comando"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    // onSubmitted: (value) {
                    //   if (value.isNotEmpty) {
                    //     widget.onDatasetChanged(value);
                    //   }
                    // },
                  ),
                  ElevatedButton(
                  onPressed: () {
                    final value = _controller.text;

                    if (value.isNotEmpty) {
                      String valueUpperCase = value.toUpperCase();
                      widget.onDatasetChanged(valueUpperCase);
                      print("Texto enviado: $valueUpperCase");
                    }
                  },
                  child: const Text("Enviar"),
                )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}