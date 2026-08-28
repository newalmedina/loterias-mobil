import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loterymobile/components/custom_checkbox.dart';
import 'package:loterymobile/components/custom_modal.dart';
import 'package:loterymobile/model/loteria_model.dart';
import 'package:loterymobile/model/venta_model.dart';
import 'package:loterymobile/pages/ventas/controller/ventas_controller.dart';
import 'package:loterymobile/partials/detalles_agrupados_list.dart';
import 'package:loterymobile/services/auth_service.dart';
import 'package:loterymobile/theme/theme.dart';
import 'package:loterymobile/widgets/snackbar_helper.dart';
import '../../components/custom_button.dart';
import '../../components/custom_input.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  late final VentasController _ctrl;
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _numberFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = VentasController();
    _ctrl.loadLoteries();
    AuthService.validateToken(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _numberFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _numberController.dispose();
    _amountController.dispose();
    _numberFocus.dispose();
    _amountFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Foco / Errores ────────────────────────────────────────
  void _recoverFocus() {
    if (_numberController.text.isEmpty) {
      _numberFocus.requestFocus();
    } else {
      _amountFocus.requestFocus();
    }
  }

  void _showError(String message) {
    SnackbarHelper.show(
      context,
      message: message,
      backgroundColor: AppColors.danger,
      duration: const Duration(seconds: 2),
    );
  }

  // ─── Añadir jugada ─────────────────────────────────────────
  void _addLotery([String tipo = "Qui"]) {
    final error = _ctrl.addLotery(
      _numberController.text.trim(),
      _amountController.text.trim(),
      tipo,
    );
    if (error != null) {
      _showError(error);
      WidgetsBinding.instance.addPostFrameCallback((_) => _recoverFocus());
      return;
    }
    if (tipo != "SPal") {
      _numberController.clear();
      if (!_ctrl.keepAmount) _amountController.clear();
    }
    _numberFocus.requestFocus();
  }

  // ─── Modales ───────────────────────────────────────────────
  void _openLoteriaModal() {
    String search = '';
    showDialog(
      context: context,
      builder: (context) => CustomModal(
        title: 'Selecciona Loterías',
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar lotería...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) =>
                    setModalState(() => search = value.toLowerCase()),
              ),
              const SizedBox(height: 10),
              if (_ctrl.loteries.isNotEmpty)
                ..._ctrl.loteries
                    .where((lot) {
                      final name = lot.nombre.toLowerCase();
                      final short = lot.shortName.toLowerCase();
                      return name.contains(search) || short.contains(search);
                    })
                    .map((lot) => CheckboxListTile(
                          activeColor: AppColors.secondary,
                          checkColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${lot.nombre} (${lot.shortName})'),
                          value: _ctrl.quinielasSelected[lot.id] ?? false,
                          onChanged: (val) {
                            setModalState(() {
                              _ctrl.quinielasSelected[lot.id] = val ?? false;
                            });
                          },
                        ))
                    .toList()
              else
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'No hay loterías disponibles',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverFocus());
  }

  void _openSuperPaleModal() {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: Column(
              children: [
                const Text('Selecciona las loterías S. Pal',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar lotería...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) =>
                      setModalState(() => search = value.toLowerCase()),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _ctrl.loteries.isNotEmpty
                      ? ListView(
                          children: _ctrl.loteries
                              .asMap()
                              .entries
                              .where((entry) {
                                final name = entry.value.nombre.toLowerCase();
                                final short =
                                    entry.value.shortName.toLowerCase();
                                return name.contains(search) ||
                                    short.contains(search);
                              })
                              .map((entry) => CheckboxListTile(
                                    activeColor: AppColors.secondary,
                                    checkColor: AppColors.primary,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(entry.value.shortName),
                                    value: _ctrl.supPaleSelected[entry.key] ??
                                        false,
                                    onChanged: (value) => setModalState(() {
                                      _ctrl.supPaleSelected[entry.key] =
                                          value ?? false;
                                    }),
                                  ))
                              .toList(),
                        )
                      : const Center(
                          child: Text('No hay loterías disponibles',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic)),
                        ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed:
                      _ctrl.supPaleSelected.values.where((v) => v).length == 2
                          ? () {
                              _addLotery('SPal');
                              Navigator.pop(context);
                            }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Añadir',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverFocus());
  }

  void _combJugadsModal() {
    bool combinarPal = false;
    bool combinarTri = false;
    final montoController = TextEditingController();
    final montoFocus = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            montoController.addListener(() => setModalState(() {}));
            bool isButtonEnabled() {
              final monto = double.tryParse(montoController.text.trim()) ?? 0;
              return monto > 0 && (combinarPal || combinarTri);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Combinación de Loterías',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Combinar Pale'),
                  value: combinarPal,
                  onChanged: (val) =>
                      setModalState(() => combinarPal = val ?? false),
                  activeColor: AppColors.secondary,
                  checkColor: AppColors.primary,
                ),
                CheckboxListTile(
                  title: const Text('Combinar Tripleta'),
                  value: combinarTri,
                  onChanged: (val) =>
                      setModalState(() => combinarTri = val ?? false),
                  activeColor: AppColors.secondary,
                  checkColor: AppColors.primary,
                ),
                const SizedBox(height: 8),
                Text('Solo se combinan quinielas o números sueltos',
                    style: TextStyle(
                        color: Colors.grey[600], fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                CustomInput(
                  controller: montoController,
                  label: 'Monto',
                  keyboardType: TextInputType.number,
                  focusNode: montoFocus,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: isButtonEnabled()
                        ? () {
                            _ctrl.procesarCombinacion(
                              combinarPal: combinarPal,
                              combinarTri: combinarTri,
                              monto: double.parse(montoController.text.trim()),
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Añadir',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _recoverFocus());
  }

  void _openEditDetalleModal(VentaDetalle detalle) {
    final numeroController =
        TextEditingController(text: detalle.numberFormated);
    final montoController =
        TextEditingController(text: detalle.monto?.toStringAsFixed(0) ?? '0');
    final numeroFocus = FocusNode();
    final montoFocus = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => numeroFocus.requestFocus());
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Editar detalle de ${detalle.loteriaSlug}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                CustomInput(
                  controller: numeroController,
                  label: 'Número',
                  keyboardType: TextInputType.number,
                  focusNode: numeroFocus,
                  textInputAction: TextInputAction.next,
                  enabled: false,
                  onSubmitted: (_) => montoFocus.requestFocus(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 12),
                CustomInput(
                  controller: montoController,
                  label: 'Monto',
                  keyboardType: TextInputType.number,
                  focusNode: montoFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    final error = _ctrl.updateDetalle(
                      detalle,
                      double.tryParse(montoController.text) ?? 0,
                    );
                    if (error != null) {
                      _showError(error);
                      return;
                    }
                    Navigator.pop(context);
                    _numberFocus.requestFocus();
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Guardar',
                    icon: Icons.save,
                    color: AppColors.primary,
                    onPressed: () {
                      final error = _ctrl.updateDetalle(
                        detalle,
                        double.tryParse(montoController.text) ?? 0,
                      );
                      if (error != null) {
                        _showError(error);
                        return;
                      }
                      Navigator.pop(context);
                      _numberFocus.requestFocus();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Eliminar',
                    icon: Icons.delete,
                    color: Colors.red,
                    onPressed: () {
                      _ctrl.eliminarDetalle(detalle);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Cancelar',
                    icon: Icons.cancel,
                    color: Colors.grey,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editarSeleccionados() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar monto"),
        content: CustomInput(
          controller: controller,
          label: "Nuevo monto",
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              _ctrl.editarMontoSeleccionados(
                  double.tryParse(controller.text) ?? 0);
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar"),
        content: const Text(
            "¿Seguro que quieres eliminar los elementos seleccionados?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              _ctrl.eliminarSeleccionados();
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  void _openFinalizarModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Finalizar Jugada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 20),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Antes de finalizar, verifica cuidadosamente los tickets para evitar errores.',
                    style: TextStyle(fontSize: 14, color: AppColors.danger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.primary),
              title: const Text('Imprimir'),
              onTap: () {
                Navigator.pop(context);
                _finalizarJugada('imprimir');
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: AppColors.primary),
              title: const Text('Imprimir y Compartir'),
              onTap: () {
                Navigator.pop(context);
                _finalizarJugada('imprimir-compartir');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.save, color: Colors.green),
              title: const Text('Guardar'),
              onTap: () {
                Navigator.pop(context);
                _finalizarJugada('guardar');
              },
            ),
            ListTile(
              leading: const Icon(Icons.save, color: Colors.green),
              title: const Text('Guardar y Compartir'),
              onTap: () {
                Navigator.pop(context);
                _finalizarJugada('compartir');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _finalizarJugada(String action) async {
    final response = await _ctrl.finalizarVenta();
    if (response.success) {
      SnackbarHelper.show(
        context,
        message: response.message.isNotEmpty
            ? response.message
            : "Venta realizada correctamente",
        backgroundColor: AppColors.success,
      );
    } else {
      SnackbarHelper.show(context,
          message: "Se encontraron errores", backgroundColor: AppColors.danger);
    }
  }

  // ─── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.point_of_sale, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Ventas',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 10),

              ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.tune),
                title: const Text('Jugadas'),
                children: [
                  // Errores
                  if (_ctrl.errores.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(top: 10, right: 8, left: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _ctrl.errores
                                  .map((e) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text('• $e',
                                            style: const TextStyle(
                                                color: Colors.red)),
                                      ))
                                  .toList(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: _ctrl.clearErrores,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Botones tipo
                  Row(
                    children: [
                      Expanded(
                          child: CustomButton(
                              text: 'Qui.',
                              color: AppColors.primary,
                              onPressed: _openLoteriaModal)),
                      const SizedBox(width: 4),
                      Expanded(
                          child: CustomButton(
                              text: 'S. Pal',
                              color: AppColors.secondary,
                              onPressed: _openSuperPaleModal)),
                      const SizedBox(width: 4),
                      Expanded(
                          child: CustomButton(
                              text: 'Comb.',
                              color: AppColors.tertiary,
                              onPressed: _combJugadsModal)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_ctrl.selectedLoteriasLabel,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.quaternary)),
                  ),

                  const SizedBox(height: 16),

                  // Inputs
                  Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: Row(
                          children: [
                            Expanded(
                              child: CustomInput(
                                controller: _numberController,
                                label: 'Número',
                                keyboardType: TextInputType.number,
                                focusNode: _numberFocus,
                                textInputAction: _amountController.text.isEmpty
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onSubmitted: (_) {
                                  if (_amountController.text.isEmpty) {
                                    _amountFocus.requestFocus();
                                  } else {
                                    _addLotery();
                                    _recoverFocus();
                                  }
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomInput(
                                controller: _amountController,
                                label: 'Monto',
                                keyboardType: TextInputType.number,
                                focusNode: _amountFocus,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _addLotery(),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 30,
                        child: Align(
                          alignment: Alignment.center,
                          child: CustomCheckbox(
                            value: _ctrl.keepAmount,
                            onChanged: (_) => _ctrl.toggleKeepAmount(),
                            size: 22,
                            borderColor: AppColors.primary,
                            activeColor: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Total
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: \$${_ctrl.calcularTotal().toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),

              const SizedBox(height: 8),

              // Botones editar/eliminar seleccionados
              if (_ctrl.seleccionados.isNotEmpty)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _editarSeleccionados,
                      icon: const Icon(Icons.edit),
                      label: const Text("Editar"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: _confirmarEliminar,
                      icon: const Icon(Icons.delete),
                      label: const Text("Eliminar"),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Seleccionar todos
              Row(
                children: [
                  Checkbox(
                    value: (_ctrl.venta?.detalles?.isNotEmpty ?? false) &&
                        _ctrl.seleccionados.length ==
                            (_ctrl.venta?.detalles?.length ?? 0),
                    activeColor: AppColors.primary,
                    onChanged: _ctrl.venta?.detalles == null
                        ? null
                        : (_) => _ctrl.toggleSelectAll(),
                  ),
                  const SizedBox(width: 8),
                  const Text("Seleccionar todos"),
                ],
              ),

              const SizedBox(height: 8),

              // Lista
              Expanded(
                child: _ctrl.venta == null || _ctrl.venta!.detalles!.isEmpty
                    ? const Center(
                        child: Text('Aquí se mostrarán los tickets agregados',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      )
                    : DetallesAgrupadosList(
                        detalles: _ctrl.venta!.detalles!,
                        seleccionados: _ctrl.seleccionados,
                        onToggleSeleccion: _ctrl.toggleSeleccion,
                        onTapDetalle: _openEditDetalleModal,
                      ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomButton(
                      text: '+',
                      color: AppColors.quaternary,
                      isCircular: true,
                      onPressed: _addLotery,
                    ),
                    const SizedBox(width: 56),
                    if (_ctrl.venta != null &&
                        _ctrl.venta!.detalles!.isNotEmpty)
                      InkWell(
                        onTap: _openFinalizarModal,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.print, color: Colors.white),
                        ),
                      )
                    else
                      const SizedBox(width: 56),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
