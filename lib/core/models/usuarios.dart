import 'package:citytourscartagena/core/models/roles.dart';

class Usuarios {
  String? id;
  String? nombre;
  String? email;
  String? telefono;
  List<String> roles;
  
  Usuarios({this.id, this.nombre, this.email, this.telefono , List<String>? roles})
      : roles = roles ?? [Roles.colaborador]; 

  Usuarios.fromJson(Map<String, dynamic> json)
      : roles = (json['rol'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [Roles.colaborador] {
    id = json['id'];
    nombre = json['nombre'];
    email = json['email'];
    telefono = json['telefono'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nombre'] = nombre;
    data['email'] = email;
    data['telefono'] = telefono;
    data['rol'] = roles;
    return data;
  }
}
