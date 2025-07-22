import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';

class NombreRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, [
      'nombre',
      'cliente',
      'name',
      'reservante',
    ]);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    String value = '';
    if (rawLine.contains(':')) {
      value = extractValue(rawLine);
    } else {
      // Buscar la palabra clave y extraer lo que sigue
      final lower = rawLine.toLowerCase();
      final keywords = ['nombre', 'cliente', 'name'];
      for (var keyword in keywords) {
        if (lower.contains(keyword)) {
          int idx = lower.indexOf(keyword) + keyword.length;
          value = rawLine.substring(idx).trim();
          break;
        }
      }
    }

    // Limpiar texto extra
    out.nombreCliente = value.replaceAll(RegExp(r'[^a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'), '').trim();
  }
}
