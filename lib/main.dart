import 'package:flutter/material.dart';
import 'ui/screens/main_menu.dart';
import 'ui/screens/configuration.dart';
import 'ui/screens/results.dart';
import 'ui/screens/real-time.dart';
import 'ui/screens/scenario_comparison.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Airport Simulator',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenu(),
        '/config': (context) => const ConfigurationScreen(),
        '/results': (context) => const ResultsScreen(),
        '/realtime': (context) => const RealTimeScreen(),
        '/compare': (context) => const ScenarioScreen(),
      },
    );
  }
}