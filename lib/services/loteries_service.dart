import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:loterymobile/model/loteriaresult_model.dart';
import 'package:loterymobile/model/loteria_model.dart';
import '../config/api.dart';

class LoteriesService {
  static Future<List<Loteria>> getLoteries() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // final token = prefs.getString('access_token') ?? '';
      // Inicializar storage (puedes ponerlo como variable global o de clase)
      final storage = const FlutterSecureStorage();

      // Obtener token seguro
      final token = await storage.read(key: 'access_token') ?? '';

      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.getloteries);
      //// print('🔹 URL: $url');
      //// print('🔹 Token: ${token.isNotEmpty ? "[OK]" : "[VACÍO]"}');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      //// print('🔹 Status code: ${response.statusCode}');
      //// print('🔹 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] == null) {
          //// print('❌ data es null');
          return [];
        }

        final List<dynamic> list = data['data'];
        //// print('🔹 Lista recibida length: ${list.length}');
        return list.map((e) => Loteria.fromJson(e)).toList();
      } else {
        //// print('❌ Status code diferente a 200');
        return [];
      }
    } catch (e) {
      //// print('Error fetching loteries: $e');
      // print(st);
      return [];
    }
  }

  static Future<List<Loteria>> getloteriesDisponibles() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // final token = prefs.getString('access_token') ?? '';
      // Inicializar storage (puedes ponerlo como variable global o de clase)
      final storage = const FlutterSecureStorage();

      // Obtener token seguro
      final token = await storage.read(key: 'access_token') ?? '';

      final url = Uri.parse(
        ApiConfig.baseUrl + ApiConfig.getloteriesDisponibles,
      );
      //// print('🔹 URL: $url');
      //// print('🔹 Token: ${token.isNotEmpty ? "[OK]" : "[VACÍO]"}');

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      // print('🔹 Status code: ${response.statusCode}');
      // print('🔹 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] == null) {
          // print('❌ data es null');
          return [];
        }

        final List<dynamic> list = data['data'];

        // print('🔹 Lista recibida length: ${list.length}');
        return list.map((e) => Loteria.fromJson(e)).toList();
      } else {
        // print('❌ Status code diferente a 200');
        return [];
      }
    } catch (e) {
      // print('Error fetching loteries: $e');
      // print(e);
      return [];
    }
  }

  static Future<List<LoteriaResult>> getResults({
    required DateTime startDate,
    DateTime? endDate,
    List<int>? loteriesIds,
    bool reload = false,
  }) async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // final token = prefs.getString('access_token') ?? '';
      // Inicializar storage (puedes ponerlo como variable global o de clase)
      final storage = const FlutterSecureStorage();

      // Obtener token seguro
      final token = await storage.read(key: 'access_token') ?? '';

      // Preparar parámetros de consulta
      final Map<String, dynamic> queryParams = {
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': (endDate ?? startDate).toIso8601String().split('T')[0],
        'reload': reload.toString(),
      };

      // Enviar loterías como array
      if (loteriesIds != null && loteriesIds.isNotEmpty) {
        for (int i = 0; i < loteriesIds.length; i++) {
          queryParams['loteries[$i]'] = loteriesIds[i].toString();
        }
      }

      final uri = Uri.parse(
        ApiConfig.baseUrl + ApiConfig.getResults,
      ).replace(queryParameters: queryParams);

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
        if (data['data'] == null || data['data'] is! List) return [];
        return List<LoteriaResult>.from(
          data['data'].map((e) => LoteriaResult.fromJson(e)),
        );
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
