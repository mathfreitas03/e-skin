import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:eprobe/views/bioinsights_card.dart';
import 'package:archive/archive.dart';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/models/chard_data.dart';
import 'package:eprobe/models/measurement_point.dart';
import 'package:eprobe/views/stats_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../bioimpedance_utils/impedance_magnitude.dart';
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
  late bool showMagnitude;

  /// KEYS DOS GRÁFICOS
  final GlobalKey realGraphKey = GlobalKey();
  final GlobalKey imagGraphKey = GlobalKey();
      
  @override
  void initState() {
    super.initState();
    xAxis = widget.xAxis;
    showMagnitude = true;
  }

  // Conversão de Widget para PNG
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
        SnackBar(content: Text("${LanguageHandler().translate('export_failed')}: $e")),
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(LanguageHandler().translate('axis_scale')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(LanguageHandler().translate('logarithmic')),
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
                    title: Text(LanguageHandler().translate('linear')),
                    value: 'numeric',
                    groupValue: xAxis,
                    onChanged: (value) {
                      setState(() {
                        xAxis = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(), 
                  Row(
                    children: [
                      Switch(
                        value: showMagnitude,
                        onChanged: (_) {
                          setDialogState(() {
                            showMagnitude = !showMagnitude;
                          });
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(LanguageHandler().translate('enable_magnitude')),
                    ],
                  )
                ],
              ),
            );
          },
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
    final List<ChartData> magnitudeData = calcularMagnitude(realData, imagData);

    // final List<ChartData> nyquistSpots = List.generate(
    // realData.length < imagData.length ? realData.length : imagData.length,
    // (i) => ChartData(
    //   realData[i].y,            // Eixo X: Real (Resistência R)
    //   imagData[i].y * -1      // Eixo Y: -Imag (Reatância Xc positiva)
    // ),
    // );

    if (widget.iz.freq.isEmpty) {
      return Center(
        child: Text(LanguageHandler().translate('no_data_found')),
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
                  
                  if (!widget.historyMode) ...[
                    IconButton(
                      onPressed: () {
                        final currentReal = widget.realOverride ?? widget.iz.real;
                        final currentImag = widget.imagOverride ?? widget.iz.imag;
                        final currentFreq = widget.iz.freq;

                        final measurementToSave = MeasurementPoint(
                          id: "m_captured_${DateTime.now().millisecondsSinceEpoch}",
                          real: List<double>.from(currentReal),
                          imag: List<double>.from(currentImag),
                          freq: List<double>.from(currentFreq),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(LanguageHandler().translate('preparing_data')),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );

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
          /// GRÁFICOS E INSIGHTS
          /// =========================
          Expanded(
            child: ListView(
              children: [
                SizedBox(
                  height: 220,
                  child: RepaintBoundary(
                    key: realGraphKey,
                    child: GraphCard(
                      unit: "Ω",
                      data: realData,
                      color: Colors.red,
                      axis: xAxis,
                      xLabel: "${LanguageHandler().translate('real_part')} vs ${LanguageHandler().translate('frequency')} (Hz)",
                      yLabel: "Real (Ω)",
                      showImpedanceMagnitude: showMagnitude,
                      magnitudeData: magnitudeData,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: RepaintBoundary(
                    key: imagGraphKey,
                    child: GraphCard(
                      unit: "Ω",
                      data: imagData,
                      color: Colors.green,
                      axis: xAxis,
                      xLabel: "${LanguageHandler().translate('imaginary_part')} vs ${LanguageHandler().translate('frequency')} (Hz)",
                      yLabel: "Imag (Ω)",
                      showImpedanceMagnitude: false,
                      magnitudeData: magnitudeData,
                    ),
                  ),
                ),
              // TODO: Ajeitar gráfico de Nyquist
              //   SizedBox(
              //   height: 220,
              //   child: GraphCard(
              //     unit: "Ω",
              //     data: const [], // Vazio pois usa nyquistData
              //     nyquistData: nyquistSpots,
              //     isNyquist: true,
              //     color: Colors.purple,
              //     axis: "numeric",
              //     xLabel: "Real - R (Ω)",
              //     yLabel: "-Imag - Xc (Ω)",
              //     showImpedanceMagnitude: false,
              //   ),
              // ),
                const SizedBox(height: 12),
                
                /// =========================
                /// CARD DE INSIGHTS DA BIA
                /// =========================
                BioinsightsCard(
                  realData: realData,
                  imaginaryData: imagData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}