import 'package:flutter/material.dart';

class VentasList extends StatelessWidget {
  final List<dynamic> ventas;
  final bool isLoading;
  final bool detalleVenta;
  final Function(Map<String, dynamic>) onOpen;

  const VentasList({
    super.key,
    required this.ventas,
    required this.isLoading,
    required this.detalleVenta,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ventas.isEmpty) {
      return const Center(child: Text("No hay ventas"));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ventas.length,
      itemBuilder: (context, index) {
        final v = ventas[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text("ID: ${v['code']}"),
            subtitle: Text("Total: \$${v['total_venta_bruto']}"),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () => onOpen(v),
            ),
          ),
        );
      },
    );
  }
}
