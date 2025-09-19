class Usuario {
  final String id;
  final String email;
  final String? nombre;
  final List<String> roles;
  final bool activo;

  Usuario({
    required this.id,
    required this.email,
    this.nombre,
    this.roles = const [],
    this.activo = true,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      id: map['id'] as String,
      email: map['email'] as String,
      nombre: map['nombre'] as String?,
      roles: List<String>.from(map['roles'] ?? []),
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'roles': roles,
      // 'activo': activo,
    };
  }
}
