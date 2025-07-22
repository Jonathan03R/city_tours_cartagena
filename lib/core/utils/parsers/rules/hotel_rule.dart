import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';

class HotelRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, ['hotel:', 'hotel ', 'hospedaje:']);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    out.hotel = extractValue(rawLine);
  }
}
