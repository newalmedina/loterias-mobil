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
  final String? email;
  final String? gender;
  final String? phone;
  final CenterInfo? center;

  User({
    this.id,
    this.name,
    this.username,
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
}
