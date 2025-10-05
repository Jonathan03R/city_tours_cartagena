class TipoServicio {
  final int codigo;
  final String descripcion;

  TipoServicio({
    required this.codigo,
    required this.descripcion,
  });

  factory TipoServicio.fromMap(Map<String, dynamic> map) {
    return TipoServicio(
      codigo: map['tipo_servicio_codigo'] as int,
      descripcion: map['tipo_servicio_descripcion'] as String,
    );
  }
}
