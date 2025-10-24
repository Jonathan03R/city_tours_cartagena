import 'package:citytourscartagena/core/models/tipos/tipo_contacto.dart';

class ContactoAgencia {
  final int codigo;
  final int tipoContactoCodigo;
  final String descripcion;
  final int agenciaCodigo;
  final TipoContacto tipoContacto;

  ContactoAgencia({
    required this.codigo,
    required this.tipoContactoCodigo,
    required this.descripcion,
    required this.agenciaCodigo,
    required this.tipoContacto,
  });

  factory ContactoAgencia.fromMap(Map<String, dynamic> map) {
    return ContactoAgencia(
      codigo: map['contacto_agencia_codigo'],
      tipoContactoCodigo: map['tipo_contacto_codigo'],
      descripcion: map['contacto_agencia_descripcion'],
      agenciaCodigo: map['agencia_codigo'],
      tipoContacto: TipoContacto.fromMap(map['tipos_contactos']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contacto_agencia_codigo': codigo,
      'tipo_contacto_codigo': tipoContactoCodigo,
      'contacto_agencia_descripcion': descripcion,
      'agencia_codigo': agenciaCodigo,
    };
  }
}