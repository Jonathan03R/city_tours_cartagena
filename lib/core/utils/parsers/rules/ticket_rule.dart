import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';

/// Regla para parsear el ticket o número de boleto asociado
class TicketRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, ['ticket:', 'ticket', 'boleto:', 'boleto ']);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    out.ticket = extractValue(rawLine).trim();
  }
}