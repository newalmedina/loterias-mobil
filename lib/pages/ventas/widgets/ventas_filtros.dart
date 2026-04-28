import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loterymobile/components/custom_button.dart';
import 'package:loterymobile/components/custom_date_input.dart';
import 'package:loterymobile/components/custom_input.dart';
import 'package:loterymobile/model/loteria_model.dart';
import 'package:loterymobile/services/loteries_service.dart';
import 'package:loterymobile/theme/theme.dart';

class VentasFiltros extends StatefulWidget {
  final Function(Map<String, dynamic>) onSearch;
  final String? moduleName; // 👈 nuevo

  const VentasFiltros({super.key, required this.onSearch, this.moduleName});

  @override
  State<VentasFiltros> createState() => _VentasFiltrosState();
}

class _VentasFiltrosState extends State<VentasFiltros> {
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

    _loadLoterias();
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
                  onPressed: () {},
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
                // 🔹 MÁS FILTROS
                if (widget.moduleName == 'ventas_realizadas')
                  Expanded(
                    child: CustomButton(
                      text: 'Más filtros',
                      icon: Icons.filter_alt,
                      color: AppColors.tertiary,
                      onPressed: _openMoreFilters,
                    ),
                  ),
                // Text(
                //   'Módulo: ${widget.moduleName ?? "sin módulo"}',
                //   style: const TextStyle(
                //     fontSize: 14,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                if (widget.moduleName == 'tickets_premiados') ...[
                  const SizedBox(width: 10),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int?>(
                        value: _pagadas,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Premiados/No premiados'),
                          ),
                          DropdownMenuItem(value: 1, child: Text('Pagados')),
                          DropdownMenuItem(value: 0, child: Text('No pagados')),
                        ],
                        onChanged: (v) {
                          setState(() => _pagadas = v);
                        },
                      ),
                    ),
                  ),
                ],

                const SizedBox(width: 10),

                // 🔍 BUSCAR
                Expanded(
                  child: CustomButton(
                    text: 'Buscar',
                    icon: Icons.search,
                    color: AppColors.primary,
                    onPressed: _onSearch,
                  ),
                ),
              ],
            ),
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
    final tiposSeleccionados = _typeFilters.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (tiposSeleccionados.isNotEmpty) {
      partes.add("Tipos: ${tiposSeleccionados.join(', ')}");
    }

    // ================= LOTERÍAS (modal checkbox) =================
    final loteriasSeleccionadas = _loteriaFilters.entries
        .where((e) => e.value)
        .map((e) {
          final loteria = _loterias.firstWhere((l) => l.id == e.key);
          return loteria.nombre;
        })
        .toList();

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
      "types": _typeFilters.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      "loterias": _loteriaFilters.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
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

                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Buscar lotería...',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setModalState(() => search = value.toLowerCase());
                        },
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: _loadingLoterias
                            ? const Center(child: CircularProgressIndicator())
                            : ListView(
                                children: [
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

                                  const Text("Loterías"),

                                  ..._loterias
                                      .where(
                                        (l) => l.nombre.toLowerCase().contains(
                                          search,
                                        ),
                                      )
                                      .map((l) {
                                        return CheckboxListTile(
                                          title: Text(l.nombre),
                                          value: _loteriaFilters[l.id] ?? false,
                                          onChanged: (val) {
                                            setState(() {
                                              _loteriaFilters[l.id] =
                                                  val ?? false;
                                            });
                                            setModalState(() {});
                                          },
                                        );
                                      }),
                                ],
                              ),
                      ),

                      CustomButton(
                        text: 'Aplicar',
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
}
