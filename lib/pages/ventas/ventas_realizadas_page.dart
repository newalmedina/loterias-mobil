import 'package:flutter/material.dart';

class VentasRealizadasPage extends StatelessWidget {
  const VentasRealizadasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Ventas Realizadas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 15,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.receipt),
              title: Text('Ticket #$index'),
              subtitle: const Text('Monto: \$100'),
            ),
          ),
        ),
      ],
    );
  }
}
