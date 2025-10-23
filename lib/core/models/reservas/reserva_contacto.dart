class ReservaContacto {
  final int tipoContactoCodigo;
  final String contacto;

  ReservaContacto({
    required this.tipoContactoCodigo,
    required this.contacto,
  });

  Map<String, dynamic> toJson() {
    return {
      'tipo_contacto_codigo': tipoContactoCodigo,
      'contacto': contacto,
    };
  }

  factory ReservaContacto.fromJson(Map<String, dynamic> json) {
    return ReservaContacto(
      tipoContactoCodigo: json['tipo_contacto_codigo'] as int,
      contacto: json['contacto'] as String,
    );
  }
}