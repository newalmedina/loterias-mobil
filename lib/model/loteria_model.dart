import 'dart:convert';
import 'package:http/http.dart' as http;

class Loteria {
  final int id;
  final String shortName;
  final String nombre;
  final String? imageBase64;
  final String? imageUrl;
  final bool? disponible;

  Loteria({
    required this.id,
    required this.shortName,
    required this.nombre,
    this.imageUrl,
    this.imageBase64,
    this.disponible,
  });

  factory Loteria.fromJson(Map<String, dynamic> json) {
    return Loteria(
      id: json['id'],
      shortName: json['short_name'],
      nombre: json['nombre'],
      imageBase64: json['image_base64'],
      imageUrl: json['image_url'],
      disponible: json['disponible'],
    );
  }
}

Future<List<Loteria>> fetchLoterias() async {
  final url = 'TU_API_URL_AQUI';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);

    // Asegúrate de acceder a 'data', que es donde está la lista
    final List<dynamic> loteriasJson = jsonResponse['data'];

    // Convertir cada JSON a objeto Loteria
    List<Loteria> loteriasList = loteriasJson
        .map((json) => Loteria.fromJson(json))
        .toList();

    return loteriasList;
  } else {
    throw Exception('Error al cargar loterías: ${response.statusCode}');
  }
}

void main() async {
  try {
    List<Loteria> loterias = await fetchLoterias();
    // print('Loterías recibidas: ${loterias.length}');
    // ignore: unused_local_variable
    for (var l in loterias) {
      // print('${l.nombre} - ${l.shortName}');
    }
  } catch (e) {
    // print(e);
  }
}
