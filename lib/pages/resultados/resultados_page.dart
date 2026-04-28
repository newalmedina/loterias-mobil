import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:loterymobile/components/custom_modal.dart';
import 'package:loterymobile/model/loteria_model.dart';
import 'package:loterymobile/model/loteriaresult_model.dart';
import 'package:loterymobile/services/auth_service.dart';
import 'package:loterymobile/services/loteries_service.dart';
import '../../components/custom_input.dart';
import '../../components/custom_button.dart';
import '../../theme/theme.dart';
import 'package:intl/intl.dart';

class ResultadosPage extends StatefulWidget {
  // final String token;
  // const ResultadosPage({super.key, required this.token});
  const ResultadosPage({super.key});

  @override
  State<ResultadosPage> createState() => _ResultadosPageState();
}

class _ResultadosPageState extends State<ResultadosPage> {
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate = DateTime.now();
  List<Loteria> _loteries = [];
  Map<int, bool> _filters = {};
  List<LoteriaResult> _results = [];
  bool _isLoading = false; // spinner solo para resultados

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _dateController.text = DateFormat('dd-MM-yyyy').format(_selectedDate!);
    _loadLoteries();
    AuthService.validateToken(context);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _searchResults({bool reload = false}) async {
    setState(() {
      _isLoading = true; // inicio del spinner
    });

    final selectedIds = _filters.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final results = await LoteriesService.getResults(
      startDate: _selectedDate!,
      loteriesIds: selectedIds,
      reload: reload,
    );

    setState(() {
      _results = results; // directamente List<LoteriaResult>
      _isLoading = false; // fin del spinner
    });
  }

  Future<void> _loadLoteries() async {
    final lots = await LoteriesService.getLoteries();

    setState(() {
      _loteries = lots;
      _filters = {for (var l in _loteries) l.id: false};
    });
    _searchResults(reload: true); // ✅ así funciona
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _openFilterModal() {
    String search = '';

    showDialog(
      context: context,
      builder: (context) => CustomModal(
        title: 'Loterias',
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            children: [
              const SizedBox(height: 8),

              // 🔍 BUSCADOR
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

              // 🔹 BOTÓN SELECCIONAR TODO (AHORA DEBAJO DEL BUSCADOR)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final filtered = _loteries.where((lot) {
                      final name = lot.nombre.toLowerCase();
                      final short = lot.shortName.toLowerCase();
                      return name.contains(search) || short.contains(search);
                    }).toList();

                    final allSelected = filtered.every(
                      (lot) => _filters[lot.id] == true,
                    );

                    setModalState(() {
                      for (var lot in filtered) {
                        _filters[lot.id] = !allSelected;
                      }
                    });

                    setState(() {});
                  },
                  child: const Text('Seleccionar todo'),
                ),
              ),

              const SizedBox(height: 8),

              // 📋 LISTA FILTRADA
              for (var lot in _loteries.where((lot) {
                final name = lot.nombre.toLowerCase();
                final short = lot.shortName.toLowerCase();
                return name.contains(search) || short.contains(search);
              }))
                CheckboxListTile(
                  activeColor: AppColors.secondary,
                  checkColor: AppColors.primary,
                  title: Text('${lot.nombre} (${lot.shortName})'),
                  value: _filters[lot.id] ?? false,
                  onChanged: (val) {
                    setModalState(() {
                      _filters[lot.id] = val ?? false;
                    });
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String get _selectedFiltersLabel {
    final selected = _loteries.where((l) => _filters[l.id] == true);
    if (selected.isEmpty) return '';
    return 'Seleccionadas: ${selected.map((l) => l.shortName).join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Consultar Premios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: CustomInput(
                    controller: _dateController,
                    label: 'Selecciona fecha',
                    isPassword: false,
                    canVisible: false,
                    prefixIcon: Icons.calendar_month,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 🔹 Botón de sincronizar
            _isLoading
                ? SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.0,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.sync,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    onPressed: () {
                      _searchResults(reload: true); // ✅ recarga los resultados
                    },
                  ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Loterias',
                icon: Icons.filter_alt,
                color: AppColors.tertiary,
                onPressed: _openFilterModal,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Buscar',
                icon: Icons.search,
                color: AppColors.primary,
                onPressed: _searchResults,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8), // un pequeño espacio
        // 🔹 Label con loterías seleccionadas
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _selectedFiltersLabel,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.quaternary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Stack(
            children: [
              _results.isNotEmpty
                  ? ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final result = _results[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // 1️⃣ Imagen con loader
                                Container(
                                  width: 50,
                                  height: 50,
                                  margin: const EdgeInsets.only(right: 12),
                                  child:
                                      (result.image != null &&
                                          result.image!.isNotEmpty)
                                      ? FutureBuilder<Uint8List>(
                                          future: Future(
                                            () => base64Decode(
                                              result.image!.split(',').last,
                                            ),
                                          ),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            } else if (snapshot.hasError ||
                                                !snapshot.hasData) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                ),
                                              );
                                            } else {
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                          },
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image_not_supported,
                                          ),
                                        ),
                                ),

                                // 2️⃣ Nombre (completeName)
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    result.shortName ?? 'Sin nombre',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),

                                // 3️⃣ Números en bolas verdes
                                Expanded(
                                  flex: 2,
                                  child:
                                      result.numbers != null &&
                                          result.numbers!.isNotEmpty
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: result.numbers!.map((
                                            number,
                                          ) {
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 2,
                                                  ),
                                              width: 28,
                                              height: 28,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                number,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      : const Text(
                                          'Sin números',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('No hay resultados')),

              // Spinner general de resultados
              if (_isLoading)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ],
    );

    // return BasePage(
    //   child: Padding(padding: const EdgeInsets.all(24), child: content),
    // );
  }
}
