import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_utils.dart';

class FechaRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, ['fecha', 'date', 'día']);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    String dateStr = '';
    if (rawLine.contains(':')) {
      dateStr = extractValue(rawLine);
    } else {
      // Buscar la palabra clave y extraer lo que sigue
      final lower = rawLine.toLowerCase();
      final keywords = ['fecha', 'date', 'día'];
      for (var keyword in keywords) {
        if (lower.contains(keyword)) {
          int idx = lower.indexOf(keyword) + keyword.length;
          dateStr = rawLine.substring(idx).trim();
          break;
        }
      }
    }

    // Intentar parsear la fecha
    out.fecha = ParserUtils.parseDate(dateStr);
  }
}
