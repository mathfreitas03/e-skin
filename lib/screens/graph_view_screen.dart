import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../controllers/iz_controller.dart';
import '../widgets/graph_card.dart';

class GraphViewScreen extends StatefulWidget {
  final IzController iz;
  final String title;
  final String xAxis;

  /// Dados opcionais sobrescritos
  /// (utilizados para compensação/tara)
  final List<double>? realOverride;
  final List<double>? imagOverride;

  const GraphViewScreen({
    super.key,
    required this.iz,
    required this.title,
    required this.xAxis,
    this.realOverride,
    this.imagOverride,
  });

  @override
  State<GraphViewScreen> createState() =>
      _GraphViewScreenState();
}

class _GraphViewScreenState
    extends State<GraphViewScreen> {

  late String xAxis;

  @override
  void initState() {
    super.initState();
    xAxis = widget.xAxis;
  }

  List<FlSpot> _spots(
    List<double> x,
    List<double> y,
  ) {
    int min = x.length < y.length
        ? x.length
        : y.length;

    return List.generate(
      min,
      (i) => FlSpot(x[i], y[i]),
    );
  }

  void _showAxisDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Escala do eixo X",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              RadioListTile<String>(
                title: const Text(
                  "Logarítmica",
                ),
                value: 'logarithmic',
                groupValue: xAxis,
                onChanged: (value) {
                  setState(() {
                    xAxis = value!;
                  });

                  Navigator.pop(context);
                },
              ),

              RadioListTile<String>(
                title: const Text(
                  "Numérica",
                ),
                value: 'numeric',
                groupValue: xAxis,
                onChanged: (value) {
                  setState(() {
                    xAxis = value!;
                  });

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

    /// =========================
    /// DADOS UTILIZADOS
    /// =========================

    final realValues =
        widget.realOverride ?? widget.iz.real;

    final imagValues =
        widget.imagOverride ?? widget.iz.imag;

    /// =========================
    /// PONTOS
    /// =========================

    final realSpots = _spots(
      widget.iz.freq,
      realValues,
    );

    final imagSpots = _spots(
      widget.iz.freq,
      imagValues,
    );

    /// =========================
    /// CHART DATA
    /// =========================

    final List<ChartData> realData =
        realSpots
            .map(
              (e) => ChartData(e.x, e.y),
            )
            .toList();

    final List<ChartData> imagData =
        imagSpots
            .map(
              (e) => ChartData(e.x, e.y),
            )
            .toList();

    /// =========================
    /// SEM DADOS
    /// =========================

    if (widget.iz.freq.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum dado encontrado",
        ),
      );
    }

    /// =========================
    /// VIEW
    /// =========================

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [

          /// =========================
          /// HEADER
          /// =========================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [

              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: _showAxisDialog,
                icon: const Icon(
                  Icons.settings,
                ),
              ),
            ],
          ),

          /// =========================
          /// GRÁFICOS
          /// =========================

          Expanded(
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
        ],
      ),
    );
  }
}