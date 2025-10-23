class CrearReservaDto {
  final DateTime reservaFecha;
  final String? numeroHabitacion;
  final String? puntoEncuentro;
  final String? observaciones;
  final int pasajeros;
  final int tipoServicioCodigo;
  final int agenciaCodigo;
  final int operadorCodigo;
  final int creadoPor;
  final String? representante;
  final String? numeroTickete;
  final double pagoMonto;
  final double? reservaTotal;
  final int colorCodigo;

  CrearReservaDto({
    required this.reservaFecha,
    this.numeroHabitacion,
    this.puntoEncuentro,
    this.observaciones,
    required this.pasajeros,
    required this.tipoServicioCodigo,
    required this.agenciaCodigo,
    required this.operadorCodigo,
    required this.creadoPor,
    this.representante,
    this.numeroTickete,
    required this.pagoMonto,
    this.reservaTotal,
    this.colorCodigo = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'p_reserva_fecha': reservaFecha.toIso8601String(),
      'p_reserva_numero_habitacion': numeroHabitacion,
      'p_reserva_punto_encuentro': puntoEncuentro,
      'p_reserva_observaciones': observaciones,
      'p_reserva_pasajeros': pasajeros,
      'p_tipo_servicio_codigo': tipoServicioCodigo,
      'p_agencia_codigo': agenciaCodigo,
      'p_operador_codigo': operadorCodigo,
      'p_reserva_creado_por': creadoPor,
      'p_reserva_representante': representante,
      'p_numero_tickete': numeroTickete,
      'p_pago_monto': pagoMonto,
      'p_reserva_total': reservaTotal,
      'p_color_codigo': colorCodigo,
    };
  }
}