import 'package:citytourscartagena/core/models/roles.dart';

class Usuarios {
  String? id;
  String? usuario;
  String? nombre;
  String? email; // Opcional
  String? telefono; // Opcional
  List<String> roles;
  bool activo;

  Usuarios({
    this.id,
    this.usuario,
    this.nombre,
    this.email,
    this.telefono,
    List<String>? roles,
    this.activo = true,
  }) : roles = roles ?? [Roles.colaborador];

  Usuarios.fromJson(Map<String, dynamic> json)
    : roles =
          (json['rol'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [Roles.colaborador],
      activo = json['activo'] as bool? ?? true {
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
    data['activo'] = activo;
    return data;
  }

  Usuarios.fromMap(Map<String, dynamic> map)
    : id       = map['id']       as String?,
      usuario  = map['usuario']  as String?,
      nombre   = map['nombre']   as String?,
      email    = map['email']    as String?,
      telefono = map['telefono'] as String?,
      roles    = (map['rol'] as List<dynamic>?)
                     ?.map((e) => e.toString())
                     .toList() ?? [Roles.colaborador],
      activo   = map['activo'] == true;   
}
