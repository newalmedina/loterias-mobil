import 'package:flutter/material.dart';

class ConfigImpresoraPage extends StatelessWidget {
  const ConfigImpresoraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text(
          'Configuración de Impresora',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        ListTile(
          leading: Icon(Icons.print),
          title: Text('Seleccionar impresora'),
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Ajustes de impresión'),
        ),
      ],
    );
  }
}
