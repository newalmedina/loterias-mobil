import 'package:flutter/material.dart';

class TicketsAnuladosPage extends StatelessWidget {
  const TicketsAnuladosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Tickets Anulados',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: Text('Ticket #$index'),
              subtitle: const Text('Motivo: Error'),
            ),
          ),
        ),
      ],
    );
  }
}
