import 'package:eprobe/controllers/language_handler.dart';
import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Acessa a instância única do Singleton
    final languageHandler = LanguageHandler(); 

    return ListenableBuilder(
      listenable: languageHandler,
      builder: (context, child) {
        return NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 65,
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: Colors.green.withOpacity(0.15),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: Colors.green, size: 28);
              }
              return const IconThemeData(color: Colors.grey, size: 26);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                );
              }
              return const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: "Home",
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: languageHandler.translate("records"),
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: languageHandler.translate("settings"),
              ),
            ],
          ),
        );
      },
    );
  }
}