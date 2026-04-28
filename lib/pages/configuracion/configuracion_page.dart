import 'package:flutter/material.dart';
import 'package:loterymobile/theme/theme.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Configuración General',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 10),
        ListTile(leading: Icon(Icons.person), title: Text('Perfil')),
        ListTile(leading: Icon(Icons.lock), title: Text('Seguridad')),
      ],
    );
  }
}
