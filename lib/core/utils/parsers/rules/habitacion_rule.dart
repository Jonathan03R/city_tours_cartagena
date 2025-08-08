import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';

/// Regla para parsear el número o nombre de habitación
class HabitacionRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, [
      'habitacion:',
      'habitacion',
      'habitación:',
      'habitación',
      'hab:',
      'hab '
    ]);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    out.habitacion = extractValue(rawLine).trim();
  }
}