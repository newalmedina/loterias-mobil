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

  static Future<List<dynamic>> getVentas({
    DateTime? startDate,
    DateTime? endDate,
    List<int>? loteriaIds,
    String? code,
    List<String>? type,
    int? pagado,
    int? premiado,
  }) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? '';

      final Map<String, String> queryParams = {};

      // =========================
      // 📅 FECHAS (OPCIONALES)
      // =========================
      if (startDate != null) {
        queryParams['fecha_inicio'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        queryParams['fecha_fin'] = endDate.toIso8601String().split('T')[0];
      }

      // =========================
      // 🔤 CAMPOS SIMPLES
      // =========================
      if (code != null && code.isNotEmpty) {
        queryParams['code'] = code;
      }

      if (pagado != null) {
        queryParams['pagado'] = pagado.toString();
      }

      if (premiado != null) {
        queryParams['premiado'] = premiado.toString();
      }

      // =========================
      // 🧩 CONSTRUIR URI (POSTMAN STYLE)
      // =========================
      final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.getVentas).replace(
        queryParameters: {
          ...queryParams,

          // type[] = A&type[] = B
          if (type != null && type.isNotEmpty)
            for (int i = 0; i < type.length; i++) "type[]": type[i],

          // loteriaIds[] = 1&loteriaIds[] = 2
          if (loteriaIds != null && loteriaIds.isNotEmpty)
            for (int i = 0; i < loteriaIds.length; i++)
              "loteriaIds[]": loteriaIds[i].toString(),
        },
      );

      // =========================
      // 🔥 DEBUG COMPLETO
      // =========================
      // print("━━━━━━━━━━━━━━━━━━━━━━");
      // print("📤 getVentas REQUEST");

      // print("📅 startDate: $startDate");
      // print("📅 endDate: $endDate");
      // print("🔤 code: $code");
      // print("💰 pagado: $pagado");
      // print("🏆 premiado: $premiado");
      // print("🧩 type: $type");
      // print("🎯 loteriaIds: $loteriaIds");

      // print("🔗 FINAL URL:");
      // print(uri.toString());
      // print("━━━━━━━━━━━━━━━━━━━━━━");

      // =========================
      // 🌐 REQUEST
      // =========================
      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      // print("📡 STATUS: ${response.statusCode}");
      // print("📨 RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) return data;
      }

      return [];
    } catch (e) {
      // print("❌ ERROR: $e");
      return [];
    }
  }
}
