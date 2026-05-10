import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loterymobile/pages/lotery/results_page.dart';
import 'package:loterymobile/theme/theme.dart';
import 'package:loterymobile/widgets/snackbar_helper.dart';
import '../config/api.dart';
import '../pages/login/login_page.dart';

class AuthService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  //login
  static Future<bool> login(
    BuildContext context,
    String login,
    String password, {
    bool rememberUser = false,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.login);
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"login": login, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (data["code"] == 200) {
        final token = data["access_token"];
        // print(data);
        final userId = data["user"]["id"];

        // Guardar token
        await _storage.write(key: 'access_token', value: token);
        await _storage.write(key: 'user_id', value: userId.toString());

        // Guardar o borrar usuario/contraseña según rememberUser
        if (rememberUser) {
          await _storage.write(key: 'saved_user', value: login);
          await _storage.write(key: 'saved_pass', value: password);
        } else {
          await _storage.delete(key: 'saved_user');
          await _storage.delete(key: 'saved_pass');
        }

        // Mostrar snackbar de éxito
        if (context.mounted) {
          SnackbarHelper.show(
            context,
            message: "Sesión iniciada correctamente",
            backgroundColor: AppColors.success,
          );

          // Navegar a ResultsPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResultsPage()),
            // MaterialPageRoute(builder: (_) => ResultsPage(token: token)),
          );
        }

        return true;
      } else {
        if (context.mounted) {
          SnackbarHelper.show(
            context,
            message: data["message"].toString(),
            backgroundColor: AppColors.danger,
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.show(
          context,
          message: "Error: $e",
          backgroundColor: AppColors.danger,
        );
      }
      return false;
    }
  }

  static Future<void> logout(BuildContext context) async {
    try {
      final token = await _storage.read(key: 'access_token') ?? '';

      // Llamar al endpoint de logout si hay token
      if (token.isNotEmpty) {
        final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.logout);
        await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token",
          },
        );
      }

      // Borrar solo lo necesario
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'user_id');
      // NO borramos saved_user ni saved_pass para respetar "recordar usuario"

      // Navegar a LoginPage y limpiar la pila
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.show(
          context,
          message: "Error al cerrar sesión: $e",
          backgroundColor: AppColors.danger,
        );
      }
    }
  }

  /// Valida el token. Si es inválido, redirige al LoginPage.
  static Future<bool> validateToken(BuildContext context) async {
    try {
      final token = await _storage.read(key: 'access_token') ?? '';
      // print("Token leído: $token");

      if (token.isEmpty) {
        // print("Token vacío, redirigiendo al login...");
        // ignore: use_build_context_synchronously
        _redirectToLogin(context);
        return false;
      }

      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.validateToken);
      // print("URL de validación: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // print("Código de respuesta: ${response.statusCode}");
      // print("Cuerpo de respuesta: ${response.body}");

      if (response.statusCode == 200) {
        // print("Token válido");
        return true;
      } else {
        // print("Token inválido, redirigiendo al login...");
        // ignore: use_build_context_synchronously
        _redirectToLogin(context);
        return false;
      }
    } catch (e) {
      // print("Error validando token: $e");
      // ignore: use_build_context_synchronously
      _redirectToLogin(context);
      return false;
    }
  }

  /// Borra token y redirige al LoginPage
  static void _redirectToLogin(BuildContext context) async {
    // Borrar token
    await _storage.delete(key: 'access_token');

    // Mostrar alerta
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Autenticación inválida'),
          content: const Text(
            'El token de autenticación no es válido o ha expirado. Por favor, inicie sesión nuevamente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      // Redirigir al LoginPage
      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
