// import 'package:eprobe/screens/graph_view_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// // import 'package:fl_chart/fl_chart.dart';
// // import '../widgets/graph_card.dart';
// import '../controllers/iz_controller.dart';
// import '../models/connection_status.dart';
// import 'probe_config.dart';

// class HomeScreen extends StatefulWidget {
//   final BleConnectionStatus connStatus;
//   final IzController iz;
//   final double temperature;
//   final double pressure;
//   final String selectedDataset;
//   final String controlConfirmation;
//   final Function(String) onDatasetChanged;

//   const HomeScreen({
//     super.key,
//     required this.connStatus,
//     required this.iz,
//     required this.temperature,
//     required this.pressure,
//     required this.selectedDataset,
//     required this.controlConfirmation,
//     required this.onDatasetChanged,
//   });

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   late TextEditingController _controller;
  

//   // STREAM MODE

//   bool streaming = false;
//   bool paused = false;

//   Future<void> startStream() async {

//       if (streaming) return;

//       streaming = true;

//       paused = false;
//       widget.onDatasetChanged("IKF");

//       while (streaming) {

//         if (!paused) {

//           final value = _controller.text;

//           if (value.isNotEmpty) {

//             String valueUpperCase =
//                 value.toUpperCase();

//             widget.onDatasetChanged(
//               valueUpperCase,
//             );

//             // print("Comando enviado: $valueUpperCase");

//           } 
//         }

//         await Future.delayed(
//           const Duration(seconds: 5),
//         );
//       }
//     }

//     void stopStream() {
//       setState(() {
//         streaming = false;
//         paused = false;
//       });
//     }

//     void pauseStream() {

//       paused = true;
//     }

//     void resumeStream() {

//       paused = false;
//     }

//     void togglePause() {

//       setState(() {
//         paused = !paused;
//       });
//     }

//   /// =========================
//   /// TARA / COMPENSAÇÃO
//   /// =========================

//   List<double>? tareReal;
//   List<double>? tareImag;

//   bool applyTare = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = TextEditingController(
//       text: widget.selectedDataset,
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _captureTare() {
//     setState(() {
//       tareReal = List.from(widget.iz.real);
//       tareImag = List.from(widget.iz.imag);
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Referência capturada"),
//       ),
//     );
//   }

//   void _clearTare() {
//     setState(() {
//       tareReal = null;
//       tareImag = null;
//       applyTare = false;
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text("Compensação removida"),
//       ),
//     );
//   }

//   List<double> _applyTare(
//     List<double> current,
//     List<double>? tare,
//   ) {
//     if (!applyTare || tare == null) {
//       return current;
//     }

//     int min = current.length < tare.length
//         ? current.length
//         : tare.length;

//     return List.generate(
//       min,
//       (i) => current[i] - tare[i],
//     );
//   }

//   // List<FlSpot> _spots(
//   //   List<double> x,
//   //   List<double> y,
//   // ) {
//   //   int min = x.length < y.length
//   //       ? x.length
//   //       : y.length;

//   //   return List.generate(
//   //     min,
//   //     (i) => FlSpot(x[i], y[i]),
//   //   );
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final iz = widget.iz;

//     /// =========================
//     /// DADOS COMPENSADOS
//     /// =========================

//     final correctedReal = _applyTare(
//       iz.real,
//       tareReal,
//     );

//     final correctedImag = _applyTare(
//       iz.imag,
//       tareImag,
//     );

//   // TODO: REVERTER APÓS DEBUG
//     // if(widget.connStatus != BleConnectionStatus.connected) {
//     //   return const Center(child: Text("Nenhum dispositivo conectado."));
//     // }

//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: ListView(
//         children: [
//           /// GRÁFICOS E CONFIGRAÇÕES DA SONDA
          
//           DefaultTabController(
//           length: 2,
//           child: SizedBox(
//             height: 580, // altura fixa
//             width: double.infinity,
//             child: Column(
//               children: [

//                 const TabBar(
//                   tabs: [
//                     Tab(text: "Gráficos"),
//                     Tab(text: "Sonda"),
//                   ],
//                 ),

//                 Expanded(
//                   // TODO: REVERTER DEPOIS
//                   // child: TabBarView(
//                   //   children: [
//                   //     GraphViewScreen(
//                   //       iz: iz,
//                   //       realOverride: correctedReal,
//                   //       imagOverride: correctedImag,
//                   //       title: applyTare
//                   //           ? "Medição Compensada"
//                   //           : "Nova Medição",
//                   //       xAxis: "logarithmic",
//                   //       historyMode: false,
//                   //     ),
//                   //     Center(
//                   //       child: IzConfigCard(config: iz.config,)
//                   //     ),
//                   //   ],
//                   // ),

// // MODO DE DEBUG (GRÁFICO ESTÁTICO)
//                   child: TabBarView(
//   children: [

//     FutureBuilder<String>(
//       future: rootBundle.loadString(
//         "assets/logs/log1.txt",
//       ),

//       builder: (context, snapshot) {

//         if (!snapshot.hasData) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         }

//         final staticIz = IzController();
//         staticIz.process(snapshot.data!);

//         return GraphViewScreen(
//           iz: staticIz,
//           title: applyTare
//               ? "Medição Compensada"
//               : "Nova Medição",
//           xAxis: "logarithmic",
//           historyMode: false,
//         );
//       },
//     ),

//     Center(
//       child: IzConfigCard(
//         config: iz.config,
//       ),
//     ),
//   ],
// ),
//                 ),
//               ],
//             ),
//           ),
//         ),
          
//           const SizedBox(height: 10),

//           /// =========================
//           /// TEMPERATURA / PRESSÃO
//           /// =========================

//           Row(
//             children: [

//               Expanded(
//                 child: Card(
//                   child: Padding(
//                     padding:
//                         const EdgeInsets.all(12),
//                     child: Column(
//                       children: [

//                         const Text(
//                           "Temperatura",
//                           style: TextStyle(
//                             fontWeight:
//                                 FontWeight.bold,
//                           ),
//                         ),

//                         Text(
//                           "${widget.temperature.toStringAsFixed(1)} °C",
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 8),

