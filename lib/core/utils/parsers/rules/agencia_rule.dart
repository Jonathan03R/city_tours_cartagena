import 'package:citytourscartagena/core/models/agencia.dart'; // Importar el modelo Agencia
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
    // Este método `apply` no se usará para esta regla especial.
    // La lógica de esta regla se aplica al texto completo a través de `applyToFullText`.
    // Dejamos el cuerpo vacío o lanzamos un error si se llama inesperadamente.
    throw UnimplementedError('AgenciaRule.apply should not be called directly. Use applyToFullText.');
  }

  // Método específico para aplicar esta regla al texto completo
  // MODIFICADO: Ahora recibe la lista de agencias como parámetro
  void applyToFullText(ParsedReserva out, List<Agencia> agencias) {
    out.agenciaId = ParserUtils.findAgenciaId(out.rawText, agencias);
  }
}
