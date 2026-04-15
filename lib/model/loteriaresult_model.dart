class LoteriaResult {
  final int? loterieId;
  final String? date;
  final String? shortName;
  final String? name;
  final String? slug;
  final String? completeName;
  final String? code;
  final List<String>? numbers;
  final String? image;

  LoteriaResult({
    this.loterieId,
    this.date,
    this.shortName,
    this.name,
    this.slug,
    String? completeName, // opcional, lo construimos abajo
    this.code,
    this.numbers,
    this.image,
  }) : completeName =
           completeName ?? // si se pasa manualmente, se respeta
           //  '${shortName ?? 'Sin nombre'} - ${name ?? 'Sin nombre'} (${date ?? 'Sin fecha'})';
           '${name ?? 'Sin nombre'} (${date ?? 'Sin fecha'})';

  factory LoteriaResult.fromJson(Map<String, dynamic> json) {
    final short = json['short_name'] as String?;
    final name = json['name'] as String?;
    final date = json['date'] as String?;
    return LoteriaResult(
      loterieId: json['loterie_id'],
      date: date,
      shortName: short,
      name: name,
      slug: json['slug'],
      code: json['code'],
      numbers: json['numbers'] != null
          ? List<String>.from(json['numbers'])
          : null,
      image: json['image_base64'],
      // completeName se construye automáticamente
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'loterie_id': loterieId,
      'date': date,
      'short_name': shortName,
      'name': name,
      'slug': slug,
      'code': code,
      'numbers': numbers,
      'image': image,
      'complete_name': completeName,
    };
  }
}
