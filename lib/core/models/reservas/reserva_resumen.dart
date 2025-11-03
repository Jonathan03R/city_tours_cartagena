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
  final String colorNombre;
  final double saldo;
  final double deuda;
  final List<Map<String, dynamic>> contactos;

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
    required this.colorNombre,
    required this.saldo,
    required this.deuda,
    required this.contactos,
  });

  factory ReservaResumen.fromJson(Map<String, dynamic> json) {
    return ReservaResumen(
      reservaCodigo: json['reserva_codigo'] as int,
      tipoServicioDescripcion: json['tipo_servicio_descripcion'] as String,
      reservaPuntoEncuentro: (json['reserva_punto_encuentro'] as String?) ?? '',
      reservaRepresentante: json['reserva_representante'] as String? ?? 'sin representante', 
      reservaFecha: DateTime.parse(json['reserva_fecha'] as String),
      reservaPasajeros: json['reserva_pasajeros'] as int,
      observaciones: json['reserva_observaciones'] as String?,
      agenciaNombre: json['agencia_nombre'] as String,
      numeroTickete: json['numero_tickete'] as String?,
      numeroHabitacion: json['numero_habitacion'] as String?,
      estadoNombre: json['estado_nombre'] as String,
      colorPrefijo: json['color_prefijo'] as String,
      colorNombre: json['color_nombre'] as String,
      saldo: double.tryParse(json['saldo'].toString()) ?? 0,
      deuda: double.tryParse(json['deuda'].toString()) ?? 0,
      contactos: (json['contactos'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [],
    );
  }

  ReservaResumen copyWith({
    int? reservaCodigo,
    String? tipoServicioDescripcion,
    String? reservaPuntoEncuentro,
    String? reservaRepresentante,
    DateTime? reservaFecha,
    int? reservaPasajeros,
    String? observaciones,
    String? agenciaNombre,
    String? numeroTickete,
    String? numeroHabitacion,
    String? estadoNombre,
    String? colorPrefijo,
    String? colorNombre,
    double? saldo,
    double? deuda,
    List<Map<String, dynamic>>? contactos,
  }) {
    return ReservaResumen(
      reservaCodigo: reservaCodigo ?? this.reservaCodigo,
      tipoServicioDescripcion: tipoServicioDescripcion ?? this.tipoServicioDescripcion,
      reservaPuntoEncuentro: reservaPuntoEncuentro ?? this.reservaPuntoEncuentro,
      reservaRepresentante: reservaRepresentante ?? this.reservaRepresentante,
      reservaFecha: reservaFecha ?? this.reservaFecha,
      reservaPasajeros: reservaPasajeros ?? this.reservaPasajeros,
      observaciones: observaciones ?? this.observaciones,
      agenciaNombre: agenciaNombre ?? this.agenciaNombre,
      numeroTickete: numeroTickete ?? this.numeroTickete,
      numeroHabitacion: numeroHabitacion ?? this.numeroHabitacion,
      estadoNombre: estadoNombre ?? this.estadoNombre,
      colorPrefijo: colorPrefijo ?? this.colorPrefijo,
      colorNombre: colorNombre ?? this.colorNombre,
      saldo: saldo ?? this.saldo,
      deuda: deuda ?? this.deuda,
      contactos: contactos ?? this.contactos,
    );
  }
}