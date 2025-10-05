class ReservaResumen {
  final int reservaCodigo;
  final String tipoServicioDescripcion;
  final String reservaPuntoEncuentro;
  final String reservaRepresentante;
  final DateTime reservaFecha;
  final int reservaPasajeros;
  final String? observaciones;
  final String agenciaNombre;
  final String? numeroTickete;
  final String? numeroHabitacion;
  final String estadoNombre;
  final String colorPrefijo;
  final double saldo;
  final double deuda;

  ReservaResumen({
    required this.reservaCodigo,
    required this.tipoServicioDescripcion,
    required this.reservaPuntoEncuentro,
    required this.reservaRepresentante,
    required this.reservaFecha,
    required this.reservaPasajeros,
    this.observaciones,
    required this.agenciaNombre,
    this.numeroTickete,
    this.numeroHabitacion,
    required this.estadoNombre,
    required this.colorPrefijo,
    required this.saldo,
    required this.deuda,
  });

  factory ReservaResumen.fromJson(Map<String, dynamic> json) {
    return ReservaResumen(
      reservaCodigo: json['reserva_codigo'] as int,
      tipoServicioDescripcion: json['tipo_servicio_descripcion'] as String,
      reservaPuntoEncuentro: json['reserva_punto_encuentro'] as String,
      reservaRepresentante: json['reserva_representante'] as String? ?? 'sin representante', 
      reservaFecha: DateTime.parse(json['reserva_fecha'] as String),
      reservaPasajeros: json['reserva_pasajeros'] as int,
      observaciones: json['observaciones'] as String?,
      agenciaNombre: json['agencia_nombre'] as String,
      numeroTickete: json['numero_tickete'] as String?,
      numeroHabitacion: json['numero_habitacion'] as String?,
      estadoNombre: json['estado_nombre'] as String,
      colorPrefijo: json['color_prefijo'] as String,
      saldo: double.tryParse(json['saldo'].toString()) ?? 0,
      deuda: double.tryParse(json['deuda'].toString()) ?? 0,
    );
  }
}