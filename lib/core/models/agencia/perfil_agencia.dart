class Agenciaperfil {
  final int codigo;
  final String nombre;
  final String? direccion;
  final int? tipoDocumento;
  final String? tipoDocumentoNombre;
  final String? representante;
  final int tipoEmpresa;
  final String? logoUrl;
  final String? documento;
  final bool activo;

  Agenciaperfil({
    required this.codigo,
    required this.nombre,
    this.direccion,
    this.tipoDocumento,
    this.tipoDocumentoNombre,
    this.representante,
    required this.tipoEmpresa,
    this.logoUrl,
    this.documento,
    required this.activo,
  });

  factory Agenciaperfil.fromMap(Map<String, dynamic> map) {
    return Agenciaperfil(
      codigo: map['agencia_codigo'],
      nombre: map['agencia_nombre'],
      direccion: map['agencia_direccion'],
      tipoDocumento: map['tipo_documento_codigo'],
      tipoDocumentoNombre: map['tipos_documentos']?['tipo_documento_nombre'],
      representante: map['agencia_beneficiario'],
      tipoEmpresa: map['tipo_empresa_codigo'],
      logoUrl: map['agencia_logo_url'],
      documento: map['agencia_documento'],
      activo: map['agencia_activo'],
    );
  }
}
