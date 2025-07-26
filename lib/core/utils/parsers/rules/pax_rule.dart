import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_utils.dart';

class PaxRule extends ParserRule {
  // unificamos las claves aquí
  static const _keys = ['pax', 'personas', 'huéspedes', 'guests'];

  @override
  bool matches(String cleanLine) {
    final lower = cleanLine.toLowerCase().trim();
    for (var key in _keys) {
      // escapamos por si hubiera caracteres especiales
      final pattern = RegExp(r'\b' + RegExp.escape(key) + r'\b');
      if (pattern.hasMatch(lower)) {
        return true;
      }
    }
    return false;
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    final lower = rawLine.toLowerCase();
    String value = '';

    if (rawLine.contains(':')) {
      value = extractValue(rawLine);
    } else {
      for (var key in _keys) {
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