import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loterymobile/pages/ventas/widgets/listado_detalle.dart';
import 'package:loterymobile/pages/ventas/widgets/ventas_filtros.dart';
import 'package:loterymobile/services/ventas_service.dart';

class TicketsPremiadosPage extends StatefulWidget {
  const TicketsPremiadosPage({super.key});

  @override
  State<TicketsPremiadosPage> createState() => _TicketsPremiadosPageState();
}

class _TicketsPremiadosPageState extends State<TicketsPremiadosPage> {
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
      premiado: 1,
      // onlyTrash: true,
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
            children: const [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Tickets Premiados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
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
                    moduleName: 'tickets_premiados',
                    onRefresh: () {
                      _searchTickets(_filtrosActuales);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
