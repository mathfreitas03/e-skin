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
                // minY: minY * 0.95,
                // maxY: maxY * 1.05,
                minY: minY - (maxY - minY) * 0.1,
                maxY: maxY + (maxY - minY) * 0.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    
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

// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// class GraphCard extends StatelessWidget {
//   final String title;
//   final String unit;
//   final List<FlSpot> spots;
//   final Color color;

//   const GraphCard({
//     super.key,
//     required this.title,
//     required this.unit,
//     required this.spots,
//     required this.color,
//   });

//   String formatX(double value) {
//     if (value >= 1e6) return "${(value / 1e6).toStringAsFixed(1)}M";
//     if (value >= 1e3) return "${(value / 1e3).toStringAsFixed(0)}K";
//     return value.toStringAsFixed(0);
//   }

//   String formatY(double value) {
//     return value.toStringAsFixed(1);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (spots.isEmpty) {
//       return const Center(child: Text("Aguardando dados IZ..."));
//     }

//     // 🔥 X normal
//     double minX = spots.map((e) => e.x).reduce((a, b) => a < b ? a : b);
//     double maxX = spots.map((e) => e.x).reduce((a, b) => a > b ? a : b);

//     // 🔥 Y com percentil (ANTI-OUTLIER)
//     List<double> ys = spots.map((e) => e.y).toList()..sort();
//     int n = ys.length;

//     double minY = ys[(n * 0.05).floor()];
//     double maxY = ys[(n * 0.95).floor()];

//     double range = maxY - minY;

//     minY -= range * 0.1;
//     maxY += range * 0.1;

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(8),
//         child: Column(
//           children: [
//             Text(title),
//             const SizedBox(height: 8),
//             Expanded(
//               child: LineChart(
//                 LineChartData(
//                   minX: minX,
//                   maxX: maxX,
//                   minY: minY,
//                   maxY: maxY,

//                   // 🔥 evita desenhar fora da área
//                   clipData: FlClipData.all(),

//                   gridData: FlGridData(show: true),

//                   titlesData: FlTitlesData(
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         interval: (maxX - minX) / 4,
//                         reservedSize: 30,
//                         getTitlesWidget: (value, meta) {
//                           return Padding(
//                             padding: const EdgeInsets.only(top: 6),
//                             child: Text(
//                               formatX(value),
//                               style: const TextStyle(fontSize: 10),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         interval: (maxY - minY) / 4,
//                         reservedSize: 42,
//                         getTitlesWidget: (value, meta) {
//                           return Text(
//                             formatY(value),
//                             style: const TextStyle(fontSize: 10),
//                           );
//                         },
//                       ),
//                     ),
//                     rightTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                     topTitles: AxisTitles(
//                       sideTitles: SideTitles(showTitles: false),
//                     ),
//                   ),

//                   borderData: FlBorderData(show: true),

//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: spots,
//                       isCurved: true,
//                       color: color,
//                       barWidth: 2,
//                       dotData: FlDotData(show: false),
//                       belowBarData: BarAreaData(show: false),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }