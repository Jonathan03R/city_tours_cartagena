import 'package:citytourscartagena/core/mvvc/reservas_controller.dart';

/// Clase de utilidad para funciones de parseo comunes.
class ParserUtils {
  /// Verifica si el texto contiene alguna de las palabras clave.
  static bool containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Extrae el valor de una línea, buscando después de ':' o el primer espacio.
  static String extractValue(String line) {
    // Buscar después de ':'
    if (line.contains(':')) {
      final parts = line.split(':');
      if (parts.length > 1) {
        return parts.sublist(1).join(':').trim();
      }
    }
    // Si no hay ':', tomar toda la línea después del primer espacio
    final words = line.trim().split(' ');
    if (words.length > 1) {
      return words.sublist(1).join(' ').trim();
    }
    return '';
  }

  /// Parsea una cadena de texto a un DateTime.
  static DateTime? parseDate(String input) {
    try {
      String clean = input.toLowerCase().trim();
      clean = clean.replaceAll(RegExp(r'(de|del|el|a|las)'), ' ');

      // Diccionario de meses
      final months = {
        'enero': 1,
        'febrero': 2,
        'marzo': 3,
        'abril': 4,
        'mayo': 5,
        'junio': 6,
        'julio': 7,
        'agosto': 8,
        'septiembre': 9,
        'octubre': 10,
        'noviembre': 11,
        'diciembre': 12,
        'jan': 1,
        'feb': 2,
        'mar': 3,
        'apr': 4,
        'may': 5,
        'jun': 6,
        'jul': 7,
        'aug': 8,
        'sep': 9,
        'oct': 10,
        'nov': 11,
        'dec': 12,
      };

      int? day, month, year;

      // 1️⃣ Detectar formato numérico clásico
      final numericMatch = RegExp(
        r'(\d{1,4})[-\/](\d{1,2})[-\/](\d{1,4})',
      ).firstMatch(clean);
      if (numericMatch != null) {
        int g1 = int.parse(numericMatch.group(1)!);
        int g2 = int.parse(numericMatch.group(2)!);
        int g3 = int.parse(numericMatch.group(3)!);

        if (g1 > 31) {
          year = g1;
          month = g2;
          day = g3;
        } else if (g3 > 31) {
          day = g1;
          month = g2;
          year = g3;
        } else {
          day = g1;
          month = g2;
          year = (g3 < 50) ? g3 + 2000 : (g3 < 100 ? g3 + 1900 : g3);
        }
        return DateTime(year, month, day);
      }

      // 2️⃣ Si no es formato numérico, buscar palabras (ej: "12 de agosto 2025")
      final parts = clean
          .split(RegExp(r'[\s,]+'))
          .where((p) => p.isNotEmpty)
          .toList();
      for (var part in parts) {
        if (int.tryParse(part) != null) {
          int num = int.parse(part);
          if (num > 31) {
            year = num;
          } else if (day == null) {
            day = num;
          } else if (month == null) {
            month = num;
          }
        } else if (months.containsKey(part)) {
          month = months[part];
        }
      }

      if (year != null && year < 100) {
        year += (year < 50) ? 2000 : 1900;
      }

      year ??= DateTime.now().year;

      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    } catch (_) {}

    return null;
  }

  /// Parsea una cadena de texto a un entero.
  static int? parseInt(String str) {
    try {
      final cleanStr = str.replaceAll(RegExp(r'[^\d]'), '');
      return int.parse(cleanStr);
    } catch (e) {
      return null;
    }
  }

  /// Parsea una cadena de texto a un double.
  static double? parseDouble(String str) {
    try {
      // Elimina caracteres que no sean dígitos, punto o coma
      String clean = str.replaceAll(RegExp(r'[^0-9,\.]'), '');

      // Caso: "50.000" → quitar puntos si no hay coma decimal
      if (clean.contains('.') && !clean.contains(',')) {
        clean = clean.replaceAll('.', '');
      }

      // Cambiar coma por punto para decimales
      clean = clean.replaceAll(',', '.');

      if (clean.isEmpty) return null;
      return double.parse(clean);
    } catch (_) {
      return null;
    }
  }

  static String extractNumber(String line) {
  final match = RegExp(r'([0-9]+[.,]?[0-9]*)').firstMatch(line);
  return match?.group(0) ?? '';
}

  /// Intenta encontrar el ID de la agencia en el texto completo.
  static String findAgenciaId(String text) {
    final agencias = ReservasController.getAllAgencias();
    final lowerText = text.toLowerCase();
    for (final agencia in agencias) {
      if (lowerText.contains(agencia.nombre.toLowerCase())) {
        return agencia.id;
      }
    }
    // Si no encuentra, usar la primera agencia disponible
    return agencias.isNotEmpty ? agencias.first.id : '';
  }
}
