import 'package:flutter/material.dart';
import 'pages/login/login_page.dart';
import 'theme/theme.dart'; // Importa tu theme

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoteryMobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, // Usando el primary de Bootstrap 5
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
