import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoReserva { pendiente, confirmada, cancelada }

class Reserva {
  final String id;
  final String nombreCliente;
  final String hotel;
  final int pax;
  final double saldo; //ES lo que la empresa a dadato de lo que debe
  final String observacion;
  final DateTime fecha; // es la fecha de la reserva
  final String agenciaId; // es el id de la agencia que hizo la reserva
  final EstadoReserva estado; // es el estado de la reserva (pendiente, confirmada, cancelada)
  final double costoAsiento; // es el costo por asiento de la reserva
  final String telefono;

  Reserva({
    required this.id,
    required this.nombreCliente,
    required this.hotel,
    required this.pax,
    required this.saldo,
    required this.observacion,
    required this.fecha,
    required this.agenciaId,
    required this.estado,
    required this.costoAsiento,
    required this.telefono,
  });

  //este constructor es para crear una reserva desde un mapa de datos
  //usado para leer datos de Firestore
  factory Reserva.fromFirestore(Map<String, dynamic> data, String id) {
    return Reserva(
      id: id,
      nombreCliente: data['nombreCliente'] as String? ?? '',
      hotel: data['hotel'] as String? ?? '',
      pax: (data['pax'] as num?)?.toInt() ?? 0,
      saldo: (data['saldo'] as num?)?.toDouble() ?? 0.0,
      observacion: data['observacion'] as String? ?? '',
      fecha: (data['fechaReserva'] as Timestamp).toDate(),
      agenciaId: data['agenciaId'] as String? ?? '',
      estado: _mapEstado(data['estado'] as String? ?? 'pendiente'),
      costoAsiento: (data['costoAsiento'] as num?)?.toDouble() ?? 0.0,
      telefono: data['telefono'] as String? ?? '',
    );
  }

  double get deuda => costoAsiento * pax - saldo;

  //este metodo convierte la reserva a un mapa de datos
  //usado para guardar datos en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombreCliente': nombreCliente,
      'hotel': hotel,
      'pax': pax,
      'saldo': saldo,
      'observacion': observacion,
      'fechaReserva': Timestamp.fromDate(fecha),
      'fechaRegistro': FieldValue.serverTimestamp(),
      'agenciaId': agenciaId,
      'estado': estado.toString().split('.').last,
      'costoAsiento': costoAsiento,
      'telefono': telefono,
    };
  }

  static EstadoReserva _mapEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return EstadoReserva.confirmada;
      case 'cancelada':
        return EstadoReserva.cancelada;
      default:
        return EstadoReserva.pendiente;
    }
  }

  // este metodo crea una copia de la reserva con los campos que se le pasen
  // se usa para actualizar los datos de la reserva
  // por ejemplo: reserva.copyWith(nombreCliente: 'Nuevo Nombre')
  Reserva copyWith({
    String? id,
    String? nombreCliente,
    String? hotel,
    int? pax,
    double? saldo,
    String? observacion,
    DateTime? fecha,
    String? agenciaId,
    EstadoReserva? estado,
    double? costoAsiento,
    String? telefono,
  }) {
    return Reserva(
      id: id ?? this.id,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      hotel: hotel ?? this.hotel,
      pax: pax ?? this.pax,
      saldo: saldo ?? this.saldo,
      observacion: observacion ?? this.observacion,
      fecha: fecha ?? this.fecha,
      agenciaId: agenciaId ?? this.agenciaId,
      estado: estado ?? this.estado,
      costoAsiento: costoAsiento ?? this.costoAsiento,
      telefono: telefono ?? this.telefono,
    );
  }
}

