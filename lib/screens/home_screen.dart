import 'package:eprobe/screens/graph_view_screen.dart';
import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../widgets/graph_card.dart';
import '../controllers/iz_controller.dart';
import '../models/connection_status.dart';
import 'probe_config.dart';

class HomeScreen extends StatefulWidget {
  final BleConnectionStatus connStatus;
  final IzController iz;
  final double temperature;
  final int pressure;
  final String selectedDataset;
  final String controlConfirmation;
  final Function(String) onDatasetChanged;

  const HomeScreen({
    super.key,
    required this.connStatus,
    required this.iz,
    required this.temperature,
    required this.pressure,
    required this.selectedDataset,
    required this.controlConfirmation,
    required this.onDatasetChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _controller;
  

  // STREAM MODE

  bool streaming = false;
  bool paused = false;

  Future<void> startStream() async {

      if (streaming) return;

      streaming = true;

      paused = false;
      widget.onDatasetChanged("IKF");

      while (streaming) {

        if (!paused) {

          final value = _controller.text;

          if (value.isNotEmpty) {

            String valueUpperCase =
                value.toUpperCase();

            widget.onDatasetChanged(
              valueUpperCase,
            );

            // print("Comando enviado: $valueUpperCase");

          } 
        }

        await Future.delayed(
          const Duration(seconds: 5),
        );
      }
    }

    void stopStream() {
      setState(() {
        streaming = false;
        paused = false;
      });
    }

    void pauseStream() {

      paused = true;
    }

    void resumeStream() {

      paused = false;
    }

    void togglePause() {

      setState(() {
        paused = !paused;
      });
    }

  /// =========================
  /// TARA / COMPENSAÇÃO
  /// =========================

  List<double>? tareReal;
  List<double>? tareImag;

  bool applyTare = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedDataset,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _captureTare() {
    setState(() {
      tareReal = List.from(widget.iz.real);
      tareImag = List.from(widget.iz.imag);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Referência capturada"),
      ),
    );
  }

  void _clearTare() {
    setState(() {
      tareReal = null;
      tareImag = null;
      applyTare = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Compensação removida"),
      ),
    );
  }

  List<double> _applyTare(
    List<double> current,
    List<double>? tare,
  ) {
    if (!applyTare || tare == null) {
      return current;
    }

    int min = current.length < tare.length
        ? current.length
        : tare.length;

    return List.generate(
      min,
      (i) => current[i] - tare[i],
    );
  }

  // List<FlSpot> _spots(
  //   List<double> x,
  //   List<double> y,
  // ) {
  //   int min = x.length < y.length
  //       ? x.length
  //       : y.length;

  //   return List.generate(
  //     min,
  //     (i) => FlSpot(x[i], y[i]),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final iz = widget.iz;

    /// =========================
    /// DADOS COMPENSADOS
    /// =========================

    final correctedReal = _applyTare(
      iz.real,
      tareReal,
    );

    final correctedImag = _applyTare(
      iz.imag,
      tareImag,
    );

    // final realSpots = _spots(
    //   iz.freq,
    //   correctedReal,
    // );

    // final imagSpots = _spots(
    //   iz.freq,
    //   correctedImag,
    // );

    // final List<ChartData> realData =
    //     realSpots.map((e) => ChartData(e.x, e.y)).toList();

    // final List<ChartData> imagData =
    //     imagSpots.map((e) => ChartData(e.x, e.y)).toList();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [

          /// =========================
          /// GRÁFICOS E CONFIGRAÇÕES DA SONDA
          /// =========================
          
          DefaultTabController(
          length: 2,
          child: SizedBox(
            height: 500, // altura fixa
            child: Column(
              children: [

                const TabBar(
                  tabs: [
                    Tab(text: "Gráficos"),
                    Tab(text: "Sonda"),
                  ],
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      GraphViewScreen(
                        iz: iz,
                        realOverride: correctedReal,
                        imagOverride: correctedImag,
                        title: applyTare
                            ? "Medição Compensada"
                            : "Nova Medição",
                        xAxis: "logarithmic",
                      ),
                      Center(
                        child: IzConfigCard(config: iz.config,)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          
          const SizedBox(height: 10),

          /// =========================
          /// TEMPERATURA / PRESSÃO
          /// =========================

          Row(
            children: [

              Expanded(
                child: Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(12),
                    child: Column(
                      children: [

                        const Text(
                          "Temperatura",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          // "${widget.temperature.toStringAsFixed(1)} °C",
                          "N/A",
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(12),
                    child: Column(
                      children: [

                        const Text(
                          "Pressão",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          // "${widget.pressure} g",
                          "N/A",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// =========================
          /// COMANDOS
          /// =========================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Text(
                    "Enviar comando",
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(
                          border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!streaming) ...[
                        ElevatedButton(
                          onPressed: () {
                            final value =
                                _controller.text;

                            if (value.isNotEmpty) {
                              widget.onDatasetChanged(
                                value.toUpperCase(),
                              );
                            }
                          },

                          child: const Text(
                            "Comando Único",
                          ),
                        ),

                        ElevatedButton(

                          onPressed: () {
                            final value =
                                _controller.text;
                            if(value.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Digite um comando para iniciar o stream"),
                                ),
                              );
                            }
                            else {
                            startStream();
                            }
                            },

                          child: const Text(
                            "Modo Stream",
                          ),
                        ),
                      ],

                      if (streaming) ...[
                        ElevatedButton(
                          onPressed: togglePause,
                          child: Icon(
                            paused
                                ? Icons.play_arrow//"Resume"
                                : Icons.pause // "Pause",
                          ),
                        ),
                        ElevatedButton(
                          onPressed: stopStream,
                          child: Icon(Icons.stop),
                        ),
                      ],
                    ],
                  )
                ],
              ),
            ),
          ),

          /// =========================
          /// CARD DE COMPENSAÇÃO
          /// =========================

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Compensação",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [

                      Expanded(
                        child: ElevatedButton(
                          onPressed: iz.real.isEmpty
                              ? null
                              : _captureTare,
                          child: const Text(
                            "Tara",
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: tareReal == null
                              ? null
                              : _clearTare,
                          child: const Text("Limpar"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SwitchListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    value: applyTare,
                    onChanged: tareReal == null
                        ? null
                        : (v) {
                            setState(() {
                              applyTare = v;
                            });
                          },
                    title: const Text(
                      "Aplicar compensação",
                    ),
                  ),

                  if (tareReal != null)
                    const Text(
                      "Referência ativa",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}