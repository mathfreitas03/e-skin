import 'package:flutter/material.dart';
import 'ble_controllerv2.dart';
import 'permissions.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart'; // Certifique-se de ter fl_chart no pubspec.yaml

// imports da estrutura (mantenha os seus imports)
import 'widgets/navbar.dart';
import 'models/connection_status.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Permissões BLE iniciais
  final ok = await requestBlePermissions();
  if (!ok) {
    print("❌ Permissões BLE não concedidas.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final BleController ble = BleController();

  // Variáveis de Estado de Conexão
  ConnectionStatus connStatus = ConnectionStatus.disconnected;

  // Variáveis para o Gráfico (Serviço 1)
  List<double> _freqData = [];
  List<double> _resData = [];
  List<double> _capData = [];

  // Variáveis para Temperatura e Pressão (Serviço 3)
  double _temperature = 0.0;
  int _pressure = 0;

  // Gerenciamento de Subscrições
  StreamSubscription<List<double>>? _freqSubscription;
  StreamSubscription<List<double>>? _resSubscription;
  StreamSubscription<List<double>>? _capSubscription;
  StreamSubscription<double>? _tempSubscription;
  StreamSubscription<int>? _pressaoSubscription;

  // Variáveis de Controle (Serviço 2)
  String _controlConfirmation = "Nenhum"; // Confirmação do comando IZxF
  int _selectedDataset = 1; // 💡 NOVO: Dataset inicialmente selecionado

  // StreamController não é mais necessário para os dados, pois estamos
  // usando as variáveis de estado e o StreamSubscription.
  // final StreamController<String> _squareController = StreamController.broadcast();
  // Stream<String> get squareStream => _squareController.stream;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // 🧹 Limpa todas as subscrições quando o widget é destruído
    _freqSubscription?.cancel();
    _resSubscription?.cancel();
    _capSubscription?.cancel();
    _tempSubscription?.cancel();
    _pressaoSubscription?.cancel();
    super.dispose();
  }

  // --- FUNÇÕES DE CONEXÃO E SUBSCRIÇÃO ---

  // Função para iniciar as subscrições após a conexão
  void _startSubscriptions() {
    if (ble.esp32 == null) return;

    // SERVIÇO 1 - BIOIMPEDÂNCIA (CSV)
    _freqSubscription = ble.subscribeFreq().listen((data) {
      setState(() => _freqData = data);
      print("📶 Frequência recebida: ${_freqData.length} pontos.");
    }, onError: (e) => print("Erro na Frequência: $e"));

    _resSubscription = ble.subscribeRes().listen((data) {
      setState(() => _resData = data);
      print("🎚️ Resistência recebida: ${_resData.length} pontos.");
    }, onError: (e) => print("Erro na Resistência: $e"));

    _capSubscription = ble.subscribeCap().listen((data) {
      setState(() => _capData = data);
      print("🔌 Capacitância recebida: ${_capData.length} pontos.");
    }, onError: (e) => print("Erro na Capacitância: $e"));

    // SERVIÇO 3 - TEMPERATURA E PRESSÃO (String Simples)
    _tempSubscription = ble.subscribeTemp().listen((data) {
      setState(() => _temperature = data);
      print("🌡️ Temperatura recebida: $data °C");
    }, onError: (e) => print("Erro na Temperatura: $e"));

    _pressaoSubscription = ble.subscribePressao().listen((data) {
      setState(() => _pressure = data);
      print("⚖️ Pressão recebida: $data g");
    }, onError: (e) => print("Erro na Pressão: $e"));
  }

  // Função para lidar com a tentativa de conexão
  Future<void> onConnectPressed() async {
    // ... (código de verificação de status e permissões) ...
    if (connStatus == ConnectionStatus.connected ||
        connStatus == ConnectionStatus.connecting ||
        connStatus == ConnectionStatus.scanning) {
      return;
    }

    print("➡️ Tentando conectar ao ESP32...");
    setState(() => connStatus = ConnectionStatus.scanning);

    final granted = await requestBlePermissions();
    if (!granted) {
      // ... (trata permissões) ...
      setState(() => connStatus = ConnectionStatus.disconnected);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permissões BLE necessárias!")),
      );
      return;
    }

    // SCAN
    bool found = await ble.scanForEsp();
    if (!mounted) return;
    if (!found) {
      // ... (trata não encontrado) ...
      setState(() => connStatus = ConnectionStatus.disconnected);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("ESP32 não encontrado!")));
      return;
    }

    // CONECTAR
    setState(() => connStatus = ConnectionStatus.connecting);
    bool connected = await ble.connect();

    if (!mounted) return;

    if (connected) {
      setState(() => connStatus = ConnectionStatus.connected);
      _startSubscriptions(); // ⚡ Inicia as subscrições APÓS a conexão
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Conectado ao ESP32-BIA!")));
    } else {
      setState(() => connStatus = ConnectionStatus.disconnected);
    }
  }

  // --- FUNÇÕES DE GRÁFICO ---

  // Converte List<double> para List<FlSpot> para o gráfico
  List<FlSpot> _getFlSpots(List<double> yData) {
    List<FlSpot> spots = [];
    int minLength = _freqData.length < yData.length
        ? _freqData.length
        : yData.length;

    for (int i = 0; i < minLength; i++) {
      spots.add(FlSpot(_freqData[i], yData[i]));
    }
    return spots;
  }

  // Widget de Card de Gráfico reutilizável
  Widget _buildGraphCard(
    String title,
    String unit,
    List<FlSpot> spots,
    Color color,
  ) {
    if (spots.isEmpty) {
      return const Center(child: Text("Aguardando dados de Bioimpedância..."));
    }

    double minX = spots.map((spot) => spot.x).reduce((a, b) => a < b ? a : b);
    double maxX = spots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
    double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    // Adiciona uma pequena margem nos eixos
    minY = minY > 0 ? minY * 0.95 : 0;
    maxY = maxY * 1.05;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text(
                        "Frequência (Hz)",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: (maxX - minX) / 4, // 5 rótulos no eixo X
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 8),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: (maxY - minY) / 4, // 5 rótulos no eixo Y
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 8),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- FUNÇÃO PARA ENVIAR COMANDOS ---
  Future<void> _sendControlCommand(int dataset) async {
    final command = "IZ${dataset}F";
    final confirmation = await ble.writeControl(command);
    // 🕵️‍♂️ PRINT DE VERIFICAÇÃO: Confirmação recebida do ESP32

    setState(() {
      _controlConfirmation = confirmation ?? "Erro ao enviar comando.";
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Comando enviado: $command. Confirmação: $_controlConfirmation",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Converte os dados para o formato do gráfico
    final resistanceSpots = _getFlSpots(_resData);
    final capacitanceSpots = _getFlSpots(_capData);

    return Scaffold(
      backgroundColor: Colors.white,

      // NAVBAR COM BOLINHA DE STATUS
      appBar: Navbar(
        onConnect: onConnectPressed,
        status: connStatus,
        assetLogoPath: 'assets/images/logo_teste.jpg',
      ),

      // ÁREA DE DADOS
      body: connStatus == ConnectionStatus.connected
          ? Padding(
              padding: const EdgeInsets.all(12),
              // 1. O corpo principal agora é um ListView para permitir a mistura de layouts
              child: ListView(
                // Adiciona um espaçamento vertical consistente
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                children: [
                  // 1. Gráfico de Resistência vs Frequência (Largura Total)
                  // Usamos SizedBox para definir uma altura retangular, já que ele ocupa 100% da largura
                  SizedBox(
                    height: 220, // Altura definida para o gráfico
                    child: _buildGraphCard(
                      "Resistência vs Freq.",
                      "Resistência (Ω)",
                      resistanceSpots,
                      Colors.red.shade700,
                    ),
                  ),

                  const SizedBox(height: 12), // Espaçamento entre os gráficos
                  // 2. Gráfico de Capacitância vs Frequência (Largura Total)
                  SizedBox(
                    height: 220, // Altura definida para o gráfico
                    child: _buildGraphCard(
                      "Capacitância vs Freq.",
                      "Capacitância (pF)",
                      capacitanceSpots,
                      Colors.green.shade700,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ), // Espaçamento entre o gráfico e o grid
                  // 3. Grid para os Cards menores (Temperatura/Pressão e Controle)
                  GridView.count(
                    crossAxisCount: 2, // 2 colunas
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    // ⭐ CRUCIAL: Faz o GridView se ajustar ao seu conteúdo, permitindo o scroll do ListView
                    shrinkWrap: true,
                    // ⭐ CRUCIAL: Desativa o scroll interno do GridView
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio:
                        1 / 1, // Ajuste a proporção para os cards menores
                    children: [
                      // 3. Informação de Temperatura e Pressão
                      Card(
                        elevation: 4,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Temperatura",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${_temperature.toStringAsFixed(1)} °C",
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Pressão",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "$_pressure g",
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Controle de Dataset (Serviço 2) - DropdownButton
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Controle de Dataset",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 8),

                              // ⬇️ SELETOR DE DATASET (DropdownButton)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: _selectedDataset,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    elevation: 4,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                    onChanged: (int? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          _selectedDataset = newValue;
                                        });
                                        // 🚀 CHAMA O ENVIO DO COMANDO AUTOMATICAMENTE
                                        _sendControlCommand(newValue);
                                      }
                                    },
                                    items: List.generate(6, (index) {
                                      final dataset = index + 1;
                                      return DropdownMenuItem<int>(
                                        value: dataset,
                                        child: Text(
                                          "Dataset $dataset (IZ${dataset}F)",
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Texto de Confirmação
                              Text(
                                "Última Confirmação: $_controlConfirmation",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : const Center(
              child: Text(
                "Conecte ao ESP32 para ver os dados",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ),

      // FOOTER
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade200,
        child: ElevatedButton(
          onPressed: () async {
            // Exemplo de como usar o LED
            final currentState = await ble.writeLed(1); // Acender
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("LED Ligado. Estado retornado: $currentState"),
                ),
              );
            }
            await Future.delayed(const Duration(seconds: 1));
            await ble.writeLed(0); // Apagar
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text("Teste LED (Ligar/Desligar)"),
        ),
      ),
    );
  }
}
