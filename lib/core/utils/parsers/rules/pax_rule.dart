import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_utils.dart';

class PaxRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    final lower = cleanLine.toLowerCase().trim();
    const keys = ['pax', 'personas', 'huéspedes', 'guests'];
    // detecta tanto "key:" como "key " sin dos puntos
    for (var key in keys) {
      if (lower.startsWith('$key:') || lower.startsWith('$key ')) {
        return true;
      }
    }
    return false;
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    final lower = rawLine.toLowerCase();
    const keys = ['pax', 'personas', 'huéspedes', 'guests'];
    String value;

    if (rawLine.contains(':')) {
      // usa extractValue cuando hay ":"
      value = extractValue(rawLine);
    } else {
      // busca la clave y extrae el texto que sigue
      value = '';
      for (var key in keys) {
        final idx = lower.indexOf(key);
        if (idx != -1) {
          value = rawLine.substring(idx + key.length).trim();
          break;
        }
      }
    }

    out.pax = ParserUtils.parseInt(value) ?? out.pax;
  }
}