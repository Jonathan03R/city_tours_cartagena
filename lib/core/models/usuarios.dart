import 'package:citytourscartagena/core/models/roles.dart';

class Usuarios {
  String? id;
  String? usuario;
  String? nombre;
  String? email; // Opcional
  String? telefono; // Opcional
  String? agenciaId; // Opcional, si es un usuario de agencia
  List<String> roles;
  bool activo;

  Usuarios({
    this.id,
    this.usuario,
    this.nombre,
    this.email,
    this.telefono,
    this.agenciaId,
    List<String>? roles,
    this.activo = true,
  }) : roles = roles ?? [Roles.verReservas];

  Usuarios.fromJson(Map<String, dynamic> json)
    : roles =
          (json['rol'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [Roles.verReservas],
      activo = json['activo'] as bool? ?? true {
    id = json['id'];
    usuario = json['usuario'];
    nombre = json['nombre'];
    email = json['email'];
    telefono = json['telefono'];
    agenciaId = json['agencia'];
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
    data['agencia'] = agenciaId;
    return data;
  }

  Usuarios copyWith({
    String? usuario,
    String? nombre,
    String? email,
    String? telefono,
    String? agenciaId,
    List<String>? roles,
    bool? activo,
  }) {
    return Usuarios(
      id: this.id,
      usuario: usuario ?? this.usuario,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      agenciaId: agenciaId ?? this.agenciaId,
      roles: roles ?? this.roles,
      activo: activo ?? this.activo,
    );
  }

  Usuarios.fromMap(Map<String, dynamic> map)
    : id = map['id'] as String?,
      usuario = map['usuario'] as String?,
      nombre = map['nombre'] as String?,
      email = map['email'] as String?,
      telefono = map['telefono'] as String?,
      agenciaId = map['agencia'] as String?,
      roles =
          (map['rol'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [Roles.verReservas],
      activo = map['activo'] == true;
}
