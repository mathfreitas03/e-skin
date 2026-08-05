import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/models/chard_data.dart' show ChartData;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphCard extends StatelessWidget {
  final String unit;
  final String axis;
  final bool showImpedanceMagnitude;
  final List<ChartData> data;
  final List<ChartData>? magnitudeData;
  final List<ChartData>? nyquistData; // Recebe os pontos (Real, -Imag)
  final Color color;
  final String xLabel;
  final String yLabel;
  final bool isNyquist;

  const GraphCard({
    super.key,
    required this.unit,
    required this.data,
    required this.color,
    required this.axis,
    required this.xLabel,
    required this.yLabel,
    required this.showImpedanceMagnitude,
    this.magnitudeData,
    this.nyquistData,
    this.isNyquist = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeData = isNyquist ? (nyquistData ?? []) : data;

    if (activeData.isEmpty) {
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
                  isVisible: showImpedanceMagnitude && !isNyquist,
                  position: LegendPosition.top,
                ),
                primaryXAxis: (() {
                  if (!isNyquist && axis == 'logarithmic') {
                    return LogarithmicAxis(
                      minimum: 10,
                      title: AxisTitle(text: xLabel),
                    );
                  }
                  return NumericAxis(
                    title: AxisTitle(text: xLabel),
                  );
                })(),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: yLabel),
                ),
                series: <CartesianSeries>[
                  LineSeries<ChartData, double>(
                    name: isNyquist 
                        ? "Nyquist (R vs -Xc)" 
                        : LanguageHandler().translate('original_data_legend'),
                    animationDuration: 500,
                    dataSource: activeData,
                    xValueMapper: (ChartData d, _) => d.x,
                    yValueMapper: (ChartData d, _) => d.y,
                    color: color,
                    width: 1.5,
                    // markerSettings: MarkerSettings(
                    //   isVisible: isNyquist, // Exibe os pontos discretos de medição no arco
                    // ),
                  ),
                  if (showImpedanceMagnitude && magnitudeData != null && !isNyquist)
                    LineSeries<ChartData, double>(
                      name: LanguageHandler().translate('z_total'),
                      animationDuration: 500,
                      dataSource: magnitudeData!,
                      xValueMapper: (ChartData d, _) => d.x,
                      yValueMapper: (ChartData d, _) => d.y,
                      color: const Color(0xFF0000FF),
                      width: 1.5,
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