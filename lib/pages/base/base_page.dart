import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:loterymobile/pages/ventas/ventas_page.dart';
import 'package:loterymobile/pages/resultados/resultados_page.dart';
import 'package:loterymobile/pages/ventas/ventas_realizadas_page.dart';
import 'package:loterymobile/pages/tickets/tickets_premiados_page.dart';
import 'package:loterymobile/pages/tickets/tickets_anulados_page.dart';
import 'package:loterymobile/pages/sorteos/sorteos_page.dart';
import 'package:loterymobile/pages/configuracion/config_impresora_page.dart';
import 'package:loterymobile/pages/configuracion/configuracion_page.dart';

import 'package:loterymobile/services/auth_service.dart';
import 'package:loterymobile/services/user_service.dart';
import '../../theme/theme.dart';

class BasePage extends StatefulWidget {
  final Widget child;

  const BasePage({super.key, required this.child});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  String _currentPage = 'ventas';
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // user information
  Future<void> _loadUser() async {
    final user = await UserService.getUser();
    setState(() {
      _user = user;
    });
  }

  // navegación
  void _navigate(String page) {
    setState(() {
      _currentPage = page;
    });
    Navigator.pop(context);
  }

  // render de páginas
  Widget _getPage() {
    switch (_currentPage) {
      case 'ventas':
        return const VentasPage();
      case 'resultados':
        return const ResultadosPage();
      case 'ventas_realizadas':
        return const VentasRealizadasPage();
      case 'tickets_premiados':
        return const TicketsPremiadosPage();
      case 'tickets_anulados':
        return const TicketsAnuladosPage();
      case 'sorteos':
        return const SorteosPage();
      case 'config_impresora':
        return const ConfigImpresoraPage();
      case 'configuracion':
        return const ConfiguracionPage();
      default:
        return widget.child;
    }
  }

  // Logout
  Future<void> _logout() async {
    await AuthService.logout(context);
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro de cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text("Sí"),
          ),
        ],
      ),
    );

    if (result == true) {
      await _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      // MENU LATERAL
      drawer: Drawer(
        child: Container(
          color: AppColors.primary,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: AppColors.primary),
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _user?.center?.imageBase64 != null
                          ? Image.memory(
                              base64Decode(
                                _user!.center!.imageBase64!.split(',').last,
                              ),
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            )
                          : Image.asset(
                              'assets/images/logo.png',
                              width: 100,
                              height: 100,
                            ),
                      const SizedBox(height: 4),
                      Text(
                        _user?.center?.name ?? 'Centro',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _user?.username ?? 'Usuario',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔽 MENÚ NUEVO
              _item(Icons.point_of_sale, "Ventas", 'ventas'),
              _item(Icons.bar_chart, "Resultados", 'resultados'),
              _item(Icons.list_alt, "Ventas realizadas", 'ventas_realizadas'),
              _item(
                Icons.emoji_events,
                "Tickets premiados",
                'tickets_premiados',
              ),
              _item(Icons.cancel, "Tickets anulados", 'tickets_anulados'),
              _item(Icons.casino, "Sorteos realizados", 'sorteos'),

              const Divider(color: Colors.white54),

              _item(Icons.print, "Config impresora", 'config_impresora'),
              _item(Icons.settings, "Configuración", 'configuracion'),
            ],
          ),
        ),
      ),

      // HEADER
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            color: AppColors.primary,
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          _user?.center?.name ?? 'Banca',
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: AppColors.danger,
            onPressed: _confirmLogout,
          ),
        ],
        elevation: 0,
      ),

      // CONTENIDO
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          child: _getPage(), // 👈 aquí cambia
        ),
      ),
    );
  }

  // 🔹 item reutilizable
  Widget _item(IconData icon, String title, String page) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => _navigate(page),
    );
  }
}
