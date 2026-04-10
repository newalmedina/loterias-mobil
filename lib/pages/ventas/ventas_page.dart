import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loterymobile/components/custom_checkbox.dart';
import 'package:loterymobile/components/custom_modal.dart';
import 'package:loterymobile/model/loteria_model.dart';
import 'package:loterymobile/model/venta_model.dart';
import 'package:loterymobile/partials/detalles_agrupados_list.dart';
import 'package:loterymobile/services/auth_service.dart';
import 'package:loterymobile/services/loteries_service.dart';
import 'package:loterymobile/services/ventas_service.dart';
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
  List<Loteria> _loteries = [];
  Set<VentaDetalle> _seleccionados = {};
  Map<int, bool> _quinielasSelected = {};
  final Map<int, bool> _supPaleSelected =
      {}; // índice de la lotería → si está seleccionada
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _numberFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  Venta? _venta; // Variable para almacenar la venta actual
  bool _keepAmount = false;
  List<String> tiposOrdenados = ['Tri', 'SPal', 'Pal', 'Qui'];

  @override
  void initState() {
    super.initState();
    _loadLoteries();
    AuthService.validateToken(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _numberFocus.requestFocus();
    });
  }

  Future<void> _loadLoteries() async {
    final lots = await LoteriesService.getloteriesDisponibles();
    // print(lots);
    setState(() {
      _loteries = lots;
      _quinielasSelected = {for (var l in _loteries) l.id: false};
    });
  }

  void _openLoteriaModal() {
    showDialog(
      context: context,
      builder: (context) => CustomModal(
        title: 'Selecciona Loterías',
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _loteries.isNotEmpty
                ? [
                    for (var lot in _loteries)
                      CheckboxListTile(
                        activeColor: AppColors
                            .secondary, // color del check al seleccionar
                        checkColor: AppColors.primary, // color de la marca ✓
                        contentPadding: EdgeInsets.zero, // ajusta margen
                        title: Text('${lot.nombre} (${lot.shortName})'),
                        value: _quinielasSelected[lot.id] ?? false,
                        onChanged: (val) {
                          setModalState(() {
                            _quinielasSelected[lot.id] = val ?? false;
                          });
                          setState(() {}); // actualizar label al instante
                        },
                      ),
                  ]
                : [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'No hay loterías disponibles',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
    // 👇 AQUÍ se recupera el foco después de cerrar el modal
    // _recoverFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverFocus();
    });
  }

  void _combJugadsModal() {
    bool combinarPal = false;
    bool combinarTri = false;
    TextEditingController montoController = TextEditingController();
    FocusNode montoFocus = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // se ajusta al teclado
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              // 🔹 Escuchar cambios para habilitar/deshabilitar botón
              montoController.addListener(() {
                setModalState(() {});
              });

              bool isButtonEnabled() {
                final monto = double.tryParse(montoController.text.trim()) ?? 0;
                return monto > 0 && (combinarPal || combinarTri);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Combinación de Loterías',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),

                  CheckboxListTile(
                    title: Text('Combinar Pale'),
                    value: combinarPal,
                    onChanged: (val) {
                      setModalState(() {
                        combinarPal = val ?? false;
                      });
                    },
                    activeColor: AppColors.secondary,
                    checkColor: AppColors.primary,
                  ),

                  CheckboxListTile(
                    title: Text('Combinar Tripleta'),
                    value: combinarTri,
                    onChanged: (val) {
                      setModalState(() {
                        combinarTri = val ?? false;
                      });
                    },
                    activeColor: AppColors.secondary,
                    checkColor: AppColors.primary,
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Solo se combinan quinielas o números sueltos',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  SizedBox(height: 12),

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

                  SizedBox(height: 12),

                  Center(
                    child: ElevatedButton(
                      onPressed: isButtonEnabled()
                          ? () {
                              final monto = double.parse(
                                montoController.text.trim(),
                              );

                              _procesarCombinacion(
                                combinarPal: combinarPal,
                                combinarTri: combinarTri,
                                monto: monto,
                              );

                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Añadir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedLoterias = _loteries
        .where((l) => _quinielasSelected[l.id] == true)
        .map((l) => l.shortName)
        .join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Row botones
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Qui.',
                  color: AppColors.primary,
                  onPressed: _openLoteriaModal,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CustomButton(
                  text: 'S. Pal',
                  color: AppColors.secondary,
                  onPressed: _openPModal,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CustomButton(
                  text: 'Comb. Jugadas',
                  color: AppColors.tertiary,
                  onPressed: _combJugadsModal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Loterías seleccionadas
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              selectedLoterias.isNotEmpty
                  ? 'Seleccionadas: $selectedLoterias'
                  : 'No hay loterías seleccionadas',
              style: const TextStyle(fontSize: 14, color: AppColors.quaternary),
            ),
          ),

          const SizedBox(height: 16),

          // Inputs
          Row(
            children: [
              Expanded(
                flex: 9,
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: CustomInput(
                        controller: _numberController,
                        label: 'Número',
                        keyboardType: TextInputType.number,
                        focusNode: _numberFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) {
                          _amountFocus.requestFocus();
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: CustomInput(
                        controller: _amountController,
                        label: 'Monto',
                        keyboardType: TextInputType.number,
                        focusNode: _amountFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          _addLotery();
                        },
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

              // Checkbox
              SizedBox(
                width: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomCheckbox(
                    value: _keepAmount,
                    onChanged: (val) {
                      setState(() {
                        _keepAmount = val ?? false;
                      });
                    },
                    size: 30,
                    borderColor: AppColors.primary,
                    activeColor: AppColors.secondary,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Botón +
              SizedBox(
                width: 50,
                height: 50,
                child: Center(
                  child: CustomButton(
                    text: '+',
                    color: AppColors.quaternary,
                    isCircular: true,
                    onPressed: _addLotery,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: \$${_calcularTotal().toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // BOTONES SELECCIÓN
          if (_seleccionados.isNotEmpty)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _editarSeleccionados,
                  icon: const Icon(Icons.edit),
                  label: const Text("Editar"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _confirmarEliminar,
                  icon: const Icon(Icons.delete),
                  label: const Text("Eliminar"),
                ),
              ],
            ),

          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value:
                    (_venta?.detalles?.isNotEmpty ?? false) &&
                    _seleccionados.length == (_venta?.detalles?.length ?? 0),
                activeColor: AppColors.primary,
                onChanged: (_venta?.detalles == null)
                    ? null
                    : (value) {
                        setState(() {
                          final detalles = _venta?.detalles ?? [];

                          if (value == true) {
                            _seleccionados = detalles.toSet();
                          } else {
                            _seleccionados.clear();
                          }
                        });
                      },
              ),

              const SizedBox(width: 8),

              const Text("Seleccionar todos"),
            ],
          ),
          const SizedBox(height: 8),

          // LISTA
          Expanded(
            child: _venta == null || _venta!.detalles!.isEmpty
                ? const Center(
                    child: Text(
                      'Aquí se mostrarán los tickets agregados',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : DetallesAgrupadosList(
                    detalles: _venta!.detalles!,
                    seleccionados: _seleccionados,
                    onToggleSeleccion: _toggleSeleccion,
                    onTapDetalle: (detalle) {
                      _openEditDetalleModal(detalle);
                    },
                  ),
          ),

          // FOOTER
          if (_venta != null && _venta!.detalles!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _openFinalizarModal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Finalizar Jugada',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openEditDetalleModal(VentaDetalle detalle) {
    print(detalle.numberFormated);
    final TextEditingController numeroController = TextEditingController(
      text: detalle.numberFormated,
    );
    final TextEditingController montoController = TextEditingController(
      text: detalle.monto?.toStringAsFixed(0) ?? '0',
    );

    // ✅ FocusNodes específicos del modal
    final FocusNode numeroFocus = FocusNode();
    final FocusNode montoFocus = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          numeroFocus.requestFocus();
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editar detalle de ${detalle.loteriaSlug}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Número
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

                // Monto
                CustomInput(
                  controller: montoController,
                  label: 'Monto',
                  keyboardType: TextInputType.number,
                  focusNode: montoFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _updateDetalle(
                    detalle,
                    numeroController,
                    montoController,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),

                const SizedBox(height: 20),

                // 🔥 BOTÓN GUARDAR
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Guardar',
                    icon: Icons.save,
                    color: AppColors.primary,
                    onPressed: () => _updateDetalle(
                      detalle,
                      numeroController,
                      montoController,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 🔥 BOTÓN ELIMINAR
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: 'Eliminar',
                    icon: Icons.delete,
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _venta!.detalles!.remove(detalle);
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // 🔥 BOTÓN CANCELAR
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

  void _openPModal() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selecciona las loterías S. Pal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // Verificamos si hay loterías
                  if (_loteries.isNotEmpty)
                    ..._loteries.asMap().entries.map((entry) {
                      int index = entry.key;
                      Loteria lottery = entry.value;
                      return CheckboxListTile(
                        title: Text(
                          lottery.shortName,
                        ), // ajusta según tu modelo
                        value: _supPaleSelected[index] ?? false,
                        onChanged: (value) {
                          setModalState(() {
                            _supPaleSelected[index] = value ?? false;
                          });
                        },
                      );
                    })
                  else
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'No hay loterías disponibles',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                  SizedBox(height: 10),

                  Center(
                    child: ElevatedButton(
                      onPressed:
                          _supPaleSelected.values.where((v) => v).length == 2
                          ? () {
                              _addLotery('SPal');
                              Navigator.pop(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // ✅ fondo verde
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Añadir',
                        style: TextStyle(
                          color: Colors.white, // ✅ texto blanco
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addLotery([String tipo = "Qui"]) {
    final number = _numberController.text.trim();
    final amount = _amountController.text.trim();

    final error = _validateInputs(number, amount, tipo);
    if (error != null) {
      _showError(error);
      WidgetsBinding.instance.addPostFrameCallback((_) => _recoverFocus());
      return;
    }

    final monto = double.tryParse(amount) ?? 0;

    // Crear venta si no existe
    _venta ??= Venta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: 'V-${DateTime.now().millisecondsSinceEpoch}',
      fecha: DateTime.now(),
      detalles: [],
    );

    // Determinar tipo final según longitud del número
    String tipoFinal = tipo;
    if (tipo == "Qui") {
      if (number.length == 4) tipoFinal = "Pal";
      if (number.length == 6) tipoFinal = "Tri";
    }

    // Separar número en pares y ordenar de mayor a menor
    String numerosOrdenados = _ordenarNumeroEnPares(number);

    // Seleccionar loterías según tipo
    Iterable<Loteria> selectedLotery;
    if (tipo == "SPal") {
      tipoFinal = tipo;

      // Obtener las loterías seleccionadas
      final selectedLoteryList = _loteries
          .asMap()
          .entries
          .where((e) => _supPaleSelected[e.key] == true)
          .map((e) => e.value)
          .toList();

      if (selectedLoteryList.isEmpty) {
        // No hay loterías seleccionadas, salir o mostrar mensaje
        _showError("No hay loterías disponibles");
        return;
      }

      // Capturar IDs de las loterías seleccionadas
      final loteriaId = selectedLoteryList[0].id;
      final loteriaSecondId = selectedLoteryList.length > 1
          ? selectedLoteryList[1].id
          : null;

      // Crear un slug combinado
      final provisionalName = selectedLoteryList
          .map((l) => l.shortName)
          .join('-');

      // Agregar o actualizar el detalle
      _addOrUpdateDetalle(
        numero: numerosOrdenados,
        monto: monto,
        tipo: tipoFinal,
        loteriaId: loteriaId,
        loteriaSecondId: loteriaSecondId,
        loteriaSlug: provisionalName,
      );
    } else {
      selectedLotery = _loteries.where((l) => _quinielasSelected[l.id] == true);

      for (var lot in selectedLotery) {
        _addOrUpdateDetalle(
          numero: numerosOrdenados,
          monto: monto,
          tipo: tipoFinal,
          loteriaId: lot.id,
          loteriaSecondId: null,
          loteriaSlug: lot.shortName,
        );
      }
    }

    setState(() {});

    // Limpieza
    if (tipo != "SPal") {
      _numberController.clear();
      if (!_keepAmount) _amountController.clear();
    }

    _numberFocus.requestFocus();
  }

  /// Separa el número en pares, los ordena y devuelve concatenado
  String _ordenarNumeroEnPares(String number) {
    List<String> pares = [];
    for (int i = 0; i < number.length; i += 2) {
      pares.add(
        i + 2 <= number.length
            ? number.substring(i, i + 2)
            : number.substring(i),
      );
    }
    pares.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
    return pares.join();
  }

  /// Agrega o actualiza un detalle en la venta
  void _addOrUpdateDetalle({
    required String numero,
    required double monto,
    required String tipo,
    required int loteriaId,
    int? loteriaSecondId,
    required String loteriaSlug,
  }) {
    // Buscar detalle duplicado considerando ambas loterías
    final index = _venta!.detalles!.indexWhere(
      (d) =>
          d.numero == numero &&
          d.tipo == tipo &&
          d.loteriaId == loteriaId &&
          d.loteriaSecondId == loteriaSecondId,
    );

    if (index != -1) {
      // Si existe, sumamos el monto
      _venta!.detalles![index].monto =
          (_venta!.detalles![index].monto ?? 0) + monto;
    } else {
      // Si no existe, agregamos uno nuevo
      _venta!.detalles!.add(
        VentaDetalle(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          numero: numero,
          monto: monto,
          tipo: tipo,
          loteriaId: loteriaId,
          loteriaSecondId: loteriaSecondId,
          loteriaSlug: loteriaSlug,
        ),
      );
    }
  }

  void _updateDetalle(
    VentaDetalle detalle,
    TextEditingController numeroController,
    TextEditingController montoController,
  ) {
    final nuevoNumero = numeroController.text.trim();
    final nuevoMonto = double.tryParse(montoController.text) ?? 0;

    // Validaciones
    if (nuevoNumero.isEmpty) {
      _showError('El número no puede estar vacío');
      return;
    }
    // if (!(nuevoNumero.length == 2 ||
    //     nuevoNumero.length == 4 ||
    //     nuevoNumero.length == 6)) {
    //   _showError('El número debe tener 2, 4 o 6 dígitos');
    //   return;
    // }
    if (montoController.text.isEmpty || nuevoMonto <= 0) {
      _showError('El monto debe ser mayor a 0');
      return;
    }

    // Actualizar detalle
    setState(() {
      // detalle.numero = nuevoNumero;
      detalle.monto = nuevoMonto;
    });

    Navigator.pop(context);
    _numberFocus.requestFocus();
  }

  String? _validateInputs(String number, String amount, String tipo) {
    if (number.isEmpty || amount.isEmpty) {
      return 'Número y monto son requeridos';
    }

    if (!RegExp(r'^\d+$').hasMatch(number) ||
        !RegExp(r'^\d+$').hasMatch(amount)) {
      return 'Formato erróneo: solo se permiten números';
    }

    if (tipo == "SPal") {
      if (!(number.length == 4)) {
        return 'Los Super pale deben de tener 4 dígitos';
      }
    }
    if (!(number.length == 2 || number.length == 4 || number.length == 6)) {
      return 'El número debe tener 2, 4 o 6 dígitos';
    }

    if (tipo == "SPal") {
      final selectedCount = _supPaleSelected.values.where((v) => v).length;

      if (selectedCount != 2) {
        return 'Debes seleccionar exactamente 2 loterías';
      }
    } else {
      if (!_quinielasSelected.values.any((v) => v)) {
        return 'Debes seleccionar al menos 1 lotería';
      }
    }

    return null;
  }

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
    );
  }

  // Dentro de tu _VentasPageState
  double _calcularTotal() {
    if (_venta == null || _venta!.detalles == null) return 0.0;
    return _venta!.detalles!.fold(
      0.0,
      (sum, detalle) => sum + (detalle.monto ?? 0.0),
    );
  }

  void _procesarCombinacion({
    required bool combinarPal,
    required bool combinarTri,
    required double monto,
  }) {
    if (_venta == null || _venta!.detalles == null) return;

    setState(() {
      // 🔹 Aquí se actualiza la UI
      // 1. Obtener todos los números de tipo Qui
      List<int> numeros = [];

      for (var d in _venta!.detalles!) {
        if (d.tipo == "Qui" && d.numero != null) {
          final partes = d.numero!.split(',');

          for (var p in partes) {
            final n = int.tryParse(p.trim());
            if (n != null) numeros.add(n);
          }
        }
      }

      if (numeros.isEmpty) return;

      // 2. Ordenar de mayor a menor
      numeros.sort((a, b) => b.compareTo(a));

      // 3. Crear un set con todos los números ya existentes
      final existentes = _venta!.detalles!
          .where((d) => d.numero != null)
          .map((d) => d.numero!)
          .toSet();

      // 4. COMBINACIONES PAL
      if (combinarPal) {
        for (int i = 0; i < numeros.length; i++) {
          for (int j = i + 1; j < numeros.length; j++) {
            final mayor = numeros[i];
            final menor = numeros[j];

            final nuevoNumero = "$mayor-$menor";

            if (!existentes.contains(nuevoNumero)) {
              existentes.add(nuevoNumero);
              _venta!.detalles!.add(
                VentaDetalle(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  numero: nuevoNumero,
                  monto: monto,
                  tipo: "Pal",
                  loteriaId: _venta!.detalles!.first.loteriaId,
                  loteriaSecondId: _venta!.detalles!.first.loteriaSecondId,
                  loteriaSlug: _venta!.detalles!.first.loteriaSlug,
                ),
              );
            }
          }
        }
      }

      // 5. COMBINACIONES TRI
      if (combinarTri) {
        for (int i = 0; i < numeros.length; i++) {
          for (int j = i + 1; j < numeros.length; j++) {
            for (int k = j + 1; k < numeros.length; k++) {
              final lista = [numeros[i], numeros[j], numeros[k]]
                ..sort((a, b) => b.compareTo(a));

              final nuevoNumero = "${lista[0]}-${lista[1]}-${lista[2]}";

              if (!existentes.contains(nuevoNumero)) {
                existentes.add(nuevoNumero);
                _venta!.detalles!.add(
                  VentaDetalle(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    numero: nuevoNumero,
                    monto: monto,
                    tipo: "Tri",
                    loteriaId: _venta!.detalles!.first.loteriaId,
                    loteriaSecondId: _venta!.detalles!.first.loteriaSecondId,
                    loteriaSlug: _venta!.detalles!.first.loteriaSlug,
                  ),
                );
              }
            }
          }
        }
      }
    }); // 🔹 Fin setState
  }

  void _openFinalizarModal() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Finalizar Jugada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
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

              // Opción 1: Imprimir
              ListTile(
                leading: Icon(Icons.print, color: AppColors.primary),
                title: const Text('Imprimir'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizarJugada('imprimir');
                },
              ),
              ListTile(
                leading: Icon(Icons.print, color: AppColors.primary),
                title: const Text('Imprimir y Compartir'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizarJugada('imprimir-compartir');
                },
              ),

              const Divider(),

              // Opción 2: Guardar
              ListTile(
                leading: Icon(Icons.save, color: Colors.green),
                title: const Text('Guardar'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizarJugada('guardar');
                },
              ),
              ListTile(
                leading: Icon(Icons.save, color: Colors.green),
                title: const Text('Guardar y Compartir'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizarJugada('compartir');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _finalizarJugada(String action) async {
    print('Acción: $action');
    SnackbarHelper.show(
      context,
      message: "Venta realizada correctamente",
      backgroundColor: AppColors.success,
    );

    // final success = await VentasService.finalizarVenta(_venta);

    // if (success) {
    //   print('Venta finalizada correctamente');
    // } else {
    //   print('Error al finalizar la venta');
    // }
  }

  void _editarSeleccionados() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editar monto"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Nuevo monto"),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // solo números (0-9)
            LengthLimitingTextInputFormatter(6), // máximo 6 dígitos
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final nuevoMonto = double.tryParse(controller.text) ?? 0;

              setState(() {
                for (var d in _seleccionados) {
                  d.monto = nuevoMonto;
                }
                _seleccionados.clear();
              });

              Navigator.pop(context);
            },
            child: Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Eliminar"),
        content: Text(
          "¿Seguro que quieres eliminar los elementos seleccionados?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _venta!.detalles!.removeWhere(
                  (d) => _seleccionados.contains(d),
                );
                _seleccionados.clear();
              });
              Navigator.pop(context);
            },
            child: Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  void _toggleSeleccion(VentaDetalle detalle) {
    setState(() {
      if (_seleccionados.contains(detalle)) {
        _seleccionados.remove(detalle);
      } else {
        _seleccionados.add(detalle);
      }
    });
  }
}
