import 'package:flutter/material.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text(
          'Configuración General',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ListTile(leading: Icon(Icons.person), title: Text('Perfil')),
        ListTile(leading: Icon(Icons.lock), title: Text('Seguridad')),
      ],
    );
  }
}
