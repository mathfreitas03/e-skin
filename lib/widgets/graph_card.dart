import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/models/chard_data.dart' show ChartData;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphCard extends StatelessWidget {
  final String unit;
  final String axis;
  final bool showImpedanceMagnitude;
  final List<ChartData> data;
  final List<ChartData>? magnitudeData; // Alterado para aceitar nulo caso showImpedanceMagnitude seja falso
  final Color color;
  final String xLabel;
  final String yLabel;

  const GraphCard({
    super.key,
    required this.unit,
    required this.data,
    required this.color,
    required this.axis,
    required this.xLabel,
    required this.yLabel,
    required this.showImpedanceMagnitude,
    this.magnitudeData, // Incluído no construtor
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          "Aguardando dados IZ...",
        ),
      );
    }

    final ZoomPanBehavior zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true,
      zoomMode: ZoomMode.xy,
    );

    return SafeArea(
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
            ),
            Expanded(
              child: SfCartesianChart(
                zoomPanBehavior: zoomPanBehavior,

                legend: Legend(
                  isVisible: showImpedanceMagnitude,
                  position: LegendPosition.top, // Exibe uma pequena legenda no topo do gráfico
                ),


                primaryXAxis: (() {
                  if (axis == 'logarithmic') {
                    return LogarithmicAxis(
                      minimum: 10,
                      // maximum: 1000000,
                      title: AxisTitle(text: xLabel),
                    );
                  }
                  return NumericAxis(
                    // maximum: 1000000,
                    title: AxisTitle(text: xLabel),
                  );
                })(),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: yLabel),
                ),

                /// =========================
                /// SÉRIES (LINHAS)
                /// =========================
                series: <CartesianSeries>[
                  // Linha Principal Original
                  LineSeries<ChartData, double>(
                    name: LanguageHandler().translate('original_data_legend'), // Nome que aparecerá na legenda
                    animationDuration: 500,
                    dataSource: data,
                    xValueMapper: (ChartData d, _) => d.x,
                    yValueMapper: (ChartData d, _) => d.y,
                    color: color,
                    width: 1,
                    markerSettings: const MarkerSettings(isVisible: false),
                  ),
                  
                  // Linha Adicional Condicional de Magnitude
                  if (showImpedanceMagnitude && magnitudeData != null)
                    LineSeries<ChartData, double>(
                      name: LanguageHandler().translate('z_total'), // Nome na legenda para a segunda reta
                      animationDuration: 500,
                      dataSource: magnitudeData!,
                      xValueMapper: (ChartData d, _) => d.x,
                      yValueMapper: (ChartData d, _) => d.y,
                      color: const Color(0xFF0000FF), // Cor diferente para distinguir a nova reta
                      width: 1, // Levemente mais grossa para destaque
                      markerSettings: const MarkerSettings(isVisible: false),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}