//               Expanded(
//                 child: Card(
//                   child: Padding(
//                     padding:
//                         const EdgeInsets.all(12),
//                     child: Column(
//                       children: [

//                         const Text(
//                           "Pressão",
//                           style: TextStyle(
//                             fontWeight:
//                                 FontWeight.bold,
//                           ),
//                         ),

//                         Text(
//                            "${widget.pressure} g",
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           /// =========================
//           /// COMANDOS
//           /// =========================

//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 children: [
//                   const Text(
//                     "Enviar comando",
//                   ),

//                   const SizedBox(height: 8),

//                   TextField(
//                     controller: _controller,
//                     decoration:
//                         const InputDecoration(
//                           border: OutlineInputBorder(),
//                     ),
//                   ),

//                   const SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment.spaceEvenly,
//                     children: [
//                       if (!streaming) ...[
//                         ElevatedButton(
//                           onPressed: () {
//                             final value =
//                                 _controller.text;

//                             if (value.isNotEmpty) {
//                               if(value.toLowerCase() != "iwf"){
//                                 widget.onDatasetChanged(value.toUpperCase());
//                               }
//                               else{
//                               widget.onDatasetChanged(
//                                 "IwF",
//                               );
//                               }
//                             }
//                           },

//                           child: const Text(
//                             "Comando Único",
//                           ),
//                         ),

//                         // ElevatedButton(

//                         //   onPressed: () {
//                         //     final value =
//                         //         _controller.text;
//                         //     if(value.isEmpty) {
//                         //         ScaffoldMessenger.of(context).showSnackBar(
//                         //         const SnackBar(
//                         //           content: Text("Digite um comando para iniciar o stream"),
//                         //         ),
//                         //       );
//                         //     }
//                         //     else {
//                         //     startStream();
//                         //     }
//                         //     },

//                         //   child: const Text(
//                         //     "Modo Stream",
//                         //   ),
//                         // ),
//                       ],

//                       if (streaming) ...[
//                         ElevatedButton(
//                           onPressed: togglePause,
//                           child: Icon(
//                             paused
//                                 ? Icons.play_arrow//"Resume"
//                                 : Icons.pause // "Pause",
//                           ),
//                         ),
//                         ElevatedButton(
//                           onPressed: stopStream,
//                           child: Icon(Icons.stop),
//                         ),
//                       ],
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           ),

//           /// =========================
//           /// CARD DE COMPENSAÇÃO
//           /// =========================

//           Card(
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.start,
//                 children: [

//                   const Text(
//                     "Compensação",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   Row(
//                     children: [

//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: iz.real.isEmpty
//                               ? null
//                               : _captureTare,
//                           child: const Text(
//                             "Tara",
//                           ),
//                         ),
//                       ),

//                       const SizedBox(width: 8),

//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: tareReal == null
//                               ? null
//                               : _clearTare,
//                           child: const Text("Limpar"),
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 12),

//                   SwitchListTile(
//                     contentPadding:
//                         EdgeInsets.zero,
//                     value: applyTare,
//                     onChanged: tareReal == null
//                         ? null
//                         : (v) {
//                             setState(() {
//                               applyTare = v;
//                             });
//                           },
//                     title: const Text(
//                       "Aplicar compensação",
//                     ),
//                   ),

//                   if (tareReal != null)
//                     const Text(
//                       "Referência ativa",
//                       style: TextStyle(
//                         color: Colors.green,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }
// }
import 'package:eprobe/screens/graph_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../widgets/graph_card.dart';
import '../controllers/iz_controller.dart';
import '../models/connection_status.dart';
import 'probe_config.dart';

class HomeScreen extends StatefulWidget {
  final BleConnectionStatus connStatus;
  final IzController iz;
  final double temperature;
  final double pressure;
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
  
  // Variáveis persistentes para o Modo Debug (Evita gargalo de build)
  Future<String>? _loadLogFuture;
  final IzController _staticIz = IzController();

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

