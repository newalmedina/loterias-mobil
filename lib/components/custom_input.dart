import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🔹 Necesario para inputFormatters
import '../theme/theme.dart'; // Tus colores personalizados

class CustomInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final TextInputType keyboardType;
  final bool canVisible;
  final bool hasError; // si true, borde rojo
  final IconData? prefixIcon; // opcional
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final List<TextInputFormatter>?
  inputFormatters; // Para limitar caracteres y dígitos

  // 🔹 Nueva propiedad para habilitar/deshabilitar
  final bool enabled;

  const CustomInput({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.canVisible = true,
    this.hasError = false,
    this.prefixIcon,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled = true, // 🔹 por defecto true
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled, // 🔹 aplicamos el enabled
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.hasError ? Colors.red : AppColors.primary,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.hasError ? Colors.red : AppColors.primary,
            width: 2,
          ),
        ),
        prefixIcon: widget.isPassword
            ? const Icon(Icons.lock)
            : (widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColors.primary)
                  : null),
        suffixIcon: widget.isPassword && widget.canVisible
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }
}
