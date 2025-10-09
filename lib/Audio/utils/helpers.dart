dynamic convertToSafeDartType(dynamic value) {
  if (value == null) {
    return null;
  } else if (value is List) {
    return List<dynamic>.from(value.map((item) => convertToSafeDartType(item)));
  } else if (value is Map) {
    Map<String, dynamic> result = {};
    value.forEach((key, val) {
      if (key is String) {
        result[key] = convertToSafeDartType(val);
      } else {
        result[key.toString()] = convertToSafeDartType(val);
      }
    });
    return result;
  } else {
    return value;
  }
}

String normalizarTexto(String texto) {
  // Mapa de sustituciones
  final Map<String, String> sustituciones = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
    'ñ': 'n', 'Ñ': 'N',
    'ü': 'u', 'Ü': 'U',
    '#': 'numero',
    '°': 'grados',
    'º': 'ordinal',
    '€': 'euros',
    '£': 'libras',
    '¥': 'yenes',
    '¿': '',
    '¡': '',
  };

  String textoNormalizado = texto;

  // Aplicar sustituciones
  sustituciones.forEach((special, normal) {
    textoNormalizado = textoNormalizado.replaceAll(special, normal);
  });

  return textoNormalizado;
}