// lib/model/venta_model.dart

class Venta {
  String? id;
  String? code;
  DateTime? fecha;
  List<VentaDetalle>? detalles;

  Venta({this.id, this.code, this.fecha, this.detalles});
}

class VentaDetalle {
  String? id;
  String? numero;
  double? monto;
  int? loteriaId;
  int? loteriaSecondId;
  String? loteriaSlug;
  String tipo; // nuevo parámetro, por defecto 'Qui'
  String? numberFormated; // campo que contendrá el número ordenado

  VentaDetalle({
    this.id,
    this.numero,
    this.monto,
    this.loteriaId,
    this.loteriaSecondId,
    this.loteriaSlug,
    this.tipo = 'Qui',
  }) {
    // Llamamos a la función dentro del constructor
    if (numero != null && numero!.isNotEmpty) {
      numero = ordenarNumeros(numero!);
      numberFormated = ordenarNumeros2(numero!);
    }
  }

  // Función para dividir de 2 en 2 y ordenar de mayor a menor
  String ordenarNumeros(String numero) {
    if (numero.length == 4 || numero.length == 6) {
      List<String> volas = [];
      for (int i = 0; i < numero.length; i += 2) {
        volas.add(numero.substring(i, i + 2));
      }
      // Ordena de mayor a menor
      volas.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
      // Devuelve como string separado por guiones
      return volas.join(''); // <--- con guion
    } else {
      return numero; // si no tiene 4 o 6 dígitos, se devuelve tal cual
    }
  }

  String ordenarNumeros2(String numero) {
    if (numero.length == 4 || numero.length == 6) {
      List<String> volas = [];
      for (int i = 0; i < numero.length; i += 2) {
        volas.add(numero.substring(i, i + 2));
      }
      // Ordena de mayor a menor
      volas.sort((a, b) => int.parse(b).compareTo(int.parse(a)));
      // Devuelve como string separado por guiones
      return volas.join('-'); // <--- con guion
    } else {
      return numero; // si no tiene 4 o 6 dígitos, se devuelve tal cual
    }
  }
}
