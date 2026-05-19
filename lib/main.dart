import 'package:flutter/material.dart';
import 'controllers/ble_controller.dart';
import 'package:eprobe/permissions.dart';
import 'dart:async';

import 'package:eprobe/widgets/navbar.dart';
import 'package:eprobe/models/connection_status.dart';

import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/user_screen.dart';
import 'widgets/bottom_navbar.dart';
import 'controllers/iz_controller.dart';

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

  BleConnectionStatus connStatus =
  BleConnectionStatus.disconnected;

  int _currentIndex = 0;

  String _selectedDataset = "IZ1000000F";
  String _controlConfirmation = "Nenhum";

  StreamSubscription<String>? _bleSubscription;

  StreamSubscription<BleConnectionStatus>? _connSub;

  double _temperature = 0;
  int _pressure = 0;

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

    // ===== BLE DATA =====
    _bleSubscription = ble.messageStream.listen((block) {

      print("Tamanho do block: ${block.length}");

      final lines = block.split("\n");

      print("Quantidade de linhas: ${lines.length}");

      iz.process(block);

      if (iz.freq.isNotEmpty &&
          iz.real.isNotEmpty &&
          iz.imag.isNotEmpty) {

        setState(() {
          _temperature = 25;
          _pressure = 0;
        });
      }
    });
  }

  @override
  void dispose() {

    _bleSubscription?.cancel();
    _connSub?.cancel();

    super.dispose();
  }

  Future<void> onConnectPressed() async {

    if (connStatus == BleConnectionStatus.connected ||
        // connStatus == BleConnectionStatus.connecting ||
        connStatus == BleConnectionStatus.scanning) {
      return;
    }

    setState(() {
      connStatus = BleConnectionStatus.connecting;
    });

    final granted = await requestBlePermissions();

    if (!granted) {

      setState(() {
        connStatus = BleConnectionStatus.disconnected;
      });

      return;
    }

    bool found = await ble.scanForEsp();

    if (!mounted) return;

    if (!found) {

      setState(() {
        connStatus = BleConnectionStatus.disconnected;
      });

      return;
    }

    setState(() {
      connStatus = BleConnectionStatus.connecting;
    });

    await ble.connect();
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
        onConnect: onConnectPressed,
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

              _sendControlCommand(v);
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