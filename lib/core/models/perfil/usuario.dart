class Usuario {
  final int codigo;
  final String alias;
  final String tipoUsuario;
  final String uidUsuario;
  final bool activo;

  Usuario({
    required this.codigo,
    required this.alias,
    required this.tipoUsuario,
    required this.uidUsuario,
    required this.activo,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      codigo: map['usuario_codigo'] as int,
      alias: map['usuario_alias'] as String,
      tipoUsuario: map['tipo_usuario'] as String,
      uidUsuario: map['usuario_password_encriptado'] as String,
      activo: map['usuario_activo'] as bool,
    );
  }
}
