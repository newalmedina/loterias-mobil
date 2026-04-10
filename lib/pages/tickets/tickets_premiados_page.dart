import 'package:flutter/material.dart';

class TicketsPremiadosPage extends StatelessWidget {
  const TicketsPremiadosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Tickets Premiados',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.green),
              title: Text('Ticket #$index'),
              subtitle: const Text('Premio: \$500'),
            ),
          ),
        ),
      ],
    );
  }
}
