import 'package:citytourscartagena/core/models/perfil/persona.dart';
import 'package:citytourscartagena/core/models/perfil/usuario.dart';

class Perfil {
  final Usuario usuario;
  final Persona? persona;
  final Map<String, dynamic>? entidad;
  final Map<String, dynamic>? rol;

  Perfil({
    required this.usuario,
    this.persona,
    this.entidad,
    this.rol,
  });

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      usuario: Usuario.fromMap(Map<String, dynamic>.from(map['usuario'] ?? {})),
      persona: map['persona'] is Map ? Persona.fromMap(Map<String, dynamic>.from(map['persona'])) : null,
      entidad: map['entidad'] is Map ? Map<String, dynamic>.from(map['entidad']) : null,
      rol: map['rol'] is Map ? Map<String, dynamic>.from(map['rol']) : null,
    );
  }
}