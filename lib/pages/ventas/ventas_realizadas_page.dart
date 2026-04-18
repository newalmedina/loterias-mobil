import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:loterymobile/components/custom_date_input.dart';
import 'package:loterymobile/services/ventas_service.dart';

import '../../components/custom_input.dart';
import '../../components/custom_button.dart';
import '../../model/loteria_model.dart';
import '../../services/loteries_service.dart';
import '../../theme/theme.dart';

class VentasRealizadasPage extends StatefulWidget {
  const VentasRealizadasPage({super.key});

  @override
  State<VentasRealizadasPage> createState() => _VentasRealizadasPageState();
}

class _VentasRealizadasPageState extends State<VentasRealizadasPage> {
  bool detalleVenta = false;

  final TextEditingController _ticketController = TextEditingController();
  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();
  List<dynamic> _ventas = [];

  bool _isLoading = false;
  int? _estadoVenta;
  int? _pagadas;
  Map<String, dynamic>? selectedVenta;
  Map<String, bool> _typeFilters = {
    'Qui': false,
    'Pal': false,
    'SPal': false,
    'Tri': false,
  };

  List<Loteria> _loterias = [];
  Map<int, bool> _loteriaFilters = {};

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final formatted = DateFormat('dd-MM-yyyy').format(today);

