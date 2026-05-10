import 'package:flutter/material.dart';
import 'package:loterymobile/components/custom_button.dart';
import 'package:loterymobile/services/ventas_service.dart';
import 'package:loterymobile/theme/theme.dart';
import 'package:loterymobile/widgets/snackbar_helper.dart';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';

class ListadoDetalle extends StatefulWidget {
  final List<dynamic> ventas;
  final String? moduleName;
  final VoidCallback? onRefresh;

  const ListadoDetalle({
    super.key,
    required this.ventas,
    this.moduleName,
    this.onRefresh,
  });

  @override
  State<ListadoDetalle> createState() => _ListadoDetalleState();
}

class _ListadoDetalleState extends State<ListadoDetalle> {
  bool detalleVenta = false;

  // =========================
  // MODAL DETALLE
  // =========================
  void _openVenta(Map<String, dynamic> venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool premiado =
            venta['premiado'] == 1 || venta['premiado'] == true;

        final bool pagado =
            venta['paid_at'] != null && venta['paid_at'].toString().isNotEmpty;

        final bool hasQr =
            venta['qr_code'] != null && venta['qr_code'].toString().isNotEmpty;

        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.92,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // ================= HEADER =================
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.orange, width: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Venta ${venta['code']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // ✔️ BOTÓN PAGAR (SOLO SI SE PUEDE PAGAR)
                      if (widget.moduleName == 'ventas_realizadas' &&
                          venta['can_delete'] == true)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _anularVentaModal(context, venta['id']);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger, // texto e icono
                            side: const BorderSide(
                              color: AppColors.danger,
                            ), // 👈 borde
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.payment),
                          label: const Text("Anular venta"),
                        ),
                      if (widget.moduleName == 'tickets_premiados' &&
                          venta['can_pay'] == true)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _pagarVentaModal(context, venta['id']);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.green, // color del texto e icono
                            side: const BorderSide(
                              color: Colors.green,
                            ), // 👈 borde
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.payment),
                          label: const Text("Pagar ticket"),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // ================= CONTENIDO SCROLL =================
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // LABEL
                        if (premiado)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: pagado
                                  ? AppColors.success
                                  : AppColors.danger,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pagado ? "PAGADO" : "NO PAGADO",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        // INFO BOX
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ================= IZQUIERDA (DATOS) =================
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Vendido por: ${venta['created_by_name']} (${venta['created_by_code']})",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      if (pagado)
                                        Text(
                                          "Pagado por: ${venta['paid_by_name']} (${venta['paid_by_code']})",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),

                                      const SizedBox(height: 10),

                                      Text(
                                        "Total bruto: \$${venta['total_venta_bruto']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Comisión: \$${venta['total_comision']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Total neto: \$${venta['total_neto']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      if (premiado)
                                        Text(
                                          "Total premiado: \$${venta['total_premiado']}",
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // ================= DERECHA (QR) =================
                                if (hasQr) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.2),
                                      ),
                                    ),
                                    child: buildQr(venta['qr_code']),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(),

                        // ================= DETALLE =================
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: venta['details'].length,
                            itemBuilder: (context, i) {
                              final d = venta['details'][i];

                              final bool detPremiado =
                                  d['premiado'] == 1 || d['premiado'] == true;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "${d['loterie_nombre']} - ${d['number_formatted']} (${d['type']}) | \$${d['monto_jugada']}",
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    if (detPremiado)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.emoji_events,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "\$${d['monto_premio'] ?? 0}",
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ================= BOTÓN =================
                        if (widget.moduleName == 'ventas_realizadas')
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: CustomButton(
                              text: 'Imprimir',
                              icon: Icons.print,
                              color: AppColors.primary,
                              onPressed: () {},
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],
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

  Future<dynamic> _anularVentaModal(BuildContext context, int ventaId) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar"),
        content: const Text("¿Seguro que quieres anular esta venta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _anularVenta(ventaId); // 👈 LLAMADA REAL
              // 👉 Aquí ejecutas la lógica de eliminación
              // eliminarVenta(venta['id']);
            },
            child: const Text("Anular", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _openVentaById(int id) async {
    final venta = await VentasService.findVenta(id);

    if (venta == null) {
      //print("❌ No se encontró la venta");
      return;
    }

    _openVenta(venta);
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final ventas = widget.ventas;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Total de ventas: ${ventas.length}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        // ================= TOGGLE =================
        if (ventas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text("Ventas"),
                Switch(
                  value: detalleVenta,
                  onChanged: (val) {
                    setState(() => detalleVenta = val);
                  },
                ),
                const Text("Detalle"),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // ================= LISTA CON SCROLL =================
        Expanded(
          child: ListView.builder(
            itemCount: ventas.length,
            padding: const EdgeInsets.only(bottom: 20),
            itemBuilder: (context, index) {
              final v = ventas[index];

              final bool pagado = v['paid_at'] != null;
              final bool premiado = v['premiado'] == 1;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= CONTENT =================
                      Expanded(
                        child: detalleVenta
                            // ================= DETAIL VIEW =================
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ================= HEADER =================
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    "${v['code']} | ${v['created_by_code']} | ${v['date']}",
                                              ),

                                              if ((v['total_comision'] ?? 0) !=
                                                  0)
                                                TextSpan(
                                                  text:
                                                      " | com. \$${v['total_comision']}",
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),

                                              TextSpan(
                                                text:
                                                    " | \$${v['total_venta_bruto'] ?? 0}",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 🏆 PREMIADO
                                      if (v['premiado'] == 1 ||
                                          v['premiado'] == true) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.emoji_events,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "\$${v['total_premiado'] ?? 0}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 4),

                                  // ================= LABEL PAGO =================
                                  if (v['premiado'] == 1 ||
                                      v['premiado'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pagado
                                            ? AppColors.success
                                            : AppColors.danger,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pagado ? "Pagado" : "No pagado",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 6),

                                  // ================= INFO USUARIO =================
                                  Text(
                                    "Vendido por: ${v['created_by_name']} (${v['created_by_code']})",
                                    style: const TextStyle(fontSize: 12),
                                  ),

                                  if (v['paid_at'] != null)
                                    Text(
                                      "Pagado por: ${v['paid_by_name']} (${v['paid_by_code']})",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),

                                  const SizedBox(height: 6),

                                  // ================= TOTALES =================
                                  Text(
                                    "Total bruto: \$${v['total_venta_bruto'] ?? 0}",
                                  ),
                                  Text(
                                    "Comisión: \$${v['total_comision'] ?? 0}",
                                  ),
                                  Text("Total neto: \$${v['total_neto'] ?? 0}"),

                                  if (v['premiado'] == 1 ||
                                      v['premiado'] == true)
                                    Text(
                                      "Total premiado: \$${v['total_premiado'] ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                  const SizedBox(height: 8),
                                  const Divider(),

                                  // ================= DETALLE COMPACTO =================
                                  ...List.generate(v['details'].length, (i) {
                                    final d = v['details'][i];

                                    final monto = d['monto_jugada'] ?? 0;
                                    final montoPremio = d['monto_premio'] ?? 0;
                                    final premiado =
                                        d['premiado'] == 1 ||
                                        d['premiado'] == true;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "${d['loterie_nombre']} - ${d['number_formatted']} (${d['type']}) | \$${monto}",
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),

                                          if (premiado)
                                            Text(
                                              "🏆 \$${montoPremio}",
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // 📝 TEXTO PRINCIPAL
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    "${v['code']} | ${v['created_by_code']} | ${v['date']}",
                                              ),

                                              if ((v['total_comision'] ?? 0) !=
                                                  0)
                                                TextSpan(
                                                  text:
                                                      " | com. \$${v['total_comision']}",
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),

                                              TextSpan(
                                                text:
                                                    " | \$${v['total_venta_bruto'] ?? 0}",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 🎯 LABEL PAGADO / NO PAGADO
                                      if ((v['premiado'] == 1 ||
                                          v['premiado'] == true))
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (v['paid_at'] == null ||
                                                    v['paid_at']
                                                        .toString()
                                                        .isEmpty)
                                                ? Colors.red
                                                : Colors.green,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            (v['paid_at'] == null ||
                                                    v['paid_at']
                                                        .toString()
                                                        .isEmpty)
                                                ? "NO PAGADO"
                                                : "PAGADO",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),

                                      // 🏆 COPA + MONTO PREMIADO AL FINAL
                                      if ((v['premiado'] == 1 ||
                                          v['premiado'] == true)) ...[
                                        const Icon(
                                          Icons.emoji_events,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "\$${v['total_premiado'] ?? 0}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  if (premiado)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: pagado
                                            ? AppColors.success
                                            : AppColors.danger,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        pagado ? "Pagado" : "No pagado",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),

                      // ================= ARROW (SIEMPRE) =================
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed: () => _openVentaById(v['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _anularVenta(int id) async {
    final response = await VentasService.anularVenta(id);

    if (response.success) {
      SnackbarHelper.show(
        context,
        message: response.message.isNotEmpty
            ? response.message
            : "Venta anulada correctamente",
        backgroundColor: AppColors.success,
      );

      widget.onRefresh?.call();
    } else {
      SnackbarHelper.show(
        context,
        message: response.message,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Future<dynamic> _pagarVentaModal(BuildContext context, int ventaId) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar pago"),
        content: const Text(
          "¿Seguro que quieres marcar esta venta como pagada?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pagarVenta(ventaId);
            },
            child: const Text("Pagar", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Future<void> _pagarVenta(int id) async {
    final response = await VentasService.pagarVenta(id);

    if (response.success) {
      SnackbarHelper.show(
        context,
        message: response.message.isNotEmpty
            ? response.message
            : "Venta pagada correctamente",
        backgroundColor: AppColors.success,
      );

      widget.onRefresh?.call();
    } else {
      SnackbarHelper.show(
        context,
        message: response.message,
        backgroundColor: AppColors.danger,
      );
    }
  }

  Widget buildQr(String dataUri) {
    try {
      final base64Data = dataUri.split(',').last;
      final svgString = utf8.decode(base64Decode(base64Data));

      return SvgPicture.string(svgString, width: 120, height: 120);
    } catch (e) {
      return const Icon(Icons.qr_code, size: 120);
    }
  }
}
