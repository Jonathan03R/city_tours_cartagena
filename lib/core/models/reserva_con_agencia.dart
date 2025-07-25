// Este archivo debe contener la definición de ReservaConAgencia.
// Ya no extiende Agencia, sino que la contiene.
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';

class ReservaConAgencia {
  final Reserva reserva;
  final Agencia agencia;

  ReservaConAgencia({
    required this.reserva,
    required this.agencia,
  });

  // Exponer propiedades de la Reserva y Agencia internas para conveniencia
  String get id => reserva.id;
  String get nombreCliente => reserva.nombreCliente;
  String get telefono => reserva.telefono;
  String get hotel => reserva.hotel;
  EstadoReserva get estado => reserva.estado;
  DateTime get fecha => reserva.fecha;
  int get pax => reserva.pax;
  double get saldo => reserva.saldo;
  String get agenciaId => reserva.agenciaId;
  String get observacion => reserva.observacion;
  String get nombreAgencia => agencia.nombre;
  double get costoAsiento => reserva.costoAsiento;
  double get deuda => reserva.deuda;
  bool get whatsappContactado => reserva.whatsappContactado;
}

// También puedes definir AgenciaConReservas aquí, ya que es un DTO combinado.
// O en un archivo separado si prefieres, pero aquí tiene sentido.
class AgenciaConReservas {
  final Agencia agencia;
  final int totalReservas;

  AgenciaConReservas({
    required this.agencia,
    required this.totalReservas,
  });

  // Exponer propiedades de la Agencia interna para conveniencia
  String get id => agencia.id;
  String get nombre => agencia.nombre;
  String? get imagenUrl => agencia.imagenUrl;
  bool get eliminada => agencia.eliminada;
}
