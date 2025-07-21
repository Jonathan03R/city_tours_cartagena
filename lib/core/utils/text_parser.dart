import 'package:citytourscartagena/core/models/reserva.dart';

import '../mvvc/reservas_controller.dart';

class TextParser {
  static Map<String, dynamic> parseReservaText(String text) {
    final Map<String, dynamic> result = {
      'nombreCliente': '',
      'hotel': '',
      'fecha': null,
      'pax': 1,
      'saldo': 0.0,
      'agenciaId': '',
      'observacion': '',
      'estado': EstadoReserva.pendiente,
    };

    // Limpiar el texto
    final cleanText = text.trim();
    final lines = cleanText.split('\n');

    for (String line in lines) {
      final cleanLine = line.trim().toLowerCase();

      // Detectar nombre
      if (_containsAny(cleanLine, ['nombre:', 'cliente:', 'name:'])) {
        result['nombreCliente'] = _extractValue(line);
      }
      // Detectar hotel
      else if (_containsAny(cleanLine, ['hotel:', 'hotel ', 'hospedaje:'])) {
        result['hotel'] = _extractValue(line);
      }
      // Detectar fecha
      else if (_containsAny(cleanLine, ['fecha:', 'date:', 'día:'])) {
        final dateStr = _extractValue(line);
        result['fecha'] = _parseDate(dateStr);
      }
      // Detectar PAX
      else if (_containsAny(cleanLine, [
        'pax:',
        'personas:',
        'huéspedes:',
        'guests:',
      ])) {
        final paxStr = _extractValue(line);
        result['pax'] = _parseInt(paxStr) ?? 1;
      }
      // Detectar saldo
      else if (_containsAny(cleanLine, [
        'saldo:',
        'precio:',
        'total:',
        'amount:',
        'costo:',
      ])) {
        final saldoStr = _extractValue(line);
        result['saldo'] = _parseDouble(saldoStr) ?? 0.0;
      }
      // Detectar observaciones
      else if (_containsAny(cleanLine, [
        'observacion:',
        'nota:',
        'comentario:',
        'obs:',
        'note:',
      ])) {
        result['observacion'] = _extractValue(line);
      }
      // Detectar estado
      else if (_containsAny(cleanLine, ['estado:', 'status:', 'situación:'])) {
        final estadoStr = _extractValue(line).toLowerCase();
        if (estadoStr.contains('confirmad') || estadoStr.contains('pagad')) {
          result['estado'] = EstadoReserva.confirmada;
        } else if (estadoStr.contains('cancelad')) {
          result['estado'] = EstadoReserva.cancelada;
        } else {
          result['estado'] = EstadoReserva.pendiente;
        }
      }
    }

    // Intentar encontrar agencia por nombre de hotel o texto
    result['agenciaId'] = _findAgenciaId(text);

    return result;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  static String _extractValue(String line) {
    // Buscar después de ':'
    if (line.contains(':')) {
      final parts = line.split(':');
      if (parts.length > 1) {
        return parts.sublist(1).join(':').trim();
      }
    }

    // Si no hay ':', tomar toda la línea después del primer espacio
    final words = line.trim().split(' ');
    if (words.length > 1) {
      return words.sublist(1).join(' ').trim();
    }

    return '';
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      // Limpiar el string de fecha
      final cleanDate = dateStr.replaceAll(RegExp(r'[^\d\-\/]'), '');

      // Intentar diferentes formatos
      final formats = [
        RegExp(
          r'(\d{1,2})[-\/](\d{1,2})[-\/](\d{2,4})',
        ), // dd-mm-yy o dd/mm/yyyy
        RegExp(r'(\d{2,4})[-\/](\d{1,2})[-\/](\d{1,2})'), // yyyy-mm-dd
      ];

      for (final format in formats) {
        final match = format.firstMatch(cleanDate);
        if (match != null) {
          int day, month, year;

          if (match.group(3)!.length == 4) {
            // Formato yyyy-mm-dd
            year = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            day = int.parse(match.group(3)!);
          } else {
            // Formato dd-mm-yy
            day = int.parse(match.group(1)!);
            month = int.parse(match.group(2)!);
            year = int.parse(match.group(3)!);

            // Ajustar año de 2 dígitos
            if (year < 50) {
              year += 2000;
            } else if (year < 100) {
              year += 1900;
            }
          }

          return DateTime(year, month, day);
        }
      }
    } catch (e) {
      print('Error parsing date: $dateStr - $e');
    }

    return null;
  }

  static int? _parseInt(String str) {
    try {
      final cleanStr = str.replaceAll(RegExp(r'[^\d]'), '');
      return int.parse(cleanStr);
    } catch (e) {
      return null;
    }
  }

  static double? _parseDouble(String str) {
    try {
      // Limpiar string manteniendo números y punto decimal
      final cleanStr = str.replaceAll(RegExp(r'[^\d\.]'), '');
      if (cleanStr.isEmpty) return null;
      return double.parse(cleanStr);
    } catch (e) {
      return null;
    }
  }

  static String _findAgenciaId(String text) {
    final agencias = ReservasController.getAllAgencias();
    final lowerText = text.toLowerCase();

    for (final agencia in agencias) {
      if (lowerText.contains(agencia.nombre.toLowerCase())) {
        return agencia.id;
      }
    }

    // Si no encuentra, usar la primera agencia disponible
    return agencias.isNotEmpty ? agencias.first.id : '';
  }

  // Método para generar ejemplo de texto
  static String getExampleText() {
    return '''Nombre: Adriana Contreras
    Fecha: 20-07-25
    Pax: 2
    Hotel: Aixon
    Saldo: 1500
    Cliente: julio
    Observacion: Cliente VIP
    Estado: confirmada
    Reportado: Brayan''';
  }
}
