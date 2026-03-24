import 'package:flutter/material.dart';
import 'widgets/ble_controllerv3.dart';
import 'package:e_skin/permissions.dart';
import 'dart:async';

import 'package:e_skin/widgets/navbar.dart';
import 'package:e_skin/models/connection_status.dart';

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
      theme: ThemeMode.system == ThemeMode.dark ? ThemeData.dark() : ThemeData.light(),
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

  ConnectionStatus connStatus = ConnectionStatus.disconnected;

  int _currentIndex = 0;

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

    _bleSubscription = ble.messageStream.listen((block) {
      iz.process(block);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _bleSubscription?.cancel();
    _tempSubscription?.cancel();
    _pressSubscription?.cancel();
    super.dispose();
  }

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

  Future<void> _sendControlCommand(int dataset) async {
    final command = "IZ${dataset}F";
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
        status: connStatus,
        assetLogoPath: 'assets/images/logo_teste.jpg',
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
              setState(() => _selectedDataset = v);
              _sendControlCommand(v);
            },
          ),

          const StatsScreen(),
          const UserScreen(),
        ],
      ),

      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}