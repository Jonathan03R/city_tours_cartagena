class Usuarios {
  String? id;
  String? nombre;
  String? email;
  String? telefono;
  String? fotoUrl;

  Usuarios({this.id, this.nombre, this.email, this.telefono, this.fotoUrl});

  Usuarios.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nombre = json['nombre'];
    email = json['email'];
    telefono = json['telefono'];
    fotoUrl = json['fotoUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nombre'] = nombre;
    data['email'] = email;
    data['telefono'] = telefono;
    data['fotoUrl'] = fotoUrl;
    return data;
  }
}
