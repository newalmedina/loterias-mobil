// lib/service/ventas_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../model/venta_model.dart';
import '../config/api.dart';

class VentasService {
  /// Envía una venta al backend
  static Future<bool> finalizarVenta(Venta venta) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? '';

      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.finalizarVenta);

      // Convertimos el modelo Venta a JSON
      final body = json.encode({
        'id': venta.id,
        'code': venta.code,
        'fecha': venta.fecha?.toIso8601String(),
        'detalles': venta.detalles
            ?.map(
              (d) => {
                'id': d.id,
                'numero': d.numero,
                'numberFormated': d.numberFormated,
                'monto': d.monto,
                'loteriaId': d.loteriaId,
                'loteriaSecondId': d.loteriaSecondId,
                'loteriaSlug': d.loteriaSlug,
                'tipo': d.tipo,
              },
            )
            .toList(),
      });

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Error al finalizar venta: ${response.statusCode}');
        print('Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción al finalizar venta: $e');
      return false;
    }
  }
}
