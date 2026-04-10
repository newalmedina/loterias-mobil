import 'package:flutter/material.dart';
import 'package:loterymobile/services/auth_service.dart';

class JugadasPage extends StatefulWidget {
  const JugadasPage({super.key});

  @override
  State<JugadasPage> createState() => _JugadasPageState();
}

class _JugadasPageState extends State<JugadasPage> {
  @override
  void initState() {
    super.initState();
    AuthService.validateToken(context);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            'Bienvenido a Jugadas!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text(
            'Aquí podrás ver tus jugadas y resultados.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
