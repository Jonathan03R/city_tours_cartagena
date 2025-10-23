class ContactoOperador {
  final int id;
  final int tipoContactoCodigo;
  final String descripcion;
  final int operadorCodigo;

  ContactoOperador({
    required this.id,
    required this.tipoContactoCodigo,
    required this.descripcion,
    required this.operadorCodigo,
  });

  factory ContactoOperador.fromMap(Map<String, dynamic> map) {
    return ContactoOperador(
      id: map['contacto_operador_codigo'] as int,
      tipoContactoCodigo: map['tipo_contacto_codigo'] as int,
      descripcion: map['contacto_operador_descripcion'] as String,
      operadorCodigo: map['operador_codigo'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contacto_operador_codigo': id,
      'tipo_contacto_codigo': tipoContactoCodigo,
      'contacto_operador_descripcion': descripcion,
      'operador_codigo': operadorCodigo,
    };
  }
}