import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loterymobile/components/custom_button.dart';
import 'package:loterymobile/components/custom_date_input.dart';
import 'package:loterymobile/components/custom_input.dart';
import 'package:loterymobile/model/loteria_model.dart';
import 'package:loterymobile/services/loteries_service.dart';
import 'package:loterymobile/services/user_service.dart';
import 'package:loterymobile/theme/theme.dart';
import 'package:loterymobile/widgets/snackbar_helper.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:loterymobile/services/ventas_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VentasFiltros extends StatefulWidget {
  final Function(Map<String, dynamic>) onSearch;
  final String? moduleName; // 👈 nuevo

  const VentasFiltros({super.key, required this.onSearch, this.moduleName});

  @override
  State<VentasFiltros> createState() => _VentasFiltrosState();
}

class _VentasFiltrosState extends State<VentasFiltros> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  // =========================
  // CONTROLLERS
  // =========================
  final TextEditingController _ticketController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  // =========================
  // ESTADO
  // =========================
  int? _estadoVenta;
  int? _pagadas;

  final Map<String, bool> _typeFilters = {
    'Qui': false,
    'Pal': false,
    'SPal': false,
    'Tri': false,
  };

  List<Loteria> _loterias = [];
  Map<int, bool> _loteriaFilters = {};
  bool _loadingLoterias = false;

  List<User> _users = [];
  List<int> _usersSelected = [];
  bool _loadingUsers = false;

  // =========================
  // INIT
  // =========================
  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    final formatted = DateFormat('dd-MM-yyyy').format(today);

    _fechaInicioController.text = formatted;
    _fechaFinController.text = formatted;
    // _loadInitialData();
    // _loadLoterias();
    // _loadUsers();
  }

  Future<void> _loadInitialData() async {
    await _loadLoterias();
    await _loadUsers();

    // 🔥 leer user_id guardado
    final userId = await _storage.read(key: 'user_id');

    if (userId != null) {
      setState(() {
        _usersSelected = [int.parse(userId)];
      });
    }

    // 🔥 buscar automáticamente
    _onSearch();
  }

  Future<void> _loadLoterias() async {
    setState(() => _loadingLoterias = true);

    final data = await LoteriesService.getLoteries();

    setState(() {
      _loterias = data;
      _loteriaFilters = {for (var l in data) l.id: false};
      _loadingLoterias = false;
    });
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);

    final data = await UserService.getUsersCanShow();

    setState(() {
      _users = data;
      _loadingUsers = false;
    });
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        ExpansionTile(
          initiallyExpanded: true,
          leading: const Icon(Icons.tune),
          title: const Text('Filtros'),
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            // ================= TICKET =================
            Row(
              children: [
                Expanded(
                  flex: 9,
                  child: CustomInput(
                    controller: _ticketController,
                    label: 'Número de ticket',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.confirmation_number,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    String? result = await showModalBottomSheet<String>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: MobileScanner(
                            fit: BoxFit.cover,
                            controller: MobileScannerController(
                              detectionSpeed: DetectionSpeed.noDuplicates,
                              facing: CameraFacing.back,
                              torchEnabled: false,
                            ),
                            onDetect: (capture) {
                              final barcodes = capture.barcodes;

                              if (barcodes.isNotEmpty) {
                                final code = barcodes.first.rawValue;

                                if (code != null) {
                                  Navigator.pop(context, code);
                                }
                              }
                            },
                          ),
                        );
                      },
                    );

                    if (result != null) {
                      debugPrint("QR leído: $result");
                      // aquí haces lo que quieras con el QR
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ================= FECHAS =================
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;

                final inicio = CustomDateInput(
                  controller: _fechaInicioController,
                  label: 'F. Inicial',
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );

                final fin = CustomDateInput(
                  controller: _fechaFinController,
                  label: 'F. Final',
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );

                return isWide
                    ? Row(
                        children: [
                          Expanded(child: inicio),
                          const SizedBox(width: 10),
                          Expanded(child: fin),
                        ],
                      )
                    : Column(
                        children: [inicio, const SizedBox(height: 10), fin],
                      );
              },
            ),

            const SizedBox(height: 10),

            // ================= BOTONES =================
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: _openMoreFilters,
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        height: 48,
                        child: Center(
                          child: Icon(
                            Icons.filter_alt,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: _onSearch,
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        height: 48,
                        child: Center(
                          child: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () {
                        _clearAllFilters();
                        _onSearch();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        height: 48,
                        child: Center(
                          child: Icon(
                            Icons.cleaning_services,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: AppColors.quaternary,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () =>
                          _buscarUuid("106d0823-61e9-4d06-a85a-347253ef280d"),
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        height: 48,
                        child: Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),

        // ================= RESUMEN SIEMPRE VISIBLE =================
        // ================= RESUMEN FILTROS =================
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _buildResumenFiltros(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  } // =========================

  String _buildResumenFiltros() {
    List<String> partes = [];

    if (_usersSelected.isNotEmpty) {
      final names = _usersSelected.map((id) {
        final user = _users.firstWhere(
          (u) => u.id == id,
          orElse: () => User(id: id, name: "Usuario"),
        );
        return user.id_name ?? user.id_name ?? '';
      }).toList();

      if (_users.length > 1) {
        partes.add("Usuarios: ${names.join(', ')}");
      }
    }
    // ================= FECHAS =================
    if (_fechaInicioController.text.isNotEmpty ||
        _fechaFinController.text.isNotEmpty) {
      partes.add(
        "Fechas: ${_fechaInicioController.text} → ${_fechaFinController.text}",
      );
    }

    // ================= TICKET =================
    if (_ticketController.text.isNotEmpty) {
      partes.add("Ticket: ${_ticketController.text}");
    }

    // ================= ESTADO VENTA =================
    if (_estadoVenta != null) {
      partes.add(_estadoVenta == 1 ? "Premiados" : "No premiados");
    }

    // ================= PAGADAS =================
    if (_pagadas != null) {
      partes.add(_pagadas == 1 ? "Pagados" : "No pagados");
    }

    // ================= TIPOS (modal checkbox) =================
    final tiposSeleccionados =
        _typeFilters.entries.where((e) => e.value).map((e) => e.key).toList();

    if (tiposSeleccionados.isNotEmpty) {
      partes.add("Tipos: ${tiposSeleccionados.join(', ')}");
    }

    // ================= LOTERÍAS (modal checkbox) =================
    final loteriasSeleccionadas =
        _loteriaFilters.entries.where((e) => e.value).map((e) {
      final loteria = _loterias.firstWhere((l) => l.id == e.key);
      return loteria.nombre;
    }).toList();

    if (loteriasSeleccionadas.isNotEmpty) {
      partes.add("Loterías: ${loteriasSeleccionadas.join(', ')}");
    }

    return partes.isEmpty ? "Sin filtros aplicados" : partes.join("  |  ");
  }

  // SEARCH
  // =========================
  void _onSearch() {
    final filters = {
      "ticket": _ticketController.text,
      "startDate": _fechaInicioController.text,
      "endDate": _fechaFinController.text,
      "estadoVenta": _estadoVenta,
      "pagadas": _pagadas,
      "types":
          _typeFilters.entries.where((e) => e.value).map((e) => e.key).toList(),
      "loterias": _loteriaFilters.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      "users": _usersSelected,
    };

    //print("📦 FILTROS: $filters");

    widget.onSearch(filters);
  }

  // =========================
  // MODAL
  // =========================
  void _openMoreFilters() {
    String search = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Más filtros',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ================= USUARIO =================
                      // ================= USUARIO =================
                      const SizedBox(height: 12),

                      // ================= BODY SCROLL =================
                      Expanded(
                        child: _loadingLoterias
                            ? const Center(child: CircularProgressIndicator())
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ================= USUARIOS =================
                                    if (_users.length > 1) ...[
                                      const Text("Usuarios"),
                                      const SizedBox(height: 6),
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxHeight: 250,
                                        ),
                                        child: Scrollbar(
                                          thumbVisibility: true,
                                          child: ListView(
                                            shrinkWrap: true,
                                            children: _users.map((u) {
                                              return CheckboxListTile(
                                                title: Text(
                                                  "${u.username ?? ''} - ${u.name ?? ''}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                value: _usersSelected.contains(
                                                  u.id,
                                                ),
                                                onChanged: (val) {
                                                  if (u.id == null) return;

                                                  setState(() {
                                                    if (val == true) {
                                                      if (!_usersSelected
                                                          .contains(u.id)) {
                                                        _usersSelected.add(
                                                          u.id!,
                                                        );
                                                      }
                                                    } else {
                                                      _usersSelected.remove(
                                                        u.id,
                                                      );
                                                    }
                                                  });

                                                  setModalState(() {});
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    // ================= ESTADO VENTA =================
                                    if (widget.moduleName !=
                                        'tickets_anulados') ...[
                                      if (widget.moduleName !=
                                          'tickets_premiados') ...[
                                        const Text("Estado de venta"),
                                        DropdownButton<int?>(
                                          value: _estadoVenta,
                                          isExpanded: true,
                                          items: const [
                                            DropdownMenuItem(
                                              value: null,
                                              child: Text('Todos'),
                                            ),
                                            DropdownMenuItem(
                                              value: 1,
                                              child: Text('Premiados'),
                                            ),
                                            DropdownMenuItem(
                                              value: 0,
                                              child: Text('No premiados'),
                                            ),
                                          ],
                                          onChanged: (v) {
                                            setState(() => _estadoVenta = v);
                                            setModalState(() {});
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                      ],

                                      // ================= ESTADO PAGO =================
                                      const Text("Estado de pago"),

                                      DropdownButton<int?>(
                                        value: _pagadas,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(
                                            value: null,
                                            child: Text('Todos'),
                                          ),
                                          DropdownMenuItem(
                                            value: 1,
                                            child: Text('Pagados'),
                                          ),
                                          DropdownMenuItem(
                                            value: 0,
                                            child: Text('No pagados'),
                                          ),
                                        ],
                                        onChanged: (v) {
                                          setState(() => _pagadas = v);
                                          setModalState(() {});
                                        },
                                      ),

                                      const SizedBox(height: 10),
                                    ],

                                    // ================= TIPOS =================
                                    const Text("Tipo"),

                                    ..._typeFilters.keys.map((key) {
                                      return CheckboxListTile(
                                        title: Text(key),
                                        value: _typeFilters[key],
                                        onChanged: (val) {
                                          setState(() {
                                            _typeFilters[key] = val ?? false;
                                          });
                                          setModalState(() {});
                                        },
                                      );
                                    }),

                                    const Divider(),

                                    // ================= LOTERÍAS (comentado) =================

                                    // const Text("Loterías"),

                                    // ..._loterias
                                    //     .where(
                                    //       (l) => l.nombre.toLowerCase().contains(
                                    //         search,
                                    //       ),
                                    //     )
                                    //     .map((l) {
                                    //       return CheckboxListTile(
                                    //         title: Text(l.nombre),
                                    //         value: _loteriaFilters[l.id] ?? false,
                                    //         onChanged: (val) {
                                    //           setState(() {
                                    //             _loteriaFilters[l.id] =
                                    //                 val ?? false;
                                    //           });
                                    //           setModalState(() {});
                                    //         },
                                    //       );
                                    //     }),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: 10),

                      // ================= BOTÓN =================
                      CustomButton(
                        text: 'Cerrar',
                        icon: Icons.check,
                        color: AppColors.primary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _ticketController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      // ================= CONTROLLERS =================
      _ticketController.clear();
      _fechaInicioController.clear();
      _fechaFinController.clear();

      // ================= ESTADOS =================
      _estadoVenta = null;
      _pagadas = null;
      // ================= USERS =================
      _usersSelected.clear();
      // ================= MAPS =================
      _typeFilters.updateAll((key, value) => false);
      _loteriaFilters.updateAll((key, value) => false);
    });
  }

  Future<void> _buscarUuid(String uuid) async {
    final cleanUuid = uuid.trim();
    print("ANTES DEL SERVICE");
    // ⚠️ validar vacío
    if (cleanUuid.isEmpty) {
      SnackbarHelper.show(
        context,
        message: "UUID inválido",
        backgroundColor: AppColors.warning,
      );
      return;
    }

    // 🔄 llamada al service
    final result = await VentasService.findVentaByUiid(cleanUuid, context);

    // ❌ si hubo error (el service ya muestra snackbar)
    if (result == null) return;

    // 🔥 EXTRAER CODE COMO TICKET
    final code = result['code'];

    _clearAllFilters(); // 🔥 LIMPIA TODO

    setState(() {
      _ticketController.text = code ?? '';
    });

    SnackbarHelper.show(
      context,
      message: "Venta cargada correctamente",
      backgroundColor: AppColors.success,
    );
    _onSearch();
  }
}
