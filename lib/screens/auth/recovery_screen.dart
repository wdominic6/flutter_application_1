import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleRecovery() async {
    if (_emailController.text.isNotEmpty) {
      setState(() => _isLoading = true);

      String? tempPassword = await _authService.recoveryPassword(
        _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (tempPassword != null) {
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Contraseña Restablecida'),
            content: Text(
              'Tu nueva contraseña temporal es:\n\n$tempPassword\n\nPor favor, úsala para iniciar sesión.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El correo no se encuentra registrado.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar Contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ingresa tu correo electrónico y te proporcionaremos una clave de acceso temporal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: _handleRecovery,
                    child: const Text(
                      'Enviar Solicitud',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
