import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';

class SaldoRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    final lower = cleanLine.toLowerCase().trim();
    const keys = [
      'saldo',
      'precio',
      'total',
      'amount',
      'costo',
      'saldo pendiente',
      'pendiente',
    ];
    // comprueba si arranca por "key:" o "key "
    for (var key in keys) {
      if (lower.startsWith('$key:') || lower.startsWith('$key ')) {
        return true;
      }
    }
    return false;
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    final match = RegExp(r'[\d.,]+').firstMatch(rawLine);
    if (match != null) {
      final rawNumber = match.group(0)!;
      final cleaned = rawNumber.replaceAll('.', '').replaceAll(',', '.');
      out.saldo = double.tryParse(cleaned) ?? 0.0;
    } else {
      out.saldo = 0.0;
    }
  }
}