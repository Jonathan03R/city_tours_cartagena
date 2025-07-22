import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';

class ObservacionRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    final lower = cleanLine.toLowerCase().trim();
    const keys = [
      'observaciones',
      'observacion',
      'nota',
      'comentario',
      'obs',
      'note',
    ];
    for (var key in keys) {
      if (lower.startsWith('$key:') || lower.startsWith('$key ')) {
        return true;
      }
    }
    return false;
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    String value;
    if (rawLine.contains(':')) {
      value = extractValue(rawLine);
    } else {
      final lower = rawLine.toLowerCase();
      const keys = [
        'observaciones',
        'observacion',
        'nota',
        'comentario',
        'obs',
        'note',
      ];
      value = '';
      for (var key in keys) {
        final idx = lower.indexOf(key);
        if (idx != -1) {
          value = rawLine.substring(idx + key.length).trim();
          break;
        }
      }
    }
    out.observacion = value;
  }
}