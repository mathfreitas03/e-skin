import 'package:flutter/material.dart';
import 'ble_controllerv3.dart';
import 'package:e_skin/permissions.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

import 'package:e_skin/widgets/navbar.dart';
import 'package:e_skin/models/connection_status.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ok = await requestBlePermissions();
  if (!ok) {
    print("Permissões BLE não concedidas.");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {

  final BleController ble = BleController();

  ConnectionStatus connStatus = ConnectionStatus.disconnected;

  /// DADOS IZ
  List<double> _freqData = [];
  List<double> _realData = [];
  List<double> _imagData = [];

  /// SENSOR
  double _temperature = 0;
  int _pressure = 0;

  StreamSubscription<String>? _bleSubscription;
  StreamSubscription<double>? _tempSubscription;
  StreamSubscription<int>? _pressSubscription;

  int _selectedDataset = 1;
  String _controlConfirmation = "Nenhum";

  @override
  void initState() {
    super.initState();

    /// ESCUTA STREAM BLE
    _bleSubscription = ble.messageStream.listen((block) {
      _processIzBlock(block);
    });
  }

  @override
  void dispose() {
    _bleSubscription?.cancel();
    _tempSubscription?.cancel();
    _pressSubscription?.cancel();
    super.dispose();
  }

  /// PROCESSA BLOCO IZ RECEBIDO
  void _processIzBlock(String block) {

    final clean = block.replaceAll("@", "");

    final parts = clean.split(",");

    if (parts.length < 4) return;

    List<double> real = [];
    List<double> imag = [];
    List<double> freq = [];

    for (int i = 1; i < parts.length; i += 3) {

      if (i + 2 >= parts.length) break;

      final r = double.tryParse(parts[i]);
      final im = double.tryParse(parts[i + 1]);
      final f = double.tryParse(parts[i + 2]);

      if (r != null && im != null && f != null) {
        real.add(r);
        imag.add(im);
        freq.add(f);
      }
    }

    setState(() {
      _realData = real;
      _imagData = imag;
      _freqData = freq;
    });

    print("📊 IZ recebido: ${freq.length} pontos");
  }

  /// CONEXÃO BLE
  Future<void> onConnectPressed() async {

    if (connStatus == ConnectionStatus.connected ||
        connStatus == ConnectionStatus.connecting ||
        connStatus == ConnectionStatus.scanning) {
      return;
    }

    setState(() => connStatus = ConnectionStatus.scanning);

    final granted = await requestBlePermissions();

    if (!granted) {
      setState(() => connStatus = ConnectionStatus.disconnected);
      return;
    }

    bool found = await ble.scanForEsp();

    if (!mounted) return;

    if (!found) {
      setState(() => connStatus = ConnectionStatus.disconnected);
      return;
    }

    setState(() => connStatus = ConnectionStatus.connecting);

    bool connected = await ble.connect();

    if (!mounted) return;

    if (connected) {

      setState(() => connStatus = ConnectionStatus.connected);

      _tempSubscription = ble.subscribeTemp().listen((data) {
        setState(() => _temperature = data);
      });

      _pressSubscription = ble.subscribePressao().listen((data) {
        setState(() => _pressure = data);
      });

    } else {
      setState(() => connStatus = ConnectionStatus.disconnected);
    }
  }

  /// CONVERTE PARA SPOTS DO GRÁFICO
  List<FlSpot> _spots(List<double> x, List<double> y) {

    List<FlSpot> spots = [];

    int min = x.length < y.length ? x.length : y.length;

    for (int i = 0; i < min; i++) {
      spots.add(FlSpot(x[i], y[i]));
    }

    return spots;
  }

  /// CARD DE GRÁFICO
  Widget _buildGraphCard(
      String title,
      String unit,
      List<FlSpot> spots,
      Color color) {

    if (spots.isEmpty) {
      return const Center(child: Text("Aguardando dados IZ..."));
    }

    double minX = spots.map((e) => e.x).reduce((a,b)=>a<b?a:b);
    double maxX = spots.map((e) => e.x).reduce((a,b)=>a>b?a:b);
    double minY = spots.map((e) => e.y).reduce((a,b)=>a<b?a:b);
    double maxY = spots.map((e) => e.y).reduce((a,b)=>a>b?a:b);

    return Card(
      elevation:4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child:Padding(
        padding: const EdgeInsets.all(12),
        child:Column(
          children:[
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey)),
            const SizedBox(height:8),
            Expanded(
              child:LineChart(
                LineChartData(
                  minX:minX,
                  maxX:maxX,
                  minY:minY*0.95,
                  maxY:maxY*1.05,
                  gridData: const FlGridData(show:true),
                  titlesData: FlTitlesData(
                    bottomTitles:AxisTitles(
                        axisNameWidget: const Text("Freq (Hz)"),
                        sideTitles:SideTitles(showTitles:true)),
                    leftTitles:AxisTitles(
                        axisNameWidget: Text(unit),
                        sideTitles:SideTitles(showTitles:true)),
                    rightTitles: const AxisTitles(
                        sideTitles:SideTitles(showTitles:false)),
                    topTitles: const AxisTitles(
                        sideTitles:SideTitles(showTitles:false)),
                  ),
                  lineBarsData:[
                    LineChartBarData(
                      spots:spots,
                      isCurved:true,
                      color:color,
                      barWidth:2,
                      dotData: const FlDotData(show:false),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// ENVIA COMANDO IZ
  Future<void> _sendControlCommand(int dataset) async {

    final command = "IZ${dataset}F";

    await ble.sendMessage(command);

    setState(() {
      _controlConfirmation = command;
    });
  }

  @override
  Widget build(BuildContext context) {

    final realSpots = _spots(_freqData,_realData);
    final imagSpots = _spots(_freqData,_imagData);

    return Scaffold(

      backgroundColor: Colors.white,

      appBar: Navbar(
        onConnect: onConnectPressed,
        status: connStatus,
        assetLogoPath: 'assets/images/logo_teste.jpg',
      ),

      body: connStatus == ConnectionStatus.connected
          ? Padding(
        padding: const EdgeInsets.all(12),

        child: ListView(
          children: [

            SizedBox(
              height:220,
              child:_buildGraphCard(
                  "Real(Z) vs Frequência",
                  "Ω",
                  realSpots,
                  Colors.red),
            ),

            const SizedBox(height:12),

            SizedBox(
              height:220,
              child:_buildGraphCard(
                  "Imag(Z) vs Frequência",
                  "Ω",
                  imagSpots,
                  Colors.green),
            ),

            const SizedBox(height:12),

            GridView.count(
              crossAxisCount:2,
              crossAxisSpacing:12,
              mainAxisSpacing:12,
              shrinkWrap:true,
              physics: const NeverScrollableScrollPhysics(),

              children:[

                Card(
                  elevation:4,
                  child:Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[

                      const Text("Temperatura",
                          style:TextStyle(fontWeight: FontWeight.bold)),

                      Text("${_temperature.toStringAsFixed(1)} °C",
                          style: const TextStyle(fontSize:28)),

                      const SizedBox(height:10),

                      const Text("Pressão",
                          style:TextStyle(fontWeight: FontWeight.bold)),

                      Text("$_pressure g",
                          style: const TextStyle(fontSize:28)),

                    ],
                  ),
                ),

                Card(
                  elevation:4,
                  child:Padding(
                    padding: const EdgeInsets.all(12),

                    child:Column(
                      children:[

                        const Text("Dataset IZ",
                            style:TextStyle(fontWeight: FontWeight.bold)),

                        const SizedBox(height:10),

                        DropdownButton<int>(
                          isExpanded:true,
                          value:_selectedDataset,

                          onChanged:(v){

                            if(v==null) return;

                            setState(()=>_selectedDataset=v);

                            _sendControlCommand(v);
                          },

                          items:List.generate(6,(i){

                            final d=i+1;

                            return DropdownMenuItem(
                                value:d,
                                child:Text("Dataset $d (IZ${d}F)")
                            );

                          }),
                        ),

                        const SizedBox(height:8),

                        Text("Último comando: $_controlConfirmation",
                            style: const TextStyle(fontSize:12))

                      ],
                    ),
                  ),
                )

              ],
            )
          ],
        ),
      )

          : const Center(
        child:Text("Conecte ao ESP32 para ver os dados"),
      ),

      bottomNavigationBar:Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade200,

        child:ElevatedButton(

          onPressed:() async{

            final state = await ble.writeLed(1);

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("LED ligado: $state")));

            await Future.delayed(const Duration(seconds:1));

            await ble.writeLed(0);
          },

          child: const Text("Teste LED"),
        ),
      ),
    );
  }
}