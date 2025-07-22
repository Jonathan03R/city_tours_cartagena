import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_utils.dart';

class CostoAsientoRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, ['costo asiento:', 'costo por asiento:', 'seat cost:']);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    final costoStr = extractValue(rawLine);
    out.costoAsiento = ParserUtils.parseDouble(costoStr) ?? 0.0;
  }
}
