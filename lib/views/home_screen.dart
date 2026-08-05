
import 'package:eprobe/controllers/app_configs.dart';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/views/graph_view_screen.dart';
import 'package:flutter/material.dart';
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
  bool wasConnected = false;
  // Future<String>? _loadLogFuture;
  final IzController _staticIz = IzController();

  // STREAM MODE

  bool streaming = false;
  bool paused = false;

  Future<void> startStream() async {

      if (streaming) return;
      if (widget.connStatus != BleConnectionStatus.connected) return;
      
      streaming = true;

      paused = false;
      
      await widget.onDatasetChanged("IKF");
      await Future.delayed(const Duration(seconds: 2));

      while (streaming) {

        if (!paused) {
          // Enquanto a sonda ainda está limitada, deixar isso estático.
          // print("--- Iniciando ciclo de leitura ---");
          await Future.delayed(const Duration(milliseconds: 800));
          await widget.onDatasetChanged("INF");
          await Future.delayed(const Duration(milliseconds: 800));
          await widget.onDatasetChanged("IZ1000000F");
        await Future.delayed(
          const Duration(seconds: 4),
        );

          // final value = _controller.text;
          // final value = "IZ1000000F";
          // if (value.isNotEmpty) {

          //   String valueUpperCase =
          //       value.toUpperCase();

          //   widget.onDatasetChanged(
          //     valueUpperCase,
          //   );

          //   // print("Comando enviado: $valueUpperCase");

          // } 
        } else {
          await Future.delayed(const Duration(milliseconds: 200));
        }

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

  // Comando "get" para simplificar a obtenção dos dados

  Future<void> commandGetAll() async {
    widget.onDatasetChanged("INF");
    await Future.delayed(const Duration(seconds: 2));
    widget.onDatasetChanged("IKF");
    await Future.delayed(const Duration(seconds: 2));
    widget.onDatasetChanged("IZ1000000F");
  }

  // Valores de compensação
  
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
    // _loadLogFuture = rootBundle.loadString("assets/logs/log1.txt").then((data) {
      
    //   // ALIMENTAÇÃO DO CONTROLLER DE DEBUG:
    //   // O método process(data) deve internamente popular o _staticIz.real, 
    //   // _staticIz.imag e principalmente o _staticIz.freq para o gráfico aceitar.
    //   // _staticIz.process(data);
      
    //   if (_staticIz.real.isNotEmpty) {
    //   if (widget.iz.freq.isNotEmpty && widget.iz.freq.length == _staticIz.real.length) {
    //     // Se o dispositivo real já tiver frequências correspondentes, clonamos elas
    //     _staticIz.freq = List.from(widget.iz.freq);
    //   } else {
    //     // Caso contrário, geramos uma lista de frequências lineares/sequenciais 
    //     // para bater com o tamanho dos pontos lidos do log e o gráfico não anular o plot
    //     _staticIz.freq = List.generate(
    //       _staticIz.real.length, 
    //       (index) => index.toDouble() * 100.0, // Ex: Passos de 100Hz em 100Hz
    //     );
    //   }
    // }
    //   // Força a atualização da tela no primeiro carregamento para desenhar o gráfico com dados prontos
    //   if (mounted) {
    //     setState(() {});
    //   }
    //   return data;
    // });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _captureTare() {
    setState(() {
      tareReal = List.from(_staticIz.real.isNotEmpty ? _staticIz.real : widget.iz.real);
      tareImag = List.from(_staticIz.imag.isNotEmpty ? _staticIz.imag : widget.iz.imag);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LanguageHandler().translate('captured_reference'),)
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
      SnackBar(
        content: Text(LanguageHandler().translate('compensation_removed')),
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

    final correctedReal = _applyTare(iz.real, tareReal);
    final correctedImag = _applyTare(iz.imag, tareImag);

    // Para o ambiente de Debug/Log estático funcionar com o Switch de compensação
    // final debugCorrectedReal = _applyTare(_staticIz.real, tareReal);
    // final debugCorrectedImag = _applyTare(_staticIz.imag, tareImag);

    if(widget.connStatus != BleConnectionStatus.connected && !wasConnected) {
        return Center(child: Text(LanguageHandler().translate("no_device_found")));
    } else {
      wasConnected = true;
    }

    return Padding(
      
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          
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
          ValueListenableBuilder<bool>(
            valueListenable: iz.sensorErrorNotifier,
            builder: (context, temErro, child) {
              // Verifica a condição aqui, antes de renderizar a interface de erro
              if (!temErro) return const SizedBox.shrink(); 

              return Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                child: Center(
                  child: Text(
                  LanguageHandler().translate('probe_sensor_error'), 
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              );
            },
          ),
          // MODO PRODUÇÃO EM TEMPO REAL: 
          SizedBox(
            height: 520,
            width: double.infinity,
            child: GraphViewScreen(
              iz: iz,
              realOverride: correctedReal,
              imagOverride: correctedImag,
              title: applyTare ? LanguageHandler().translate('compensated_measurement') : LanguageHandler().translate('new_measurement'),
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
              title: Text(
                LanguageHandler().translate('view_probe_settings'),
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

          // Temperatura e Pressão

          Row(
            children: [

              Expanded(
                child: Card(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(12),
                    child: Column(
                      children: [

                        Text(
                          // "Temperatura",
                          LanguageHandler().translate('temperature'),
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          // "${widget.temperature.toStringAsFixed(1)} °C",
                          AppConfigs().formatTemperature(widget.temperature)
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

                        Text(
                          // "Pressão",
                          LanguageHandler().translate('pressure'),
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                           "${widget.pressure} N",
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
                  Text(
                    // "Enviar comando",
                    LanguageHandler().translate('send_command')
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
                              if(value.toLowerCase() == "get") {
                                commandGetAll();
                              }
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

                          child: Text(
                            // "Comando Único",
                            LanguageHandler().translate('single_command'),
                          ),
                        ),
                        const SizedBox(width: 8),
        
                        ElevatedButton.icon(
                          onPressed: startStream,
                          icon: const Icon(Icons.sensors), 
                          label: const Text("Streaming"),   
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

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                  Text(
                    // "Compensação",
                    LanguageHandler().translate('compensation'),
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
                          child: Text(
                            // "Tara",
                            LanguageHandler().translate('tare')
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: tareReal == null
                              ? null
                              : _clearTare,
                          child: Text(LanguageHandler().translate('clean'))// const Text("Limpar"),
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
                    title: Text(
                      // "Aplicar compensação",
                      LanguageHandler().translate('apply_compensation')
                    ),
                  ),

                  if (tareReal != null)
                    Text(
                      // "Referência ativa",
                      LanguageHandler().translate('reference_activated'),
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