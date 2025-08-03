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

  DateTime? lastSeenReservas;

  Usuarios({
    this.id,
    this.usuario,
    this.nombre,
    this.email,
    this.telefono,
    this.agenciaId,
    List<String>? roles,
    this.activo = true,
    this.lastSeenReservas,
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

    lastSeenReservas = json['lastSeenReservas'] != null
        ? (json['lastSeenReservas'] is DateTime
            ? json['lastSeenReservas']
            : (json['lastSeenReservas'] is String
                ? DateTime.tryParse(json['lastSeenReservas'])
                : (json['lastSeenReservas'] is int
                    ? DateTime.fromMillisecondsSinceEpoch(json['lastSeenReservas'])
                    : null)))
        : null;

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

    if (lastSeenReservas != null) {
      data['lastSeenReservas'] = lastSeenReservas!.toIso8601String();
    }

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
    DateTime? lastSeenReservas,
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
      lastSeenReservas: lastSeenReservas ?? this.lastSeenReservas,
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

      : id = map['id'] as String?,
        usuario = map['usuario'] as String?,
        nombre = map['nombre'] as String?,
        email = map['email'] as String?,
        telefono = map['telefono'] as String?,
        roles =
            (map['rol'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [Roles.verReservas],
        activo = map['activo'] == true,
        lastSeenReservas = map['lastSeenReservas'] != null
            ? (map['lastSeenReservas'] is DateTime
                ? map['lastSeenReservas']
                : (map['lastSeenReservas'] is String
                    ? DateTime.tryParse(map['lastSeenReservas'])
                    : (map['lastSeenReservas'] is int
                        ? DateTime.fromMillisecondsSinceEpoch(map['lastSeenReservas'])
                        : null)))
            : null;

}
