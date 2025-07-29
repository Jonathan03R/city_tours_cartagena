import 'package:citytourscartagena/core/models/roles.dart';

class Usuarios {
  String? id;
  String? usuario;
  String? nombre;
  String? email;
  String? telefono;
  List<String> roles;

  Usuarios({
    this.id,
    this.usuario,
    this.nombre,
    this.email,
    this.telefono,
    List<String>? roles,
  }) : roles = roles ?? [Roles.colaborador];

  Usuarios.fromJson(Map<String, dynamic> json)
    : roles =
          (json['rol'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [Roles.colaborador] {
    id = json['id'];
    usuario = json['usuario'];
    nombre = json['nombre'];
    email = json['email'];
    telefono = json['telefono'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['usuario'] = usuario;
    data['nombre'] = nombre;
    data['email'] = email;
    data['telefono'] = telefono;
    data['rol'] = roles;
    return data;
  }

  /// este es el fromMap

  Usuarios.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      usuario = map['usuario'],
      nombre = map['nombre'],
      email = map['email'],
      telefono = map['telefono'],
      roles =
          (map['rol'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [Roles.colaborador];
}
