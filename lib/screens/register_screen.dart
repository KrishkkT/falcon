import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailC = TextEditingController();
  final TextEditingController passC = TextEditingController();
  final TextEditingController nameC = TextEditingController();

  Future<void> register() async {
    final authService = AuthService();
    final result = await authService.register(
      name: nameC.text.trim(),
      mobile: emailC.text.trim(),
      password: passC.text.trim(),
    );
    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registered. Please login.')));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Registration failed: ${result['message']}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Falcon - Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Display name')),
          TextField(
              controller: emailC,
              decoration: const InputDecoration(labelText: 'Email')),
          TextField(
              controller: passC,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password')),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: register, child: const Text('Register'))
        ]),
      ),
    );
  }
}
