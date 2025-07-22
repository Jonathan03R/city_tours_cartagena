import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_utils.dart';

class PaxRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, ['pax:', 'personas:', 'huéspedes:', 'guests:']);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    final paxStr = extractValue(rawLine);
    out.pax = ParserUtils.parseInt(paxStr) ?? 1;
  }
}
