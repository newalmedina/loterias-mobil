import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loterymobile/pages/reportes/reportes_page.dart';
import 'package:loterymobile/pages/ventas/controller/ventas_premiadas_controller.dart';
import 'package:loterymobile/pages/ventas/widgets/listado_detalle.dart';
import 'package:loterymobile/pages/ventas/widgets/ventas_filtros.dart';

class VentasPremiadasPage extends StatefulWidget {
  const VentasPremiadasPage({super.key});

  @override
  State<VentasPremiadasPage> createState() => _VentasPremiadasPageState();
}

class _VentasPremiadasPageState extends State<VentasPremiadasPage> {
  late final VentasPremiadasController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VentasPremiadasController();

    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _ctrl.searchTickets({
      "ticket": "",
      "startDate": today,
      "endDate": today,
      "loterias": [],
      "types": [],
      "pagadas": null,
      "estadoVenta": null,
      "users": [1],
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openReporteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportesPage(
          ventas: _ctrl.tickets,
          filtros: _ctrl.filtrosActuales,
          title: "Reportes Ventas premiadas",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.emoji_events, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Ventas premiadas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.file_download),
                label: const Text("Reportes"),
                onPressed: _openReporteScreen,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ✅ Fuera del AnimatedBuilder
          VentasFiltros(
            moduleName: 'tickets_premiados',
            onSearch: _ctrl.searchTickets,
          ),

          const SizedBox(height: 10),

          // ✅ Solo la lista escucha al controller
          Expanded(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) {
                return _ctrl.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListadoDetalle(
                        ventas: _ctrl.tickets,
                        moduleName: 'tickets_premiados',
                        onRefresh: () =>
                            _ctrl.searchTickets(_ctrl.filtrosActuales),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
