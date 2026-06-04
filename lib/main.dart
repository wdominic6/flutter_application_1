import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  // Aseguramos que Flutter esté inicializado antes de cargar servicios nativos
  WidgetsFlutterBinding.ensureInitialized();



  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garage Sale App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}
