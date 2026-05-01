import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loterymobile/pages/ventas/widgets/listado_detalle.dart';
import 'package:loterymobile/pages/ventas/widgets/ventas_filtros.dart';
import 'package:loterymobile/services/ventas_service.dart';
import 'package:loterymobile/theme/theme.dart';
import 'package:loterymobile/pages/reportes/reportes_page.dart';

class VentasRealizadasPage extends StatefulWidget {
  const VentasRealizadasPage({super.key});

  @override
  State<VentasRealizadasPage> createState() => _VentasRealizadasPageState();
}

class _VentasRealizadasPageState extends State<VentasRealizadasPage> {
  List<dynamic> _ventas = [];
  Map<String, dynamic> _filtrosActuales = {};
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();

    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());

    _searchVentas({
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
  // SOLO API CALL
  // =========================
  Future<void> _searchVentas(Map<String, dynamic> filtros) async {
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
    );

    setState(() {
      _ventas = results;
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
              // 🧾 TÍTULO
              Row(
                children: const [
                  Icon(Icons.point_of_sale, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Ventas Realizadas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              // 📊 BOTÓN EXTRAER REPORTE
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

          VentasFiltros(
            onSearch: _searchVentas,
            moduleName: 'ventas_realizadas',
          ),

          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListadoDetalle(
                    ventas: _ventas,
                    moduleName: 'ventas_realizadas',
                    onRefresh: () {
                      _searchVentas(_filtrosActuales); // 👈 reutiliza filtros
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
        builder: (context) =>
            ReportesPage(ventas: _ventas, filtros: _filtrosActuales),
      ),
    );
  }
}
