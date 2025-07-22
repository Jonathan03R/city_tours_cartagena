import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';

class ObservacionRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, ['observacion:', 'nota:', 'comentario:', 'obs:', 'note:']);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    out.observacion = extractValue(rawLine);
  }
}
