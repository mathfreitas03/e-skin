import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/iz_controller.dart';
import '../widgets/graph_card.dart';

class GraphViewScreen extends StatefulWidget {
  final IzController iz;
  final String title;
  final String xAxis;

  const GraphViewScreen({
    super.key,
    required this.iz,
    required this.title,
    required this.xAxis,
  });

  @override
  State<GraphViewScreen> createState() => _GraphViewScreenState();
}

class _GraphViewScreenState extends State<GraphViewScreen> {
  late String xAxis;

  @override
  void initState() {
    super.initState();
    xAxis = widget.xAxis;
  }

  List<FlSpot> _spots(List<double> x, List<double> y) {
    List<FlSpot> s = [];
    int min = x.length < y.length ? x.length : y.length;

    for (int i = 0; i < min; i++) {
      s.add(FlSpot(x[i], y[i]));
    }

    return s;
  }

  void _showAxisDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Escala do eixo X"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text("Logarítmica"),
                value: 'logarithmic',
                groupValue: xAxis,
                onChanged: (value) {
                  setState(() => xAxis = value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text("Numérica"),
                value: 'numeric',
                groupValue: xAxis,
                onChanged: (value) {
                  setState(() => xAxis = value!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final realSpots = _spots(widget.iz.freq, widget.iz.real);
    final imagSpots = _spots(widget.iz.freq, widget.iz.imag);

    final List<ChartData> realData =
        realSpots.map((e) => ChartData(e.x, e.y)).toList();

    final List<ChartData> imagData =
        imagSpots.map((e) => ChartData(e.x, e.y)).toList();

    if (widget.iz.freq.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text("Nenhum dado encontrado no arquivo"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _showAxisDialog,
            icon: const Icon(Icons.settings),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            SizedBox(
              height: 220,
              child: GraphCard(
                title: "Real(Z)",
                unit: "Ω",
                data: realData,
                color: Colors.red,
                axis: xAxis,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: GraphCard(
                title: "Imag(Z)",
                unit: "Ω",
                data: imagData,
                color: Colors.green,
                axis: xAxis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}