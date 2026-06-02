

// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// import '../controllers/iz_controller.dart';
// import '../widgets/graph_card.dart';

// import 'dart:io';

// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';

// class GraphViewScreen extends StatefulWidget {
//   final IzController iz;
//   final String title;
//   final String xAxis;

//   /// Dados opcionais sobrescritos
//   /// (utilizados para compensação/tara)
//   final List<double>? realOverride;
//   final List<double>? imagOverride;

//   const GraphViewScreen({
//     super.key,
//     required this.iz,
//     required this.title,
//     required this.xAxis,
//     this.realOverride,
//     this.imagOverride,
//   });

//   @override
//   State<GraphViewScreen> createState() =>
//       _GraphViewScreenState();
// }

// class _GraphViewScreenState
//     extends State<GraphViewScreen> {

//   late String xAxis;

//   @override
//   void initState() {
//     super.initState();
//     xAxis = widget.xAxis;
//   }
//    Future<void> _shareGraphData() async {

//   try {

//     final realValues =
//         widget.realOverride ?? widget.iz.real;

//     final imagValues =
//         widget.imagOverride ?? widget.iz.imag;

//     final freqValues = widget.iz.freq;

//     final int min = [
//       realValues.length,
//       imagValues.length,
//       freqValues.length,
//     ].reduce((a, b) => a < b ? a : b);

//     final buffer = StringBuffer();

//     /// HEADER
//     buffer.writeln("real imag freq");

//     /// DADOS
//     for (int i = 0; i < min; i++) {

//       buffer.writeln(
//         "${realValues[i]} "
//         "${imagValues[i]} "
//         "${freqValues[i]}",
//       );
//     }

//     /// ARQUIVO TEMPORÁRIO
//     final dir =
//         await getTemporaryDirectory();

//     final file = File(
//       "${dir.path}/eprobe_data_${DateTime.now().millisecondsSinceEpoch % 1000000}.dat",
//     );

//     await file.writeAsString(
//       buffer.toString(),
//     );

//     /// SHARE SHEET NATIVO
//     await Share.shareXFiles(
//       [XFile(file.path)],
//       text: "Dados exportados do gráfico",
//       subject: "Exportação eProbe",
//     );

//   } catch (e) {

//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           "Erro ao compartilhar: $e",
//         ),
//       ),
//     );
//   }
// }

//   List<FlSpot> _spots(
//     List<double> x,
//     List<double> y,
//   ) {
//     int min = x.length < y.length
//         ? x.length
//         : y.length;

//     return List.generate(
//       min,
//       (i) => FlSpot(x[i], y[i]),
//     );
//   }

