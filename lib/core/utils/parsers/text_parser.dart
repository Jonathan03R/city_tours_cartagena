import 'package:citytourscartagena/core/models/parsed_reserva.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/agencia_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/costo_asiento_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/estado_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/fecha_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/hotel_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/nombre_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/observacion_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/pax_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/saldo_rule.dart';
import 'package:citytourscartagena/core/utils/parsers/rules/telefono_rule.dart';

/// Clase principal para parsear texto de reservas usando el patrón Chain of Responsibility.
class TextParser {
  final List<ParserRule> _rules;
  final AgenciaRule _agenciaRule; // La regla de agencia se maneja por separado

  TextParser()
      : _rules = [
          NombreRule(),
          HotelRule(),
          FechaRule(),
          PaxRule(),
          SaldoRule(),
          ObservacionRule(),
          EstadoRule(),
          TelefonoRule(),
          CostoAsientoRule(), // Añadida la nueva regla
        ],
        _agenciaRule = AgenciaRule(); // Instancia de la regla de agencia

  /// Parsea el texto de una reserva y devuelve un Map<String, dynamic>.
  Map<String, dynamic> parseReservaText(String text) {
    final cleanText = text.trim();
    final lines = cleanText.split('\n');

    // Inicializa el objeto ParsedReserva con el texto completo
    final ParsedReserva parsedReserva = ParsedReserva(rawText: cleanText);

    for (String line in lines) {
      final cleanLine = line.trim().toLowerCase();
      for (final rule in _rules) {
        if (rule.matches(cleanLine)) {
          rule.apply(line, parsedReserva); // Pasa la línea original para _extractValue
          break; // Una vez que una regla coincide, pasa a la siguiente línea
        }
      }
    }

    // Aplica la regla de agencia al final, usando el texto completo
    _agenciaRule.applyToFullText(parsedReserva);

    return parsedReserva.toMap();
  }

  /// Método para generar ejemplo de texto (igual que el original)
  static String getExampleText() {
    return '''Nombre: Adriana Contreras
    Fecha: 20-07-25
    Pax: 2
    Hotel: Aixon
    Saldo: 1500
    Cliente: julio
    Observacion: Cliente VIP
    Estado: confirmada
    Reportado: Brayan'''; // Añadido costo asiento al ejemplo
  }
}
