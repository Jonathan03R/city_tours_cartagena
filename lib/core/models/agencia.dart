class Agencia {
  final String id;
  final String nombre;
  final String? imagenUrl;

  Agencia({
    required this.id,
    required this.nombre,
    this.imagenUrl,
  });

  factory Agencia.fromFirestore(Map<String, dynamic> data, String id) {
    return Agencia(
      id: id,
      nombre: data['nombre'] ?? '',
      imagenUrl: data['imagenUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'imagenUrl': imagenUrl,
      'fechaRegistro': DateTime.now().toIso8601String(),
    };
  }
}


class AgenciaConReservas extends Agencia {
  final int totalReservas;

  AgenciaConReservas({
    required super.id,
    required super.nombre,
    required super.imagenUrl, // 👈 agregar esto
    required this.totalReservas,
  });
}
