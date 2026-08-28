import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loterymobile/components/custom_modal.dart';
import 'package:loterymobile/model/loteria_model.dart';
import 'package:loterymobile/model/loteriaresult_model.dart';
import 'package:loterymobile/pages/resultados/controller/resultados_controller.dart';
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
  late final ResultadosController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = ResultadosController();
    _ctrl.loadLoteries();
    AuthService.validateToken(context);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _ctrl.selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _ctrl.pickDate(picked);
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

              // 🔹 BOTÓN SELECCIONAR TODO
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final filtered = _ctrl.loteries.where((lot) {
                      final name = lot.nombre.toLowerCase();
                      final short = lot.shortName.toLowerCase();
                      return name.contains(search) || short.contains(search);
                    }).toList();

                    _ctrl.toggleSelectAll(filtered);
                    setModalState(() {});
                  },
                  child: const Text('Seleccionar todo'),
                ),
              ),

              const SizedBox(height: 8),

              // 📋 LISTA FILTRADA
              for (var lot in _ctrl.loteries.where((lot) {
                final name = lot.nombre.toLowerCase();
                final short = lot.shortName.toLowerCase();
                return name.contains(search) || short.contains(search);
              }))
                CheckboxListTile(
                  activeColor: AppColors.secondary,
                  checkColor: AppColors.primary,
                  title: Text('${lot.nombre} (${lot.shortName})'),
                  value: _ctrl.filters[lot.id] ?? false,
                  onChanged: (val) {
                    _ctrl.setFilter(lot.id, val ?? false);
                    setModalState(() {});
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
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
                        controller: _ctrl.dateController,
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
                _ctrl.isLoading
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
                          _ctrl.searchResults(
                              reload: true); // ✅ recarga los resultados
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
                    onPressed: _ctrl.searchResults,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // un pequeño espacio
            // 🔹 Label con loterías seleccionadas
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _ctrl.selectedFiltersLabel,
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
                  _ctrl.results.isNotEmpty
                      ? ListView.builder(
                          itemCount: _ctrl.results.length,
                          itemBuilder: (context, index) {
                            final result = _ctrl.results[index];
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
                                      child: (result.image != null &&
                                              result.image!.isNotEmpty)
                                          ? Builder(
                                              builder: (context) {
                                                final raw = result.image!;
                                                final isSvg =
                                                    raw.contains('svg');
                                                final bytes = base64Decode(
                                                    raw.split(',').last);

                                                return isSvg
                                                    ? SvgPicture.memory(bytes,
                                                        fit: BoxFit.cover)
                                                    : Image.memory(bytes,
                                                        fit: BoxFit.cover);
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                  Icons.image_not_supported),
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
                                      child: result.numbers != null &&
                                              result.numbers!.isNotEmpty
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: result.numbers!.map((
                                                number,
                                              ) {
                                                return Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 2,
                                                  ),
                                                  width: 28,
                                                  height: 28,
                                                  decoration:
                                                      const BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    number,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                  if (_ctrl.isLoading)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
