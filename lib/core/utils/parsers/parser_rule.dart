import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_utils.dart';

/// Interfaz abstracta para todas las reglas de parseo.
abstract class ParserRule {
  /// Verifica si la línea limpia coincide con los criterios de esta regla.
  bool matches(String cleanLine);

  /// Aplica la lógica de parseo a la línea cruda y actualiza el objeto ParsedReserva.
  void apply(String rawLine, ParsedReserva out);

  /// Método auxiliar para extraer el valor después de un delimitador (ej. ':').
  /// Se puede usar en las implementaciones concretas de las reglas.
  String extractValue(String line) {
    return ParserUtils.extractValue(line);
  }

  /// Método auxiliar para verificar si la línea contiene alguna de las palabras clave.
  /// Se puede usar en las implementaciones concretas de las reglas.
  bool containsAny(String text, List<String> keywords) {
    return ParserUtils.containsAny(text, keywords);
  }
}
