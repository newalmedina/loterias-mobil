import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loterymobile/services/ventas_service.dart';

class VentasRealizadasController extends ChangeNotifier {
  List<dynamic> ventas = [];
  Map<String, dynamic> filtrosActuales = {};
  bool isLoading = false;

  Future<void> searchVentas(Map<String, dynamic> filtros) async {
    filtrosActuales = filtros;
    isLoading = true;
    notifyListeners();

    final results = await VentasService.getVentas(
      startDate: _parseDateSafe(filtros["startDate"]),
      endDate: _parseDateSafe(filtros["endDate"]),
      loteriaIds: (filtros["loterias"] ?? []).cast<int>(),
      code: filtros["ticket"] ?? "",
      type: (filtros["types"] ?? []).cast<String>(),
      pagado: filtros["pagadas"],
      premiado: filtros["estadoVenta"],
      users: filtros["users"],
    );

    ventas = results;
    isLoading = false;
    notifyListeners();
  }

  DateTime? _parseDateSafe(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat('dd-MM-yyyy').parse(value);
    } catch (_) {
      return null;
    }
  }
}
