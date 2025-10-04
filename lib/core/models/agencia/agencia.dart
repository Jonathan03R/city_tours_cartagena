class AgenciaSupabase {
  final int codigo;
  final String nombre;
  final String? direccion;
  final int? tipoDocumento;
  final String? representante;
  final int tipoEmpresa;
  final String? logoUrl;
  final String? documento;
  final bool activo;
  final double deuda;
  final int totalPasajeros;
  final int totalReservas;

  AgenciaSupabase({
    required this.codigo,
    required this.nombre,
    this.direccion,
    this.tipoDocumento,
    this.representante,
    required this.tipoEmpresa,
    this.logoUrl,
    required this.activo,
    this.documento,
    required this.deuda,
    required this.totalPasajeros,
    required this.totalReservas,
  });

  factory AgenciaSupabase.fromMap(Map<String, dynamic> map) {
    return AgenciaSupabase(
      codigo: map['agencia_codigo'],
      nombre: map['agencia_nombre'],
      direccion: map['agencia_direccion'],
      tipoDocumento: map['tipo_documento_codigo'],
      representante: map['agencia_beneficiario'],
      tipoEmpresa: map['tipo_empresa_codigo'],
      logoUrl: map['agencia_logo_url'],
      documento: map['agencia_documento'],
      activo: map['agencia_activo'],
      deuda: 0.0,
      totalPasajeros: 0,
      totalReservas: 0,
    );
  }

  AgenciaSupabase copyWith({
    int? codigo,
    String? nombre,
    String? direccion,
    int? tipoDocumento,
    String? representante,
    int? tipoEmpresa,
    String? logoUrl,
    String? documento,
    bool? activo,
    double? deuda,
    int? totalPasajeros,
    int? totalReservas,
  }) {
    return AgenciaSupabase(
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      direccion: direccion ?? this.direccion,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      representante: representante ?? this.representante,
      tipoEmpresa: tipoEmpresa ?? this.tipoEmpresa,
      logoUrl: logoUrl ?? this.logoUrl,
      documento: documento ?? this.documento,
      activo: activo ?? this.activo,
      deuda: deuda ?? this.deuda,
      totalPasajeros: totalPasajeros ?? this.totalPasajeros,
      totalReservas: totalReservas ?? this.totalReservas,
    );
  }
}
