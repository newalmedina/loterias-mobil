import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:loterymobile/components/custom_checkbox.dart';
import 'package:loterymobile/services/auth_service.dart';
import 'package:loterymobile/widgets/snackbar_helper.dart';

import '../../components/custom_input.dart';
import '../../components/custom_button.dart';
import '../../theme/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController(
    text: '23479', // Valor por defecto
    // text: '', // Valor por defecto
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'EithanSteven15*', // Valor por defecto
    // text: '', // Valor por defecto
  );

  bool _rememberUser = false;
  bool _loading = false;

  // Flags de error
  bool _userError = false;
  bool _passwordError = false;

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    _loadSavedCredentials();
  }

  // Cargar credenciales seguras si existen
  Future<void> _loadSavedCredentials() async {
    final savedUser = await _storage.read(key: 'saved_user') ?? '';
    final savedPass = await _storage.read(key: 'saved_pass') ?? '';

    if (savedUser.isNotEmpty && savedPass.isNotEmpty) {
      _userController.text = savedUser;
      _passwordController.text = savedPass;
      setState(() => _rememberUser = true);
    }
  }

  // Función de login normal
  Future<void> _login() async {
    final loginText = _userController.text.trim();
    final passwordText = _passwordController.text.trim();

    // Validar campos obligatorios
    if (loginText.isEmpty || passwordText.isEmpty) {
      setState(() {
        _userError = loginText.isEmpty;
        _passwordError = passwordText.isEmpty;
      });
      SnackbarHelper.show(
        context,
        message: "Usuario y contraseña son obligatorios",
        backgroundColor: AppColors.danger,
      );

      return;
    } else {
      setState(() {
        _userError = false;
        _passwordError = false;
      });
    }

    setState(() => _loading = true);

    try {
      final success = await AuthService.login(
        context,
        loginText,
        passwordText,
        rememberUser: _rememberUser, // si agregas este parámetro al service
      );
      setState(() => _loading = false);

      if (!success) {
        // Ya el AuthService muestra los diálogos de error, no necesitas más.
      }
    } catch (e) {
      setState(() => _loading = false);
      SnackbarHelper.show(
        // ignore: use_build_context_synchronously
        context,
        message: "Error: $e",
        backgroundColor: AppColors.danger,
      );
    }
  }

  // Función de login biométrico
  Future<void> _loginWithBiometrics() async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        SnackbarHelper.show(
          // ignore: use_build_context_synchronously
          context,
          message: 'Este dispositivo no soporta biometría',
          backgroundColor: AppColors.danger,
        );

        return;
      }

      bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Autentícate para iniciar sesión',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        // Recuperar credenciales seguras
        String? savedUser = await _storage.read(key: 'saved_user');
        String? savedPass = await _storage.read(key: 'saved_pass');

        if (savedUser != null && savedPass != null) {
          _userController.text = savedUser;
          _passwordController.text = savedPass;
          _login(); // Llamar al login existente
        } else {
          SnackbarHelper.show(
            // ignore: use_build_context_synchronously
            context,
            message: 'No hay credenciales guardadas',
            backgroundColor: AppColors.warning,
          );
        }
      }
    } catch (e) {
      SnackbarHelper.show(
        // ignore: use_build_context_synchronously
        context,
        message: 'Error biométrico: $e',
        backgroundColor: AppColors.danger,
      );
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              SizedBox(
                height: 300,
                width: 300,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              // Usuario
              CustomInput(
                controller: _userController,
                label: 'Usuario',
                hasError: _userError,
                prefixIcon: Icons.person, // 🔹 aquí pasas el icono
              ),
              const SizedBox(height: 20),

              // Contraseña
              CustomInput(
                controller: _passwordController,
                label: 'Contraseña',
                isPassword: true,
                hasError: _passwordError,
              ),
              const SizedBox(height: 20),

              // Recordar usuario y contraseña
              Row(
                children: [
                  CustomCheckbox(
                    value: _rememberUser,
                    onChanged: (value) {
                      setState(() {
                        _rememberUser = value ?? false;
                      });
                    },
                    borderColor: AppColors
                        .primary, // color del borde cuando NO está marcado
                    activeColor: AppColors
                        .secondary, // color de relleno cuando está marcado
                    size: 24, // opcional, tamaño del checkbox
                  ),
                  const Text('Recordar usuario y contraseña'),
                ],
              ),
              const SizedBox(height: 20),

              // Botón de login normal
              _loading
                  ? const CircularProgressIndicator()
                  : CustomButton(text: 'Ingresar', onPressed: _login),
              const SizedBox(height: 10),

              // Botón de login biométrico
              CustomButton(
                text: 'Ingresar con huella / Face ID',
                onPressed: _loginWithBiometrics,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
