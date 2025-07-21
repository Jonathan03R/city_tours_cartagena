import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoReserva { pendiente, confirmada, cancelada }

class Reserva {
  final String id;
  final String nombreCliente;
  final String hotel;
  final int pax;
  final double saldo;
  final String observacion;
  final DateTime fecha;
  final String agenciaId;
  final EstadoReserva estado;

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
  });

  factory Reserva.fromFirestore(Map<String, dynamic> data, String id) {
    return Reserva(
      id: id,
      nombreCliente: data['nombreCliente'] as String? ?? '',
      hotel:         data['hotel']         as String? ?? '',
      pax:           (data['pax'] as num?)?.toInt() ?? 0,
      saldo:         (data['saldo'] as num?)?.toDouble() ?? 0.0,
      observacion:   data['observacion']   as String? ?? '',
      fecha:         (data['fechaReserva'] as Timestamp).toDate(),
      agenciaId:     data['agenciaId']     as String? ?? '',
      estado:        _mapEstado(data['estado'] as String? ?? 'pendiente'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombreCliente': nombreCliente,
      'hotel':         hotel,
      'pax':           pax,
      'saldo':         saldo,
      'observacion':   observacion,
      'fechaReserva':  Timestamp.fromDate(fecha),
      'fechaRegistro': FieldValue.serverTimestamp(),
      'agenciaId':     agenciaId,
      'estado':        estado.toString().split('.').last,
    };
  }

  static EstadoReserva _mapEstado(String estado) {
    switch (estado) {
      case 'confirmada': return EstadoReserva.confirmada;
      case 'cancelada':  return EstadoReserva.cancelada;
      default:           return EstadoReserva.pendiente;
    }
  }


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
  }) {
    return Reserva(
      id:            id            ?? this.id,
      nombreCliente: nombreCliente ?? this.nombreCliente,
      hotel:         hotel         ?? this.hotel,
      pax:           pax           ?? this.pax,
      saldo:         saldo         ?? this.saldo,
      observacion:   observacion   ?? this.observacion,
      fecha:         fecha         ?? this.fecha,
      agenciaId:     agenciaId     ?? this.agenciaId,
      estado:        estado        ?? this.estado,
    );
  }
}