import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:esc_pos_utils/esc_pos_utils.dart';

import 'package:loterymobile/components/custom_button.dart';
import 'package:loterymobile/components/custom_input.dart';
import 'package:loterymobile/theme/theme.dart';
import 'package:loterymobile/widgets/snackbar_helper.dart';

import 'package:loterymobile/pages/tickets/reporte_page.dart';

class ConfigImpresoraPage extends StatefulWidget {
  const ConfigImpresoraPage({super.key});

  @override
  State<ConfigImpresoraPage> createState() => _ConfigImpresoraPageState();
}

class _ConfigImpresoraPageState extends State<ConfigImpresoraPage> {
  final storage = const FlutterSecureStorage();
  final ReporteTicketService printerService = ReporteTicketService();

  static const kPrinterKey = 'selected_printer_address';
  static const kPaperKey = 'paper_size';

  List<BluetoothDevice> printers = [];
  BluetoothDevice? selectedPrinter;

  bool scanning = false;

  final paperSizeController = TextEditingController(text: "58");

  String? savedPrinterAddress;

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  Future<void> loadConfig() async {
    final paper = await storage.read(key: kPaperKey);
    final saved = await storage.read(key: kPrinterKey);

    setState(() {
      paperSizeController.text = paper ?? "58";
      savedPrinterAddress = saved;
    });
  }

  // =========================
  Future<void> scanPrinters() async {
    setState(() {
      scanning = true;
      printers.clear();
    });

    // limpiar stream anterior (IMPORTANTE)
    await FlutterBluePlus.stopScan();

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    final subscription = FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        final d = r.device;

        if (!printers.any((e) => e.remoteId == d.remoteId)) {
          setState(() => printers.add(d));
        }

        if (savedPrinterAddress != null &&
            d.remoteId.str == savedPrinterAddress) {
          setState(() => selectedPrinter = d);
        }
      }
    });

    await Future.delayed(const Duration(seconds: 5));

    await FlutterBluePlus.stopScan();
    await subscription.cancel();

    setState(() {
      scanning = false;
    });
  }

  // =========================
  Future<void> connectPrinter(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
    } catch (_) {
      // ya conectado o fallo silencioso
    }
  }

  // =========================
  Future<BluetoothCharacteristic?> _getWritableChar(
    BluetoothDevice device,
  ) async {
    final services = await device.discoverServices();

    for (var s in services) {
      for (var c in s.characteristics) {
        if (c.properties.write || c.properties.writeWithoutResponse) {
          return c;
        }
      }
    }
    return null;
  }

  // =========================
  Future<void> printBytes(List<int> bytes) async {
    if (selectedPrinter == null) return;

    await connectPrinter(selectedPrinter!);

    final char = await _getWritableChar(selectedPrinter!);

    if (char == null) {
      throw Exception("La impresora no tiene canal de escritura");
    }

    await char.write(bytes, withoutResponse: true);
  }

  // =========================
  Future<void> saveConfig() async {
    await storage.write(key: kPaperKey, value: paperSizeController.text);

    if (selectedPrinter != null) {
      await storage.write(
        key: kPrinterKey,
        value: selectedPrinter!.remoteId.str,
      );
    }

    SnackbarHelper.show(
      context,
      message: "Configuración guardada",
      backgroundColor: AppColors.success,
    );
  }

  // =========================
  Future<void> printTest() async {
    try {
      final bytes = await printerService.buildTicket(
        ventas: [
          {
            "code": "TEST001",
            "date": DateTime.now().toString(),
            "details": [
              {
                "short_name": "TEST",
                "number_formatted": "01",
                "type": "A",
                "monto_jugada": 100,
              },
            ],
          },
        ],
        title: "TICKET PRUEBA",
      );

      await printBytes(bytes);

      SnackbarHelper.show(
        context,
        message: "Impresión correcta",
        backgroundColor: AppColors.success,
      );
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: "Error impresión: $e",
        backgroundColor: AppColors.danger,
      );
    }
  }

  // =========================
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Configuración de Impresora",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (selectedPrinter != null)
            Text("Impresora: ${selectedPrinter!.platformName}"),
          const SizedBox(height: 20),
          CustomInput(
            controller: paperSizeController,
            label: "Tamaño papel (mm)",
            prefixIcon: Icons.print,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: scanning ? "Buscando..." : "Buscar impresoras",
              icon: Icons.bluetooth_searching,
              color: AppColors.primary,
              onPressed: scanning ? () {} : () => scanPrinters(),
            ),
          ),
          const SizedBox(height: 10),
          ...printers.map((p) {
            return RadioListTile<BluetoothDevice>(
              title: Text(
                p.platformName.isEmpty ? "Sin nombre" : p.platformName,
              ),
              subtitle: Text(p.remoteId.str),
              value: p,
              groupValue: selectedPrinter,
              onChanged: (v) => setState(() => selectedPrinter = v),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: "Guardar configuración",
              icon: Icons.save,
              color: AppColors.primary,
              onPressed: saveConfig,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: "Prueba impresión",
              icon: Icons.receipt,
              color: AppColors.success,
              onPressed: printTest,
            ),
          ),
        ],
      ),
    );
  }
}