    _fechaInicioController.text = formatted;
    _fechaFinController.text = formatted;
    _loadLoterias();
    _searchVentas();
  }

  Future<void> _loadLoterias() async {
    final data = await LoteriesService.getLoteries();

    setState(() {
      _loterias = data;
      _loteriaFilters = {for (var l in data) l.id: false};
    });
  }

  @override
  void dispose() {
    _ticketController.dispose();
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }

  // =========================
  // 🔥 SEARCH EVENT
  Future<void> _searchVentas({bool reload = false}) async {
    setState(() {
      _isLoading = true;
    });

    final selectedLoterias = _loteriaFilters.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final selectedTypes = _typeFilters.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    // 🔥 FECHAS REALES DEL INPUT
    final startDate = _fechaInicioController.text.isNotEmpty
        ? _parseDate(_fechaInicioController.text)
        : null;

    final endDate = _fechaFinController.text.isNotEmpty
        ? _parseDate(_fechaFinController.text)
        : null;

    final results = await VentasService.getVentas(
      startDate: startDate,
      endDate: endDate,
      loteriaIds: selectedLoterias,
      code: _ticketController.text,
      type: selectedTypes,
      pagado: _pagadas,
      premiado: _estadoVenta,
    );

    setState(() {
      _ventas = results;
      _isLoading = false;
    });
  }

  // =========================
  // MODAL
  // =========================
  void _openMoreFilters() {
    String search = '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.75,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
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
                          setModalState(() {
                            search = value.toLowerCase();
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estado de venta'),
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
                                onChanged: (value) {
                                  setModalState(() => _estadoVenta = value);
                                  setState(() {});
                                },
                              ),

                              const SizedBox(height: 10),

                              const Text('Estado de pago'),
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
                                onChanged: (value) {
                                  setModalState(() => _pagadas = value);
                                  setState(() {});
                                },
                              ),

                              const SizedBox(height: 10),

                              const Text('Tipo'),
                              ..._typeFilters.keys.map((key) {
                                return CheckboxListTile(
                                  title: Text(key),
                                  value: _typeFilters[key],
                                  onChanged: (val) {
                                    setModalState(() {
                                      _typeFilters[key] = val ?? false;
                                    });
                                    setState(() {});
                                  },
                                );
                              }),

                              const Divider(),

                              const Text('Loterías'),

                              ..._loterias
                                  .where((l) {
                                    return l.nombre.toLowerCase().contains(
                                      search,
                                    );
                                  })
                                  .map((l) {
                                    return CheckboxListTile(
                                      title: Text(l.nombre),
                                      value: _loteriaFilters[l.id] ?? false,
                                      onChanged: (val) {
                                        setModalState(() {
                                          _loteriaFilters[l.id] = val ?? false;
                                        });
                                        setState(() {});
                                      },
                                    );
                                  }),
                            ],
                          ),
                        ),
                      ),

                      CustomButton(
                        text: 'Aplicar filtros',
                        icon: Icons.check,
                        color: AppColors.primary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // =========================
  // LABEL (NOMBRES REALES)
  // =========================
  String get _filtersLabel {
    final parts = <String>[];

    if (_estadoVenta != null) {
      parts.add(_estadoVenta == 1 ? 'Premiados' : 'No premiados');
    }

    if (_pagadas != null) {
      parts.add(_pagadas == 1 ? 'Pagados' : 'No pagados');
    }

    final tipos = _typeFilters.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (tipos.isNotEmpty) {
      parts.add('Tipo: ${tipos.join(", ")}');
    }

    final loteriasSeleccionadas = _loteriaFilters.entries
        .where((e) => e.value)
        .map((e) {
          final l = _loterias.firstWhere(
            (lot) => lot.id == e.key,
            orElse: () =>
                Loteria(id: e.key, nombre: 'Lotería ${e.key}', shortName: ''),
          );

          return l.shortName.isNotEmpty ? l.shortName : l.nombre;
        })
        .toList();

    if (loteriasSeleccionadas.isNotEmpty) {
      parts.add('Loterías: ${loteriasSeleccionadas.join(", ")}');
    }

    return parts.isEmpty ? '' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("orden"),
                  Switch(
                    value: detalleVenta,
                    onChanged: (val) {
                      setState(() {
                        detalleVenta = val;
                      });
                    },
                  ),
                  const Text("Detalle"),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 9, // 🔥 90%
                    child: CustomInput(
                      controller: _ticketController,
                      label: 'Número de ticket',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.confirmation_number,
                    ),
                  ),

                  const SizedBox(width: 4), // menos espacio

                  Expanded(
                    flex: 1,
                    child: Center(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // TODO: abrir escáner QR
                        },
                        child: Container(
                          width: 44, // 🔥 más ancho
                          height: 44, // 🔥 más alto (cuadrado bonito)
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  Widget inicio = CustomDateInput(
                    controller: _fechaInicioController,
                    label: 'F. Inicial',
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );

                  Widget fin = CustomDateInput(
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

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Mas filtros',
                      icon: Icons.filter_alt,
                      color: AppColors.tertiary,
                      onPressed: _openMoreFilters,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Buscar',
                      icon: Icons.search,
                      color: AppColors.primary,
                      onPressed: _searchVentas,
                    ),
                  ),
                ],
              ),

              if (_filtersLabel.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _filtersLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 10),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ventas.length,
                      itemBuilder: (context, index) {
                        final v = _ventas[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ================= SIMPLE MODE =================
                                if (!detalleVenta)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("Orden: ${v['code']}"),
                                            Text("Fecha: ${v['date']}"),
                                            Text("Total: ${v['total_neto']}"),
                                          ],
                                        ),
                                      ),

                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_forward_ios,
                                        ),
                                        onPressed: () {
                                          _openVenta(v);
                                        },
                                      ),
                                    ],
                                  ),

                                // ================= DETAIL MODE =================
                                if (detalleVenta)
                                  Column(
                                    children: [
                                      ...List.generate(v['details'].length, (
                                        i,
                                      ) {
                                        final d = v['details'][i];

                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.black12,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "${d['loterie_nombre']} - ${d['number']} (${d['type']})",
                                                    ),
                                                    Text(
                                                      "Monto: ${d['monto_jugada']}",
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              Row(
                                                children: [
                                                  if (d['premiado'] == 1)
                                                    const Icon(
                                                      Icons.emoji_events,
                                                      color: Colors.amber,
                                                    ),

                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.arrow_forward,
                                                    ),
                                                    onPressed: () {
                                                      _openVenta(v);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  void _openVenta(Map<String, dynamic> venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // ================= HEADER =================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Orden ${venta['code']}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // ================= BODY =================
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Fecha: ${venta['date']}"),
                        Text("Total neto: ${venta['total_neto']}"),
                        Text("Total premiado: ${venta['total_premiado']}"),

                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),

                        ...List.generate(venta['details'].length, (i) {
                          final d = venta['details'][i];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${d['loterie_nombre']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text("${d['number']} - ${d['type']}"),
                                      Text("Monto: ${d['monto_jugada']}"),
                                    ],
                                  ),
                                ),

                                if (d['premiado'] == 1)
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // ================= FOOTER (IMPRIMIR) =================
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.3),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Imprimir',
                      icon: Icons.print,
                      color: AppColors
                          .primary, // o Colors.black si lo quieres neutro
                      onPressed: () {
                        _printVenta(venta);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _printVenta(Map<String, dynamic> venta) {}

  DateTime _parseDate(String text) {
    try {
      return DateFormat('dd-MM-yyyy').parse(text);
    } catch (e) {
      return DateTime.now();
    }
  }
}
