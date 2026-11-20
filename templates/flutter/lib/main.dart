import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/zkbrain_ble_service.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ZKBrainBleService()),
      ],
      child: const ZKBrainFlutterApp(),
    ),
  );
}

class ZKBrainFlutterApp extends StatelessWidget {
  const ZKBrainFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZKBrain Flutter Starter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