//   void _showAxisDialog() {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text(
//             "Escala do eixo X",
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [

//               RadioListTile<String>(
//                 title: const Text(
//                   "Logarítmica",
//                 ),
//                 value: 'logarithmic',
//                 groupValue: xAxis,
//                 onChanged: (value) {
//                   setState(() {
//                     xAxis = value!;
//                   });

//                   Navigator.pop(context);
//                 },
//               ),

//               RadioListTile<String>(
//                 title: const Text(
//                   "Numérica",
//                 ),
//                 value: 'numeric',
//                 groupValue: xAxis,
//                 onChanged: (value) {
//                   setState(() {
//                     xAxis = value!;
//                   });

//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           ),
//         );
//       },
//     );

//   }

//   @override
//   Widget build(BuildContext context) {

//     /// =========================
//     /// DADOS UTILIZADOS
//     /// =========================

//     final realValues =
//         widget.realOverride ?? widget.iz.real;

//     final imagValues =
//         widget.imagOverride ?? widget.iz.imag;

//     /// =========================
//     /// PONTOS
//     /// =========================

//     final realSpots = _spots(
//       widget.iz.freq,
//       realValues,
//     );

//     final imagSpots = _spots(
//       widget.iz.freq,
//       imagValues,
//     );

//     /// =========================
//     /// CHART DATA
//     /// =========================

//     final List<ChartData> realData =
//         realSpots
//             .map(
//               (e) => ChartData(e.x, e.y),
//             )
//             .toList();

//     final List<ChartData> imagData =
//         imagSpots
//             .map(
//               (e) => ChartData(e.x, e.y),
//             )
//             .toList();

//     /// =========================
//     /// SEM DADOS
//     /// =========================

//     if (widget.iz.freq.isEmpty) {
//       return const Center(
//         child: Text(
//           "Nenhum dado encontrado",
//         ),
//       );
//     }

//     /// =========================
//     /// VIEW
//     /// =========================

//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Column(
//         children: [

//           /// =========================
//           /// HEADER
//           /// =========================

//           Row(
//             mainAxisAlignment:
//                 MainAxisAlignment.spaceBetween,
//             children: [

//               Text(
//                 widget.title,
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               Row(
//                 children: [
//                 IconButton(
//                 onPressed: _showAxisDialog,
//                 icon: const Icon(
//                   Icons.settings,
//                 ),
//               ),
//               IconButton(
//                 onPressed: _shareGraphData,
//                 icon: const Icon(
//                   Icons.share,
//                 ),
//               )
//               ]),
//             ],
//           ),

//           /// =========================
//           /// GRÁFICOS
//           /// =========================

//           Expanded(
//             child: ListView(
//               children: [

//                 SizedBox(
//                   height: 220,
//                   child: GraphCard(
//                     title: "Real(Z)",
//                     unit: "Ω",
//                     data: realData,
//                     color: Colors.red,
//                     axis: xAxis,
//                   ),
//                 ),

//                 const SizedBox(height: 12),

//                 SizedBox(
//                   height: 220,
//                   child: GraphCard(
//                     title: "Imag(Z)",
//                     unit: "Ω",
//                     data: imagData,
//                     color: Colors.green,
//                     axis: xAxis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final bool historyMode;

  const GraphViewScreen({
    super.key,
    required this.iz,
    required this.title,
    required this.xAxis,
    required this.historyMode,
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

  /// =========================
  /// KEYS DOS GRÁFICOS
  /// =========================

  final GlobalKey realGraphKey =
      GlobalKey();

  final GlobalKey imagGraphKey =
      GlobalKey();
      
  @override
  void initState() {
    super.initState();
    xAxis = widget.xAxis;
  }

  /// =========================
  /// CAPTURA WIDGET -> PNG
  /// =========================

  Future<Uint8List> _captureWidget(
    GlobalKey key,
  ) async {

    final boundary =
        key.currentContext!
            .findRenderObject()
                as RenderRepaintBoundary;

    final image = await boundary.toImage(
      pixelRatio: 3,
    );

    final byteData =
        await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!
        .buffer
        .asUint8List();
  }

  /// =========================
  /// EXPORTAÇÃO COMPLETA
  /// =========================

  Future<void>
      _exportCompletePackage() async {

    try {

      final realValues =
          widget.realOverride ??
              widget.iz.real;

      final imagValues =
          widget.imagOverride ??
              widget.iz.imag;

      final freqValues =
          widget.iz.freq;

      final int min = [
        realValues.length,
        imagValues.length,
        freqValues.length,
      ].reduce(
        (a, b) => a < b ? a : b,
      );

      /// =========================
      /// RAW DATA
      /// =========================

      final buffer = StringBuffer();

      buffer.writeln(
        "real imag freq",
      );

      for (int i = 0; i < min; i++) {

        buffer.writeln(
          "${realValues[i]} "
          "${imagValues[i]} "
          "${freqValues[i]}",
        );
      }

      /// =========================
      /// CAPTURA DOS GRÁFICOS
      /// =========================

      final realGraphBytes =
          await _captureWidget(
        realGraphKey,
      );

      final imagGraphBytes =
          await _captureWidget(
        imagGraphKey,
      );

      /// =========================
      /// ZIP
      /// =========================

      final archive = Archive();

      final rawData =
          utf8.encode(
        buffer.toString(),
      );

      archive.addFile(
        ArchiveFile(
          "raw_data.dat",
          rawData.length,
          rawData,
        ),
      );

      archive.addFile(
        ArchiveFile(
          "real_graph.png",
          realGraphBytes.length,
          realGraphBytes,
        ),
      );

      archive.addFile(
        ArchiveFile(
          "imag_graph.png",
          imagGraphBytes.length,
          imagGraphBytes,
        ),
      );

      /// =========================
      /// CONFIG
      /// =========================

      final configData =
          utf8.encode(
        widget.iz.config.toString(),
      );

      archive.addFile(
        ArchiveFile(
          "config.txt",
          configData.length,
          configData,
        ),
      );

      /// =========================
      /// GERA ZIP
      /// =========================

      final zipData =
          ZipEncoder()
              .encode(archive);

      final dir =
          await getTemporaryDirectory();

      final file = File(
        "${dir.path}/eprobe_export_${DateTime.now().millisecondsSinceEpoch % 1000000}.zip",
      );

      await file.writeAsBytes(
        zipData,
      );

      /// =========================
      /// SHARE SHEET
      /// =========================

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            "Exportação eProbe",
        subject:
            "Dados e gráficos",
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Erro ao exportar: $e",
          ),
        ),
      );
    }
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
      (i) => FlSpot(
        x[i],
        y[i],
      ),
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
            mainAxisSize:
                MainAxisSize.min,

            children: [

              RadioListTile<String>(
                title: const Text(
                  "Logarítmica",
                ),

                value:
                    'logarithmic',

                groupValue: xAxis,

                onChanged: (value) {

                  setState(() {
                    xAxis = value!;
                  });

                  Navigator.pop(
                    context,
                  );
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

                  Navigator.pop(
                    context,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {

    /// =========================
    /// DADOS UTILIZADOS
    /// =========================

    final realValues =
        widget.realOverride ??
            widget.iz.real;

    final imagValues =
        widget.imagOverride ??
            widget.iz.imag;

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
              (e) => ChartData(
                e.x,
                e.y,
              ),
            )
            .toList();

    final List<ChartData> imagData =
        imagSpots
            .map(
              (e) => ChartData(
                e.x,
                e.y,
              ),
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
      padding:
          const EdgeInsets.all(12),

      child: Column(
        children: [

          /// =========================
          /// HEADER
          /// =========================

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [

              Text(
                widget.title,

                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              Row(
                children: [

                  IconButton(
                    onPressed:
                        _showAxisDialog,

                    icon: const Icon(
                      Icons.settings,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        _exportCompletePackage,

                    icon: const Icon(
                      Icons.share,
                    ),
                  ),
                  // 
                  if (!widget.historyMode) ...[
                    IconButton(
                      onPressed: _exportCompletePackage,
                      icon: const Icon(Icons.share),
                    ),
                    IconButton(
                      onPressed: () {
                        print("Salvar dados internamente (ainda não implementado)");
                      },
                      icon: const Icon(Icons.save),
                    ),
                  ]
                ],
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

                  child:
                      RepaintBoundary(
                    key: realGraphKey,

                    child: GraphCard(
                      title:
                          "Real(Z)",

                      unit: "Ω",

                      data: realData,

                      color:
                          Colors.red,

                      axis: xAxis,
                      xLabel: "Frequência (Hz)",
                      yLabel: "Resistência (Ω)",
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                SizedBox(
                  height: 220,

                  child:
                      RepaintBoundary(
                    key: imagGraphKey,

                    child: GraphCard(
                      title:
                          "Imag(Z)",

                      unit: "Ω",

                      data: imagData,

                      color:
                          Colors.green,

                      axis: xAxis,
                      xLabel: "Frequência (Hz)",
                      yLabel: "Capacitância (pF)",
                    ),
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