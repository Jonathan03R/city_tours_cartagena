import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:intl/intl.dart';

class Formatters {
   static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: 'COP ');
    return formatter.format(amount);
  }
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy', 'es_CO');
    return formatter.format(date);
  }

  static String formatDateLong(DateTime date) {
    final formatter = DateFormat('EEEE, dd MMMM yyyy', 'es_CO');
    return formatter.format(date);
  }

  static String getEstadoText(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.pagada:
        return 'pagada';
      case EstadoReserva.pendiente:
        return 'Pendiente';
      case EstadoReserva.cancelada:
        return 'Cancelada';
    }
  }

  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm', 'es_CO');
    return formatter.format(dateTime);
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace un momento';
    }
  }

  static String formatPax(int pax) {
    return '$pax persona${pax != 1 ? 's' : ''}';
  }

  static String formatId(String id) {
    if (id.length > 8) {
      return '${id.substring(0, 8)}...';
    }
    return id;
  }
}
