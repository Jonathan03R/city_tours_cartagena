import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart'; // Para EstadoReserva

class EstadoRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, ['estado:', 'status:', 'situación:']);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    final estadoStr = extractValue(rawLine).toLowerCase();
    if (estadoStr.contains('confirmad') || estadoStr.contains('pagad')) {
      out.estado = EstadoReserva.pagada;
    } else if (estadoStr.contains('cancelad')) {
      out.estado = EstadoReserva.cancelada;
    } else {
      out.estado = EstadoReserva.pendiente;
    }
  }
}
