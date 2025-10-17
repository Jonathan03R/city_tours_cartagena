class Persona {
  final String nombre;
  final String apellido;
  final String email;

  Persona({required this.nombre, required this.apellido, required this.email});

  factory Persona.fromMap(Map<String, dynamic> map) {
    return Persona(
      nombre: map['persona_nombre'] as String,
      apellido: map['persona_apellido'] as String,
      email: map['persona_email'] as String,
    );
  }
}
