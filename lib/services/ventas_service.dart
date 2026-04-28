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
      //print('❌ ERROR BACKEND');
      //print('Status: ${response.statusCode}');
      //print('Message: ${data['message']}');
      //print('List: ${data['messageList']}');

      return ApiResponse(
        success: false,
        message: data['message'] ?? 'Error desconocido',
        errors: data['messageList'] ?? [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      //print('❌ EXCEPTION: $e');

      return ApiResponse(
        success: false,
        message: 'Error de conexión',
        errors: [e.toString()],
        statusCode: null,
      );
    }
  }

  static Future<Map<String, dynamic>?> findVenta(int id) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? '';

      final uri = Uri.parse(ApiConfig.baseUrl + ApiConfig.findVentas + '/$id');

      //print("━━━━━━━━━━━━━━━━━━━━━━");
      //print("📤 FIND VENTA REQUEST");
      //print("🆔 ID: $id");
      //print("🔗 URL:");
      //print(uri.toString());
      //print("━━━━━━━━━━━━━━━━━━━━━━");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      //print("📡 STATUS: ${response.statusCode}");
      //print("📥 RESPONSE:");
      //print(response.body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ⚠️ importante: esperamos UN objeto
        if (data is Map<String, dynamic>) {
          return data;
        }

        return null;
      }

      return null;
    } catch (e) {
      //print("❌ ERROR findVenta:");
      //print(e);
      return null;
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
    bool onlyTrash = false,
  }) async {
    print("━━━━━━━━━━━━━━━━━━━━━━");
    print("📤 GET VENTAS REQUEST");

    print("📅 startDate: $startDate");
    print("📅 endDate: $endDate");
    print("🔤 code: $code");
    print("💰 pagado: $pagado");
    print("🏆 premiado: $premiado");
    print("🏷️ type: $type");
    print("🎯 loterias: $loteriaIds");
    print("🎯 onlyTrash: $onlyTrash");

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? '';

      final Map<String, dynamic> queryParams = {};

      // =========================
      // FECHAS
      // =========================
      queryParams['onlyTrash'] = onlyTrash ? '1' : '0';

      if (startDate != null) {
        queryParams['fecha_inicio'] = startDate.toIso8601String().split('T')[0];
      }

      if (endDate != null) {
        queryParams['fecha_fin'] = endDate.toIso8601String().split('T')[0];
      }

      // =========================
      // CAMPOS SIMPLES
      // =========================
      if (code != null && code.isNotEmpty) {
        queryParams['code'] = code;
      }

      // ✔️ IMPORTANTE: SOLO SI NO ES NULL
      if (pagado != null) {
        queryParams['pagado'] = pagado.toString();
      }

      if (premiado != null) {
        queryParams['premiado'] = premiado.toString();
      }

      // =========================
      // LISTAS (FIX CRÍTICO)
      // =========================
      if (type != null && type.isNotEmpty) {
        queryParams['type[]'] = type.join(',');
      }

      if (loteriaIds != null && loteriaIds.isNotEmpty) {
        queryParams['loteriaIds[]'] = loteriaIds
            .map((e) => e.toString())
            .join(',');
      }

      final uri = Uri.parse(
        ApiConfig.baseUrl + ApiConfig.getVentas,
      ).replace(queryParameters: queryParams);

      // =========================
      // DEBUG FINAL
      // =========================
      print("🔗 URL FINAL:");
      print(uri.toString());
      print("━━━━━━━━━━━━━━━━━━━━━━");

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          return data;
        }
      }

      return [];
    } catch (e) {
      print("❌ EXCEPTION:");
      print(e);
      return [];
    }
  }

  static Future<ApiResponse> anularVenta(int id) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? '';

      final url = Uri.parse("${ApiConfig.baseUrl}${ApiConfig.anularVenta}/$id");

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      // 🟢 SUCCESS
      if (data['success'] == true) {
        return ApiResponse(
          success: true,
          message: data['message'] ?? 'Venta anulada correctamente',
          errors: [],
          statusCode: response.statusCode,
        );
      }

      // 🔴 ERROR BACKEND
      return ApiResponse(
        success: false,
        message: data['message'] ?? 'Error al anular la venta',
        errors: data['messageList'] ?? [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión',
        errors: [e.toString()],
        statusCode: null,
      );
    }
  }

  static Future<ApiResponse> pagarVenta(int id) async {
    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? '';

      final url = Uri.parse("${ApiConfig.baseUrl}${ApiConfig.pagarVenta}/$id");

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      // 🟢 SUCCESS
      if (data['success'] == true) {
        return ApiResponse(
          success: true,
          message: data['message'] ?? 'Venta pagada correctamente',
          errors: [],
          statusCode: response.statusCode,
        );
      }

      // 🔴 ERROR BACKEND
      return ApiResponse(
        success: false,
        message: data['message'] ?? 'Error al pagar la venta',
        errors: data['messageList'] ?? [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error de conexión',
        errors: [e.toString()],
        statusCode: null,
      );
    }
  }
}
