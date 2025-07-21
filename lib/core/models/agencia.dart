class Agencia {
  final String id;
  final String nombre;

  Agencia({
    required this.id,
    required this.nombre,
  });

  factory Agencia.fromFirestore(Map<String, dynamic> data, String id) {
    return Agencia(
      id: id,
      nombre: data['nombre'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'fechaRegistro': DateTime.now().toIso8601String(),
    };
  }
}

class AgenciaConReservas extends Agencia {
  final int totalReservas;

  AgenciaConReservas({
    required super.id,
    required super.nombre,
    required this.totalReservas,
  });
}
