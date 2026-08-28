import 'package:flutter/material.dart';

class ReportesPage extends StatelessWidget {
  final List<dynamic> ventas;
  final Map<String, dynamic> filtros;
  final String title;
  final String moduleName;

  const ReportesPage({
    super.key,
    required this.ventas,
    required this.filtros,
    this.title = "Reporte de Ventas",
    this.moduleName = "",
  });

  @override
  Widget build(BuildContext context) {
    final int totalOrdenes = ventas.length;

    final double totalBruto = ventas.fold(
      0.0,
      (sum, v) => sum + ((v['total_venta_bruto'] ?? 0) as num).toDouble(),
    );

    final double totalNeto = ventas.fold(
      0.0,
      (sum, v) => sum + ((v['total_neto'] ?? 0) as num).toDouble(),
    );

    final double totalComision = ventas.fold(
      0.0,
      (sum, v) => sum + ((v['total_comision'] ?? 0) as num).toDouble(),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),

      // 🧹 BOTÓN SIMPLIFICADO (SIN IMPRESIÓN)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint("Reporte generado: ${ventas.length} ventas");
        },
        child: const Icon(Icons.info),
      ),

      body: Column(
        children: [
          // ================= RESUMEN =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.black),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "RESUMEN GENERAL",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("TOTAL ÓRDENES: $totalOrdenes"),
                Text("TOTAL BRUTO: $totalBruto"),
                Text(
                  "TOTAL NETO: $totalNeto",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "TOTAL COMISIÓN: $totalComision",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // ================= LISTA =================
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ventas.length,
              itemBuilder: (context, index) {
                final v = ventas[index];
                final List details = v['details'] ?? [];

                final bool premiado = v['premiado'] == true;
                final double totalPremio =
                    (v['total_premiado'] ?? 0).toDouble();

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= HEADER =================
                      if (v['deleted_at'] != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "ANULADO",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      Text(
                        "VENTA: ${v['code']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("FECHA: ${v['date']}"),
                      Text("VENDEDOR: ${v['created_by_code']}"),

                      const SizedBox(height: 8),

                      // ================= RESUMEN =================
                      Text("TOTAL BRUTO: ${v['total_venta_bruto']}"),

                      if (moduleName != "tickets_anulados")
                        Text(
                          "TOTAL COMISIÓN: ${v['total_comision']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                      Text(
                        "TOTAL NETO: ${v['total_neto']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      if (premiado && totalPremio > 0)
                        Text(
                          "TOTAL PREMIO: $totalPremio",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),

                      const SizedBox(height: 6),

                      if (premiado)
                        const Text(
                          "PREMIADO ✔",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),

                      if (premiado) const SizedBox(height: 6),

                      if (premiado)
                        Text(
                          v['paid_at'] != null ? "PAGADO" : "NO PAGADO",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: v['paid_at'] != null
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),

                      const Divider(),

                      // ================= HEADER TABLA =================
                      const Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              "LOTERIA",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "NUM",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "TIPO",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "MONTO",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "PREM",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // ================= DETAILS =================
                      ...details.map((d) {
                        final bool detPremiado =
                            d['premiado'] == 1 || d['premiado'] == true;

                        return Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                d['short_name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                d['number_formatted'].toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                d['type'].toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                d['monto_jugada'].toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: detPremiado
                                  ? Text(
                                      d['monto_premio'].toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const Text(
                                      "-",
                                      style: TextStyle(fontSize: 12),
                                    ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
