import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartData {
  final double x;
  final double y;

  ChartData(this.x, this.y);
}

class GraphCard extends StatelessWidget {

  final String title;
  final String unit;
  final String axis;
  final List<ChartData> data;
  final Color color;
  final String xLabel;
  final String yLabel;

  const GraphCard({
    super.key,
    required this.title,
    required this.unit,
    required this.data,
    required this.color,
    required this.axis,
    required this.xLabel,
    required this.yLabel,
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


    final ZoomPanBehavior zoomPanBehavior =
        ZoomPanBehavior(
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
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ),

              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: SfCartesianChart(

                /// =========================
                /// ZOOM
                /// =========================

                zoomPanBehavior:
                    zoomPanBehavior,

                /// =========================
                /// EIXOS
                /// =========================

                primaryXAxis: (() {

                  if (axis ==
                      'logarithmic') {

                    return LogarithmicAxis(
                      minimum: 10,
                      title: AxisTitle(
                        text: xLabel,
                      ),
                    );
                  }

                  return NumericAxis(
                    title: AxisTitle(
                        text: xLabel,
                      ),
                  );

                })(),

                primaryYAxis:
                    NumericAxis(
                      title: AxisTitle(
                        text: yLabel,
                      ),
                    ),

                /// SÉRIE
                series: <CartesianSeries>[
                  LineSeries<
                      ChartData,
                      double>(

                    animationDuration: 500,
                    dataSource: data,
                    xValueMapper:
                        (ChartData d, _) =>
                            d.x,
                    yValueMapper:
                        (ChartData d, _) =>
                            d.y,
                    color: color,
                    width: 1,

                    markerSettings:
                        const MarkerSettings(
                      isVisible: false,
                    ),
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