    // Inicializa a leitura do log de debug estático uma única vez na memória
    _loadLogFuture = rootBundle.loadString("assets/logs/log1.txt").then((data) {
      
      // ALIMENTAÇÃO DO CONTROLLER DE DEBUG:
      // O método process(data) deve internamente popular o _staticIz.real, 
      // _staticIz.imag e principalmente o _staticIz.freq para o gráfico aceitar.
      // _staticIz.process(data);
      
      if (_staticIz.real.isNotEmpty) {
      if (widget.iz.freq.isNotEmpty && widget.iz.freq.length == _staticIz.real.length) {
        // Se o dispositivo real já tiver frequências correspondentes, clonamos elas
        _staticIz.freq = List.from(widget.iz.freq);
      } else {
        // Caso contrário, geramos uma lista de frequências lineares/sequenciais 
        // para bater com o tamanho dos pontos lidos do log e o gráfico não anular o plot
        _staticIz.freq = List.generate(
          _staticIz.real.length, 
          (index) => index.toDouble() * 100.0, // Ex: Passos de 100Hz em 100Hz
        );
      }
    }
      // Força a atualização da tela no primeiro carregamento para desenhar o gráfico com dados prontos
      if (mounted) {
        setState(() {});
      }
      return data;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _captureTare() {
    setState(() {
      // DEBUG MODE: Captura a tara baseando-se no arquivo estático para testes funcionarem na UI
      tareReal = List.from(_staticIz.real.isNotEmpty ? _staticIz.real : widget.iz.real);
      tareImag = List.from(_staticIz.imag.isNotEmpty ? _staticIz.imag : widget.iz.imag);
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

  @override
  Widget build(BuildContext context) {
    final iz = widget.iz;

    /// ====================================================
    /// DADOS COMPENSADOS (Calculados dinamicamente no Build)
    /// ====================================================
    
    // Para o ambiente de produção real (Bluetooth)
    final correctedReal = _applyTare(iz.real, tareReal);
    final correctedImag = _applyTare(iz.imag, tareImag);

    // Para o ambiente de Debug/Log estático funcionar com o Switch de compensação
    final debugCorrectedReal = _applyTare(_staticIz.real, tareReal);
    final debugCorrectedImag = _applyTare(_staticIz.imag, tareImag);

  // TODO: REVERTER APÓS DEBUG
    if(widget.connStatus != BleConnectionStatus.connected) {
      return const Center(child: Text("Nenhum dispositivo conectado."));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          
          /// ====================================================
          /// SEÇÃO DO GRÁFICO (Sempre visível e fixa no topo)
          /// ====================================================
          // SizedBox(
          //   height: 520, // Ajustado para dar espaço suficiente aos dois gráficos internos do GraphViewScreen
          //   width: double.infinity,
          //   child: FutureBuilder<String>(
          //     future: _loadLogFuture,
          //     builder: (context, snapshot) {
          //       if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          //         return const Center(
          //           child: CircularProgressIndicator(),
          //         );
          //       }

          //       // ADAPTAÇÃO DO CONTROLLER DE DEBUG:
          //       // Passamos o `_staticIz` no parâmetro `iz`. Assim, o gráfico original vai ler 
          //       // `widget.iz.freq` direto do arquivo de log, passando na validação de dados vazios.
          //       return GraphViewScreen(
          //         iz: _staticIz, 
          //         realOverride: debugCorrectedReal,
          //         imagOverride: debugCorrectedImag,
          //         title: applyTare
          //             ? "Medição Compensada"
          //             : "Nova Medição",
          //         xAxis: "logarithmic",
          //         historyMode: false,
          //       );
          //     },
          //   ),
          // ),

          // MODO PRODUÇÃO EM TEMPO REAL: 
          SizedBox(
            height: 520,
            width: double.infinity,
            child: GraphViewScreen(
              iz: iz,
              realOverride: correctedReal,
              imagOverride: correctedImag,
              title: applyTare ? "Medição Compensada" : "Nova Medição",
              xAxis: "logarithmic",
              historyMode: false,
            ),
          ),
          

          const SizedBox(height: 12),

          /// ====================================================
          /// CARD EXPANSIBLE PARA CONFIGURAÇÃO DA SONDA (Opção 2)
          /// ====================================================
          Card(
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              title: const Text(
                "Ver Configurações da Sonda",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: const Icon(Icons.tune),
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16, top: 4),
                  child: Center(
                    child: IzConfigCard(
                      config: iz.config,
                    ),
                  ),
                ),
              ],
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
                          "${widget.temperature.toStringAsFixed(1)} °C",
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
                           "${widget.pressure} g",
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
                              if(value.toLowerCase() != "iwf"){
                                widget.onDatasetChanged(value.toUpperCase());
                              }
                              else{
                              widget.onDatasetChanged(
                                "IwF",
                              );
                              }
                            }
                          },

                          child: const Text(
                            "Comando Único",
                          ),
                        ),
                      ],

                      if (streaming) ...[
                        ElevatedButton(
                          onPressed: togglePause,
                          child: Icon(
                            paused
                                ? Icons.play_arrow
                                : Icons.pause
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                          onPressed: (_staticIz.real.isEmpty && iz.real.isEmpty)
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
                      "Referência activa",
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