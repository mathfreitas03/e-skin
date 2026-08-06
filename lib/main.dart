import 'package:eprobe/controllers/app_configs.dart';
import 'package:eprobe/controllers/language_handler.dart';
import 'package:eprobe/models/found_ble_device.dart';
import 'package:eprobe/widgets/device_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'controllers/ble_controller.dart';
import 'package:eprobe/permissions.dart';
import 'dart:async';
import 'package:eprobe/widgets/navbar.dart';
import 'package:eprobe/models/connection_status.dart';
import 'views/home_screen.dart';
import 'views/stats_screen.dart';
import 'views/user_screen.dart';
import 'widgets/bottom_navbar.dart';
import 'controllers/iz_controller.dart';

const double forceScaleNewtonPerCount = 0.00005572;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await enableBluetooth();
  final configs = AppConfigs();
  await configs.init();
  final languageHandler = LanguageHandler();
  await languageHandler.init();
  
  
  runApp(
    const ProviderScope( // Requerido pelo Riverpod
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeMode.system == ThemeMode.dark
          ? ThemeData.dark()
          : ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
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
  final IzController iz = IzController();

  BleConnectionStatus connStatus = BleConnectionStatus.disconnected;
  int _currentIndex = 0;

  String _selectedDataset = "IZ1000000F";
  String _controlConfirmation = "Nenhum";

  StreamSubscription<String>? _bleSubscription;
  StreamSubscription<BleConnectionStatus>? _connSub;

  double _temperature = 0;
  double _pressure = 0;
  // ignore: unused_field
  List<FoundBleDevice> _discoveredDevices = [];

  @override
  void initState() {
    super.initState();
    
    // ===== BLE STATUS =====
    _connSub = ble.connectionStream.listen((status) {
      if (!mounted) return;
      setState(() {
        connStatus = status;
      });
    });

    _bleSubscription = ble.messageStream.listen((block) {
      // print("Tamanho do block: ${block.length}");
      // final lines = block.split("\n");
      // print("Quantidade de linhas: ${lines.length}");

      iz.process(block);

      if (!mounted) return;
      setState(() {
        _temperature = iz.temperatura ?? _temperature;
        if (iz.forcaTareada != null) {
          _pressure = iz.forcaTareada! * forceScaleNewtonPerCount;
        } else{
          _pressure = _pressure * forceScaleNewtonPerCount;
        }
        _pressure = double.parse(_pressure.toStringAsFixed(5));
      });
    });
  }

  @override
  void dispose() {
    _bleSubscription?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> onScanPressed() async {
    bool bluetoothGranted;

    bluetoothGranted = await enableBluetooth();

    if(!bluetoothGranted) {return;}

    if (connStatus == BleConnectionStatus.connected ||
        connStatus == BleConnectionStatus.connecting ||
        connStatus == BleConnectionStatus.scanning) {
      return;
    }

    setState(() {
      connStatus = BleConnectionStatus.scanning;
      _discoveredDevices = []; 
    });

    final granted = await requestBlePermissions();
    if (!granted) {
      setState(() {
        connStatus = BleConnectionStatus.disconnected;
      });
      return;
    }

    // ValueNotifier para o modal saber quando novos dispositivos entrarem na lista
    final devicesNotifier = ValueNotifier<List<FoundBleDevice>>([]);

    // Abre o painel visual passando o Notifier
    _showBluetoothDeviceSheet(devicesNotifier);

    final devices = await ble.scanForDevices();
    
    if (!mounted) return;

    setState(() {
      _discoveredDevices = devices;
      connStatus = BleConnectionStatus.disconnected;
    });
    
    devicesNotifier.value = devices;
  }
  void _showBluetoothDeviceSheet(ValueNotifier<List<FoundBleDevice>> devicesNotifier) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                LanguageHandler().translate('available_devices'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Expanded(
              child: ValueListenableBuilder<List<FoundBleDevice>>(
                valueListenable: devicesNotifier,
                builder: (context, devicesList, child) {
                  // Se a lista ainda estiver vazia, mostra o progresso de busca
                  if (devicesList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(LanguageHandler().translate('searching_for_devices')),
                        ],
                      ),
                    );
                  }

                  // Quando a lista popula, renderiza os cards
                  return ListView.builder(
                    itemCount: devicesList.length,
                    itemBuilder: (context, index) {
                      final device = devicesList[index];
                      return DeviceCard(
                        device: device,
                        onTap: () {
                          Navigator.pop(context); // Fecha o modal
                          onDeviceSelected(device); // Inicia a conexão na main
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> onDeviceSelected(FoundBleDevice device) async {
  // Atualiza o status global para "Conectando..." (isso vai atualizar a cor da Navbar)
  setState(() {
    connStatus = BleConnectionStatus.connecting;
  });

  // Chama o método connect modificado do seu controlador passando o dispositivo alvo
  bool success = await ble.connect(device);

  if (!mounted) return;

  // Se a conexão falhar ou der certo, atualiza o estado final na UI
  setState(() {
    connStatus = success 
        ? BleConnectionStatus.connected 
        : BleConnectionStatus.disconnected;
  });
}

  Future<void> _sendControlCommand(String dataset) async {
    final command = dataset;
    await ble.sendMessage(command);

    setState(() {
      _controlConfirmation = command;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navbar(
        onScan: onScanPressed,
        ble: ble,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            connStatus: connStatus,
            iz: iz,
            temperature: _temperature,
            pressure: _pressure,
            selectedDataset: _selectedDataset,
            controlConfirmation: _controlConfirmation,
            onDatasetChanged: (v) {
              setState(() {
                _selectedDataset = v;
              });
                if(connStatus == BleConnectionStatus.connected) {
                  _sendControlCommand(v);
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Aviso'),
                      content: Text('Dispositivo desconectado ou não está pronto'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
            },
          ),
          const StatsScreen(),
          const UserScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
          });
        },
      ),
    );
  }
}