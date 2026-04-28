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

  const GraphCard({
    super.key,
    required this.title,
    required this.unit,
    required this.data,
    required this.color,
    required this.axis
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("Aguardando dados IZ..."));
    }

    return 
    SafeArea(child:
    Card(
      child: Column(
        children: [
          Text(title),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: (() {
              if (axis == 'logarithmic') {
                return LogarithmicAxis(minimum: 10);
              } else {
                return NumericAxis();
              }
            })(),
              primaryYAxis: NumericAxis(),

              series: <CartesianSeries>[
                LineSeries<ChartData, double>(
                  dataSource: data,
                  xValueMapper: (ChartData d, _) => d.x,
                  yValueMapper: (ChartData d, _) => d.y,
                  color: color,
                  width: 2,
                )
              ],
            ),
          ),
        ],
      ),
    )
    ); 
  }
}