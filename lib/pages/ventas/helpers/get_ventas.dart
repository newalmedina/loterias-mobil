import 'package:intl/intl.dart';
import 'package:loterymobile/services/ventas_service.dart';

DateTime? _parseDate(String? date) {
  if (date == null || date.isEmpty) return null;

  try {
    return DateFormat('dd-MM-yyyy').parse(date);
  } catch (_) {
    return null;
  }
}

Future<List<dynamic>> getVentasHelper({
  String? ticket,
  List<String>? tipos,
  List<int>? loterias,
  int? estadoVenta,
  int? pagadas,
  String? fechaInicio,
  String? fechaFin,
}) async {
  final startDate = _parseDate(fechaInicio) ?? DateTime.now();
  final endDate = _parseDate(fechaFin);

  final response = await VentasService.getVentas(
    startDate: startDate,
    endDate: endDate,
    code: ticket,
    type: tipos,
    loteriaIds: loterias,
    pagado: pagadas,
    premiado: estadoVenta,
  );

  return response;
}
