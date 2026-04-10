import 'package:flutter/material.dart';
import '../base/base_page.dart'; // ← Esto es obligatorio

class HomePage extends StatelessWidget {
  final String token;

  const HomePage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Bienvenido al Home!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Token de sesión:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(token, textAlign: TextAlign.center),
        ],
      ),
    );

    return BasePage(child: content); // ← Usando la plantilla
  }
}
