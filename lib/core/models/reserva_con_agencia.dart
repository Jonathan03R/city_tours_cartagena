import 'agencia.dart';
import 'reserva.dart';

class ReservaConAgencia {
  final Reserva reserva;
  final Agencia agencia;

  ReservaConAgencia({
    required this.reserva,
    required this.agencia,
  });

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
}
