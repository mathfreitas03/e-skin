

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

// TODO REMOVER SEGUNDO COMENTARIO

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:eprobe/models/measurement_data.dart';
import 'package:eprobe/screens/stats_screen.dart';
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
  State<GraphViewScreen> createState() => _GraphViewScreenState();
}

class _GraphViewScreenState extends State<GraphViewScreen> {
  late String xAxis;

  /// =========================
  /// KEYS DOS GRÁFICOS
  /// =========================

  final GlobalKey realGraphKey = GlobalKey();
  final GlobalKey imagGraphKey = GlobalKey();
      
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
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final image = await boundary.toImage(
      pixelRatio: 3,
    );

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  /// ====================================================
  /// GERAÇÃO DO PACOTE DE DADOS (Imagens + Vetores)
  /// ====================================================
  Future<File?> _generateGraphPackage() async {
    try {
      final realValues = widget.realOverride ?? widget.iz.real;
      final imagValues = widget.imagOverride ?? widget.iz.imag;
      final freqValues = widget.iz.freq;

      final int min = [
        realValues.length,
        imagValues.length,
        freqValues.length,
      ].reduce((a, b) => a < b ? a : b);

      final buffer = StringBuffer();
      buffer.writeln("real imag freq");
      for (int i = 0; i < min; i++) {
        buffer.writeln("${realValues[i]} ${imagValues[i]} ${freqValues[i]}");
      }

      final realGraphBytes = await _captureWidget(realGraphKey);
      final imagGraphBytes = await _captureWidget(imagGraphKey);

      final archive = Archive();
      final rawData = utf8.encode(buffer.toString());

      archive.addFile(ArchiveFile("raw_data.dat", rawData.length, rawData));
      archive.addFile(ArchiveFile("real_graph.png", realGraphBytes.length, realGraphBytes));
      archive.addFile(ArchiveFile("imag_graph.png", imagGraphBytes.length, imagGraphBytes));

      final configData = utf8.encode(widget.iz.config.toString());
      archive.addFile(ArchiveFile("config.txt", configData.length, configData));

      final zipData = ZipEncoder().encode(archive);
      final dir = await getTemporaryDirectory();
      
      final file = File(
        "${dir.path}/graph_snapshot_${DateTime.now().millisecondsSinceEpoch}.zip",
      );
      await file.writeAsBytes(zipData);
      return file;

    } catch (e) {
      print("Erro ao gerar pacote do gráfico: $e");
      return null;
    }
  }

  /// =========================
  /// EXPORTAÇÃO COMPLETA SHARE
  /// =========================

  Future<void> _exportCompletePackage() async {
    final file = await _generateGraphPackage();
    if (file == null) return;

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Exportação eProbe",
        subject: "Dados e gráficos",
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao exportar: $e")),
      );
    }
  }

  List<FlSpot> _spots(
    List<double> x,
    List<double> y,
  ) {
    int min = x.length < y.length ? x.length : y.length;

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
          title: const Text("Escala do eixo X"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text("Logarítmica"),
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
                title: const Text("Numérica"),
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
    final realValues = widget.realOverride ?? widget.iz.real;
    final imagValues = widget.imagOverride ?? widget.iz.imag;

    final realSpots = _spots(widget.iz.freq, realValues);
    final imagSpots = _spots(widget.iz.freq, imagValues);

    final List<ChartData> realData = realSpots.map((e) => ChartData(e.x, e.y)).toList();
    final List<ChartData> imagData = imagSpots.map((e) => ChartData(e.x, e.y)).toList();

    if (widget.iz.freq.isEmpty) {
      return const Center(
        child: Text("Nenhum dado encontrado"),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          /// =========================
          /// HEADER
          /// =========================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _showAxisDialog,
                    icon: const Icon(Icons.settings),
                  ),
                  IconButton(
                    onPressed: _exportCompletePackage,
                    icon: const Icon(Icons.share),
                  ),
                  
                  // if (!widget.historyMode) ...[
                  //   IconButton(
                  //     onPressed: () async {
                  //       // 1. Mostra um feedback de processamento para o usuário
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(
                  //           content: Text("Capturando gráficos e compilando dataset..."),
                  //           duration: Duration(milliseconds: 800),
                  //         ),
                  //       );

                  //       // 2. Transforma o estado do gráfico completo em um arquivo físico (.zip contendo fotos e raw_data)
                  //       final File? packageFile = await _generateGraphPackage();

                  //       if (packageFile != null) {
                  //         // 3. LOGICA DO MAPA INTERATIVO:
                  //         // Aqui enviamos o arquivo gerado e o ID do dataset para o seu gerenciador de mapas.
                  //         print("------------------------------------------");
                  //         print("SALVANDO SNAPSHOT COMPLETO NO DATASET/MAPA");
                  //         print("Dataset Alvo: ${widget.title}");
                  //         print("Caminho do Arquivo Gerado: ${packageFile.path}");
                  //         print("------------------------------------------");

                  //         // TODO: Chame aqui a sua função global do mapa ou banco de dados, enviando o `packageFile`.
                  //         // Exemplo: MapController.saveGraphToSelectedMarker(file: packageFile, dataset: widget.title);

                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             backgroundColor: Colors.green,
                  //             content: Text("Gráfico salvo com sucesso no mapa (${widget.title})!"),
                  //           ),
                  //         );
                  //       }
                  //     },
                  //     icon: const Icon(Icons.save),
                  //   ),
                  // ]
                  if (!widget.historyMode) ...[
  IconButton(
    onPressed: () {
      // 1. Captura os valores atuais considerando possíveis overrides/taras
      final currentReal = widget.realOverride ?? widget.iz.real;
      final currentImag = widget.imagOverride ?? widget.iz.imag;
      final currentFreq = widget.iz.freq;

      // 2. Instancia o objeto de dados estruturados com um ID único baseado em timestamp
      final measurementToSave = MeasurementData(
        id: "m_captured_${DateTime.now().millisecondsSinceEpoch}",
        timestamp: DateTime.now(),
        real: List<double>.from(currentReal),
        imag: List<double>.from(currentImag),
        freq: List<double>.from(currentFreq),
      );

      // Feedback visual rápido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preparando dados. Selecione o dataset a seguir..."),
          duration: Duration(milliseconds: 600),
        ),
      );

      // 3. Navega para a StatsScreen passando a medição que acabamos de capturar do gráfico
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatsScreen(
            currentMeasurementToSave: measurementToSave,
          ),
        ),
      );
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
                  child: RepaintBoundary(
                    key: realGraphKey,
                    child: GraphCard(
                      title: "Real(Z)",
                      unit: "Ω",
                      data: realData,
                      color: Colors.red,
                      axis: xAxis,
                      xLabel: "Frequência (Hz)",
                      yLabel: "Resistência (Ω)",
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: RepaintBoundary(
                    key: imagGraphKey,
                    child: GraphCard(
                      title: "Imag(Z)",
                      unit: "Ω",
                      data: imagData,
                      color: Colors.green,
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