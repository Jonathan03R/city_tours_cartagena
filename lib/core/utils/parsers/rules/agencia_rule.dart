import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_utils.dart';

/// Esta regla es especial: no coincide con una línea específica,
/// sino que se aplica al final para buscar la agencia en el texto completo.
class AgenciaRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    // Esta regla no "coincide" con una línea, se aplica de forma diferente.
    // Siempre devuelve false para no ser procesada línea por línea.
    return false;
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    // La lógica de esta regla se aplica al texto completo, no a una línea individual.
    // Por eso, el `rawLine` aquí es el texto completo de la reserva.
    out.agenciaId = ParserUtils.findAgenciaId(out.rawText);
  }

  // Método específico para aplicar esta regla al texto completo
  void applyToFullText(ParsedReserva out) {
    out.agenciaId = ParserUtils.findAgenciaId(out.rawText);
  }
}
