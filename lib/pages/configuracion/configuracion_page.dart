import 'package:flutter/material.dart';
import 'package:loterymobile/components/custom_input.dart';
import 'package:loterymobile/services/user_service.dart';
import 'package:loterymobile/theme/theme.dart';
import 'package:loterymobile/components/custom_button.dart';
import 'package:loterymobile/widgets/snackbar_helper.dart';

class ConfiguracionPage extends StatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  State<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends State<ConfiguracionPage> {
  final TextEditingController userNaController = TextEditingController(
    text: "usuario_demo",
  );

  final TextEditingController nameController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();
  User? _user;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> updateProfile() async {
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final repeat = repeatPasswordController.text.trim();

    // ================= VALIDACIONES =================
    if (name.isEmpty) {
      SnackbarHelper.show(
        context,
        message: "El nombre es obligatorio",
        backgroundColor: AppColors.danger,
      );
      return;
    }

    if (password.isNotEmpty) {
      if (password.length < 6) {
        SnackbarHelper.show(
          context,
          message: "La contraseña debe tener mínimo 6 caracteres",
          backgroundColor: AppColors.warning,
        );
        return;
      }

      if (password != repeat) {
        SnackbarHelper.show(
          context,
          message: "Las contraseñas no coinciden",
          backgroundColor: AppColors.danger,
        );
        return;
      }
    }

    setState(() => loading = true);

    try {
      final response = await UserService.updateProfile(
        name: name,
        password: password.isNotEmpty ? password : null,
        passwordConfirmation: repeat.isNotEmpty ? repeat : null,
      );

      if (response['success'] == true) {
        // limpiar passwords
        passwordController.clear();
        repeatPasswordController.clear();

        await _loadUser();

        SnackbarHelper.show(
          context,
          message: response['message'],
          backgroundColor: AppColors.success,
        );
      } else {
        SnackbarHelper.show(
          context,
          message: response['message'],
          backgroundColor: AppColors.danger,
        );
      }
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: "Error al actualizar",
        backgroundColor: AppColors.danger,
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadUser() async {
    final user = await UserService.getUser();

    if (user == null) return;

    setState(() {
      _user = user;

      // llenar form
      userNaController.text = user.username ?? '';
      nameController.text = user.name ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración General',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 20),

          // ================= USER (DISABLED) =================
          CustomInput(
            controller: userNaController,
            label: "Usuario",
            prefixIcon: Icons.person,
            enabled: false,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 12),

          // ================= NAME =================
          CustomInput(
            controller: nameController,
            label: "Nombre",
            prefixIcon: Icons.badge,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 12),
          // ================= PASSWORD =================
          CustomInput(
            controller: passwordController,
            label: "Contraseña (opcional)",
            textInputAction: TextInputAction.next,
            isPassword: true,
          ),

          const SizedBox(height: 4),

          const Text(
            "Solo se modificará si escribes una nueva contraseña",
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),

          const SizedBox(height: 8),

          // ================= REPEAT PASSWORD =================
          CustomInput(
            controller: repeatPasswordController,
            label: "Repetir contraseña",
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) async {
              await updateProfile();
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: loading ? "Guardando..." : "Actualizar",
              icon: Icons.save,
              color: AppColors.primary,
              onPressed: loading ? () {} : () async => await updateProfile(),
            ),
          ),
        ],
      ),
    );
  }
}
