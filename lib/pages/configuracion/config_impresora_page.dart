import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:loterymobile/components/custom_button.dart';
import 'package:loterymobile/components/custom_input.dart';
import 'package:loterymobile/theme/theme.dart';
import 'package:loterymobile/widgets/snackbar_helper.dart';

class ConfigImpresoraPage extends StatefulWidget {
  const ConfigImpresoraPage({super.key});

  @override
  State<ConfigImpresoraPage> createState() => _ConfigImpresoraPageState();
}

class _ConfigImpresoraPageState extends State<ConfigImpresoraPage> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  List<BluetoothDevice> printers = [];
  BluetoothDevice? selectedPrinter;

  final TextEditingController paperSizeController = TextEditingController(
    text: "58",
  );

  bool isLoading = true;
  bool isConnected = false;

  static const String kPrinterKey = 'selected_printer';
  static const String kPaperKey = 'paper_size';

  String? _pendingPrinterAddress;

  @override
  void initState() {
    super.initState();
    loadConfig();
  }

  // 🔥 FLUJO PRINCIPAL (orden correcto)
  Future<void> loadConfig() async {
    await loadSavedConfig();
    await loadPrinters();
  }

  // 💾 cargar configuración guardada primero
  Future<void> loadSavedConfig() async {
    final savedPrinter = await storage.read(key: kPrinterKey);
    final savedPaper = await storage.read(key: kPaperKey);

    paperSizeController.text = savedPaper ?? "58";

    _pendingPrinterAddress = savedPrinter;
  }

  // 🔵 cargar impresoras
  Future<void> loadPrinters() async {
    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();

      setState(() {
        printers = devices;
        isLoading = false;
      });

      applySavedPrinter();
    } catch (e) {
      setState(() {
        printers = [];
        isLoading = false;
      });
    }
  }

  // 🧠 aplicar impresora guardada cuando ya existen devices
  void applySavedPrinter() {
    if (_pendingPrinterAddress == null) return;

    try {
      final match = printers.firstWhere(
        (p) => p.address == _pendingPrinterAddress,
      );

      setState(() {
        selectedPrinter = match;
      });
    } catch (_) {}
  }

  // 🔌 conectar
  Future<void> connectPrinter() async {
    if (selectedPrinter == null) return;

    try {
      await bluetooth.connect(selectedPrinter!);

      setState(() {
        isConnected = true;
      });

      SnackbarHelper.show(
        context,
        message: "Impresora conectada",
        backgroundColor: AppColors.success,
      );
    } catch (e) {
      SnackbarHelper.show(
        context,
        message: "Error conexión: $e",
        backgroundColor: AppColors.danger,
      );
    }
  }

  // 💾 guardar config
  Future<void> saveConfig() async {
    await storage.write(
      key: kPrinterKey,
      value: selectedPrinter?.address ?? '',
    );

    await storage.write(key: kPaperKey, value: paperSizeController.text);

    SnackbarHelper.show(
      context,
      message: "Configuración guardada",
      backgroundColor: AppColors.success,
    );
  }

  // 🧪 test print
  void printTestPage() {
    bluetooth.printNewLine();
    bluetooth.printCustom("TICKET PRUEBA", 3, 1);
    bluetooth.printCustom("----------------------", 1, 1);
    bluetooth.printCustom("Impresora OK", 1, 1);
    bluetooth.printCustom("Papel: ${paperSizeController.text}mm", 1, 1);
    bluetooth.printNewLine();
    bluetooth.paperCut();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración de Impresora',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 20),

          // 🔄 loading
          if (isLoading) const Center(child: CircularProgressIndicator()),

          // ❌ no printers
          if (!isLoading && printers.isEmpty)
            const Text("No hay impresoras emparejadas"),

          // 🖨️ dropdown
          if (!isLoading && printers.isNotEmpty) ...[
            DropdownButtonFormField<BluetoothDevice>(
              value: selectedPrinter,
              decoration: const InputDecoration(
                labelText: "Seleccionar impresora",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.print),
              ),
              items: printers.map((device) {
                return DropdownMenuItem(
                  value: device,
                  child: Text(device.name ?? "Sin nombre"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedPrinter = value;
                  isConnected = false;
                });
              },
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Conectar impresora',
                icon: Icons.link,
                color: AppColors.primary,
                onPressed: connectPrinter,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 📏 papel
          CustomInput(
            controller: paperSizeController,
            label: "Tamaño del papel (mm)",
            prefixIcon: Icons.straighten,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) async {
              await saveConfig(); // 👈 ejecuta guardado
              FocusScope.of(context).unfocus(); // cierra teclado
            },
          ),

          const SizedBox(height: 20),

          // 💾 guardar
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Guardar configuración',
              icon: Icons.save,
              color: AppColors.primary,
              onPressed: saveConfig,
            ),
          ),

          const SizedBox(height: 10),

          // 🧪 test print
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Imprimir prueba',
              icon: Icons.receipt,
              color: isConnected ? AppColors.success : Colors.grey,
              onPressed: () {
                if (!isConnected) {
                  SnackbarHelper.show(
                    context,
                    message: "Primero conecta la impresora",
                    backgroundColor: AppColors.warning,
                  );
                  return;
                }
                printTestPage();
              },
            ),
          ),
        ],
      ),
    );
  }
}
