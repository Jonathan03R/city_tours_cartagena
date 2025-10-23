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
  final String? contactoAgencia;
  final String? linkContactoAgencia;

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
    this.contactoAgencia,
    this.linkContactoAgencia,
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
      contactoAgencia: map['contacto_agencia'] as String?,
      linkContactoAgencia: map['link_contacto_agencia'] as String?,
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
    String? contactoAgencia,
    String? linkContactoAgencia,
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
      contactoAgencia: contactoAgencia ?? this.contactoAgencia,
      linkContactoAgencia: linkContactoAgencia ?? this.linkContactoAgencia,
    );
  }
}

class CrearAgenciaDTO {
  final String nombre;
  final String direccion;
  final int? tipoDocumentoCodigo;
  final String? beneficiario;
  final int tipoEmpresaCodigo;
  final String? logoUrl;
  final int creadoPor;
  final int operadorCodigo;
  final String? ipOrigen;

  CrearAgenciaDTO({
    required this.nombre,
    required this.direccion,
    this.tipoDocumentoCodigo,
    this.beneficiario,
    required this.tipoEmpresaCodigo,
    this.logoUrl,
    required this.creadoPor,
    required this.operadorCodigo,
    this.ipOrigen,
  });

  Map<String, dynamic> toMap() {
    return {
      'p_agencia_nombre': nombre,
      'p_agencia_direccion': direccion,
      'p_tipo_documento_codigo': tipoDocumentoCodigo,
      'p_agencia_beneficiario': beneficiario,
      'p_tipo_empresa_codigo': tipoEmpresaCodigo,
      'p_agencia_logo_url': logoUrl,
      'p_creado_por': creadoPor,
      'p_operador_codigo': operadorCodigo,
      'p_ip_origen': ipOrigen,
    };
  }

  CrearAgenciaDTO copyWith({
    String? logoUrl,
    String? ipOrigen,
  }) {
    return CrearAgenciaDTO(
      nombre: nombre,
      direccion: direccion,
      tipoDocumentoCodigo: tipoDocumentoCodigo,
      beneficiario: beneficiario,
      tipoEmpresaCodigo: tipoEmpresaCodigo,
      logoUrl: logoUrl ?? this.logoUrl,
      creadoPor: creadoPor,
      operadorCodigo: operadorCodigo,
      ipOrigen: ipOrigen ?? this.ipOrigen,
    );
  }
}
