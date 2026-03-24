import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphCard extends StatelessWidget {

  final String title;
  final String unit;
  final List<FlSpot> spots;
  final Color color;

  const GraphCard({
    super.key,
    required this.title,
    required this.unit,
    required this.spots,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {

    if (spots.isEmpty) {
      return const Center(child: Text("Aguardando dados IZ..."));
    }

    double minX = spots.map((e) => e.x).reduce((a,b)=>a<b?a:b);
    double maxX = spots.map((e) => e.x).reduce((a,b)=>a>b?a:b);
    double minY = spots.map((e) => e.y).reduce((a,b)=>a<b?a:b);
    double maxY = spots.map((e) => e.y).reduce((a,b)=>a>b?a:b);

    return Card(
      child: Column(
        children: [
          Text(title),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY * 0.95,
                maxY: maxY * 1.05,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}