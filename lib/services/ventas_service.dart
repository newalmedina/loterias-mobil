// lib/service/ventas_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:loterymobile/model/api_response.dart';
import '../model/venta_model.dart';
import '../config/api.dart';

class VentasService {
  /// Envía una venta al backend
  static Future<ApiResponse> finalizarVenta(Venta venta) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? '';

      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.finalizarVenta);

      final body = json.encode({
        'id': venta.id ?? '',
        'code': venta.code ?? '',
        'fecha': venta.fecha?.toIso8601String(),
        'detalles':
            venta.detalles?.map((d) {
              return {
                'numero': (d.numero ?? '').replaceAll('-', ''),
                'monto': d.monto ?? 0,
                'tipo': d.tipo,
                'loteriaId': d.loteriaId ?? 0,
                'loteriaSecondId': d.loteriaSecondId,
              };
            }).toList() ??
            [],
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

      final data = jsonDecode(response.body);

      // 🟢 SUCCESS
      if (data['success'] == true) {
        return ApiResponse(
          success: true,
          message: data['message'] ?? 'OK',
          errors: [],
          statusCode: response.statusCode,
        );
      }

      // 🔴 ERROR BACKEND
      print('❌ ERROR BACKEND');
      print('Status: ${response.statusCode}');
      print('Message: ${data['message']}');
      print('List: ${data['messageList']}');

      return ApiResponse(
        success: false,
        message: data['message'] ?? 'Error desconocido',
        errors: data['messageList'] ?? [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('❌ EXCEPTION: $e');

      return ApiResponse(
        success: false,
        message: 'Error de conexión',
        errors: [e.toString()],
        statusCode: null,
      );
    }
  }
}
