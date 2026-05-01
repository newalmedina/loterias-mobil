import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loterymobile/pages/reportes/reportes_page.dart';
import 'package:loterymobile/pages/ventas/widgets/listado_detalle.dart';
import 'package:loterymobile/pages/ventas/widgets/ventas_filtros.dart';
import 'package:loterymobile/services/ventas_service.dart';

class TicketsAnuladosPage extends StatefulWidget {
  const TicketsAnuladosPage({super.key});

  @override
  State<TicketsAnuladosPage> createState() => _TicketsAnuladosPageState();
}

class _TicketsAnuladosPageState extends State<TicketsAnuladosPage> {
  List<dynamic> _tickets = [];
  Map<String, dynamic> _filtrosActuales = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());

    _searchTickets({
      "ticket": "",
      "startDate": today,
      "endDate": today,
      "loterias": [],
      "types": [],
      "pagadas": null,
      "estadoVenta": null,
    });
  }

  // =========================
  // API CALL
  // =========================
  Future<void> _searchTickets(Map<String, dynamic> filtros) async {
    _filtrosActuales = filtros;
    setState(() => _isLoading = true);

    final results = await VentasService.getVentas(
      startDate: _parseDateSafe(filtros["startDate"]),
      endDate: _parseDateSafe(filtros["endDate"]),
      loteriaIds: (filtros["loterias"] ?? []).cast<int>(),
      code: filtros["ticket"] ?? "",
      type: (filtros["types"] ?? []).cast<String>(),
      pagado: filtros["pagadas"],
      premiado: filtros["estadoVenta"],
      onlyTrash: true,
    );

    setState(() {
      _tickets = results;
      _isLoading = false;
    });
  }

  DateTime? _parseDateSafe(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat('dd-MM-yyyy').parse(value);
    } catch (_) {
      return null;
    }
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
              // ❌ TÍTULO
              Row(
                children: const [
                  Icon(Icons.cancel, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    'Ventas Anuladas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              // 📊 BOTÓN REPORTE
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.file_download),
                label: const Text("Reportes"),
                onPressed: _openReporteScreen,
              ),
            ],
          ),
          const SizedBox(height: 10),

          VentasFiltros(onSearch: _searchTickets),

          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListadoDetalle(
                    ventas: _tickets,
                    moduleName: 'tickets_anulados',
                    onRefresh: () {
                      _searchTickets(_filtrosActuales);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openReporteScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportesPage(
          ventas: _tickets,
          filtros: _filtrosActuales,
          title: "Reportes Tickets anulados",
          moduleName: "tickets_anulados",
        ),
      ),
    );
  }
}
