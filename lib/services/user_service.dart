import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api.dart';

/// Modelo del centro
class CenterInfo {
  final int? id;
  final String? name;
  final String? imageBase64;

  CenterInfo({this.id, this.name, this.imageBase64});

  factory CenterInfo.fromJson(Map<String, dynamic> json) {
    return CenterInfo(
      id: json['id'],
      name: json['name'],
      imageBase64: json['image_base64'],
    );
  }
}

/// Modelo del usuario
class User {
  final int? id;
  final String? name;
  final String? username;
  final String? id_name;
  final String? email;
  final String? gender;
  final String? phone;
  final CenterInfo? center;

  User({
    this.id,
    this.name,
    this.username,
    this.id_name,
    this.email,
    this.gender,
    this.phone,
    this.center,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      id_name: json['id_name'],
      email: json['email'],
      gender: json['gender'],
      phone: json['phone'],
      center: json['center'] != null
          ? CenterInfo.fromJson(json['center'])
          : null,
    );
  }
}

/// Servicio para obtener datos del usuario
class UserService {
  static Future<User?> getUser() async {
    try {
      // final prefs = await SharedPreferences.getInstance();
      // final token = prefs.getString('access_token') ?? '';
      final storage = const FlutterSecureStorage();

      // Obtener token seguro
      final token = await storage.read(key: 'access_token') ?? '';

      if (token.isEmpty) return null;

      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.user);
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // debugPrint(data.toString(), wrapWidth: 1024);
        return User.fromJson(data['user']);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      const storage = FlutterSecureStorage();

      final token = await storage.read(key: 'access_token') ?? '';

      if (token.isEmpty) {
        return {'success': false, 'message': 'Token inválido'};
      }

      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.updateProfile);

      final Map<String, dynamic> body = {'name': name};

      // password solo si viene
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
        body['password_confirmation'] = passwordConfirmation ?? '';
      }

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Perfil actualizado correctamente',
          'user': data['user'],
        };
      }

      return {'success': false, 'message': data['message'].toString()};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<User>> getUsersCanShow() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token') ?? '';

      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.ventasUserCanShow);

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token.isNotEmpty) "Authorization": "Bearer $token",
        },
      );

      // print("🔵 URL: $url");
      // print("🔵 STATUS: ${response.statusCode}");
      // print("🔵 BODY RAW: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // print("🟢 DATA PARSED: $data");

        final List list = data['data'] ?? [];

        // print("🟢 USERS COUNT: ${list.length}");

        return list.map((e) => User.fromJson(e)).toList();
      }

      // print("🔴 ERROR RESPONSE: ${response.body}");
      return [];
    } catch (e) {
      // print("🔥 EXCEPTION: $e");
      return [];
    }
  }
}
