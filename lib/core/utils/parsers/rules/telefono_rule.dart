import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';

class TelefonoRule extends ParserRule {
  @override
  bool matches(String cleanLine) {
    return containsAny(cleanLine, [
          'celular',
          'teléfono',
          'telefono',
          'cel ',
          'phone',
          'cel:',
          'tel',
          'telf',
          'contacto',
          'tlf'
        ]) ||
        RegExp(r'\b\d{7,15}\b').hasMatch(cleanLine);
  }

  @override
  void apply(String rawLine, ParsedReserva out) {
    String value = extractValue(rawLine);

    // Buscar número con regex
    final match = RegExp(r'(\+?\d[\d\s\-\(\)]{6,})').firstMatch(value);
    if (match != null) {
      String numero = match.group(0)!;

      // Normalizar: eliminar espacios, guiones, paréntesis
      numero = numero.replaceAll(RegExp(r'[\s\-\(\)]'), '');

      // Si no tiene prefijo y parece colombiano (10 dígitos y empieza por 3)
      if (!numero.startsWith('+') && numero.length == 10 && numero.startsWith('3')) {
        numero = '+57$numero';
      }

      // Si ya tiene +57, se deja igual
      out.telefono = numero;
    } else {
      out.telefono = value; // fallback
    }
  }
}
