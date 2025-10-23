class TipoDocumento {
  final int codigo;
  final String nombre;
  final String prefijo;
  final bool activo;

  TipoDocumento({
    required this.codigo,
    required this.nombre,
    required this.prefijo,
    required this.activo,
  });

  factory TipoDocumento.fromMap(Map<String, dynamic> map) {
    return TipoDocumento(
      codigo: map['tipo_documento_codigo'],
      nombre: map['tipo_documento_nombre'],
      prefijo: map['tipo_documento_prefijo'],
      activo: map['tipo_documento_activo'],
    );
  }
}
