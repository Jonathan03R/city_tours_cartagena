import 'package:citytourscartagena/core/models/reserva.dart'; // Importa tu enum EstadoReserva

/// Modelo intermedio para almacenar los datos de la reserva parseados.
class ParsedReserva {
  String nombreCliente;
  String hotel;
  DateTime? fecha; // Se mapeará a 'fechaReserva' en toMap()
  int pax;
  double saldo;
  String agenciaId;
  String observacion;
  EstadoReserva estado;
  String telefono;
  double costoAsiento; // Nuevo campo
  String habitacion; // Nuevo campo para habitación
  String ticket;     // Nuevo campo para ticket
  String rawText; // Para la regla de agencia que necesita el texto completo

  ParsedReserva({
    this.nombreCliente = '',
    this.hotel = '',
    this.fecha,
    this.pax = 1,
    this.saldo = 0.0,
    this.agenciaId = '',
    this.observacion = '',
    this.estado = EstadoReserva.pendiente,
    this.telefono = '',
    this.costoAsiento = 0.0, // Inicialización del nuevo campo
  this.habitacion = '',    // Inicialización de habitación
  this.ticket = '',        // Inicialización de ticket
    required this.rawText,
  });

  /// Convierte el objeto ParsedReserva a un Map<String, dynamic>
  /// compatible con el método toFirestore de tu clase Reserva.
  Map<String, dynamic> toMap() {
    return {
      'nombreCliente': nombreCliente,
      'hotel': hotel,
      'fechaReserva': fecha?.toIso8601String(), // Clave ajustada a 'fechaReserva'
      'pax': pax,
      'saldo': saldo,
      'agenciaId': agenciaId,
      'observacion': observacion,
      'estado': estado.toString().split('.').last, // Convertir enum a String
      'telefono': telefono,
      'costoAsiento': costoAsiento, // Añadido el nuevo campo
    'habitacion': habitacion,     // Añadido habitación
    'ticket': ticket,             // Añadido ticket
    };
  }
}
