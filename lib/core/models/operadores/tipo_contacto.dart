class TipoContacto {
  final int id;
  final String descripcion;
  final bool activo;

  TipoContacto({
    required this.id,
    required this.descripcion,
    required this.activo,
  });

  factory TipoContacto.fromMap(Map<String, dynamic> map) {
    return TipoContacto(
      id: map['tipo_contacto_codigo'] as int,
      descripcion: map['tipo_contacto_descripcion'] as String,
      activo: map['tipo_contacto_activo'] as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo_contacto_codigo': id,
      'tipo_contacto_descripcion': descripcion,
      'tipo_contacto_activo': activo,
    };
  }
}