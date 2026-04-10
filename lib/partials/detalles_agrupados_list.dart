import 'package:flutter/material.dart';
import '../model/venta_model.dart';
import '../theme/theme.dart';

typedef OnTapDetalle = void Function(VentaDetalle detalle);
typedef OnToggleSeleccion = void Function(VentaDetalle detalle);

class DetallesAgrupadosList extends StatelessWidget {
  final List<VentaDetalle> detalles;
  final OnTapDetalle onTapDetalle;

  final Set<VentaDetalle> seleccionados;
  final OnToggleSeleccion onToggleSeleccion;

  const DetallesAgrupadosList({
    Key? key,
    required this.detalles,
    required this.onTapDetalle,
    required this.seleccionados,
    required this.onToggleSeleccion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tiposOrdenados = ['Tri', 'SPal', 'Pal', 'Qui'];

    return ListView(
      children: tiposOrdenados.expand((tipo) {
        final detallesPorTipo = detalles.where((d) => d.tipo == tipo).toList();

        if (detallesPorTipo.isEmpty) return <Widget>[];

        return [
          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(thickness: 1, color: AppColors.secondary),
              ],
            ),
          ),

          // LISTA
          ...detallesPorTipo.map((detalle) {
            final isSelected = seleccionados.contains(detalle);

            return GestureDetector(
              onTap: () => onTapDetalle(detalle),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // ✅ CHECKBOX
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggleSeleccion(detalle),
                      ),

                      // TIPO / LOTERIA
                      Expanded(
                        flex: 3,
                        child: Text(
                          detalle.loteriaSlug != null
                              ? '(${detalle.tipo}) ${detalle.loteriaSlug}'
                              : detalle.tipo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),

                      // NÚMERO
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          child: Text(
                            detalle.numberFormated ?? detalle.numero ?? '',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      // MONTO
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '\$${(detalle.monto ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ];
      }).toList(),
    );
  }
}
