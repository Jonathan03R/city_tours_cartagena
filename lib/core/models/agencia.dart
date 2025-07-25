class Agencia {
  final String id;
  final String nombre;
  final String? imagenUrl;
  final bool eliminada;
  final double? precioPorAsiento;

  Agencia({
    required this.id,
    required this.nombre,
    this.imagenUrl,
    this.eliminada = false,
    this.precioPorAsiento,
  });

  // Añadir el método copyWith para facilitar la creación de nuevas instancias con ID
  Agencia copyWith({
    String? id,
    String? nombre,
    String? imagenUrl,
    bool? eliminada,
    double? precioPorAsiento,
  }) {
    return Agencia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      eliminada: eliminada ?? this.eliminada,
      precioPorAsiento: precioPorAsiento ?? this.precioPorAsiento,
    );
  }

  factory Agencia.fromFirestore(Map<String, dynamic> data, String id) {
    return Agencia(
      id: id,
      nombre: data['nombre'] ?? '',
      imagenUrl: data['imagenUrl'],
      eliminada: data['eliminada'] ?? false,
      precioPorAsiento: (data['precioPorAsiento'] is num) ? data['precioPorAsiento'].toDouble() : null, // NUEVO
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'imagenUrl': imagenUrl,
      'eliminada': eliminada,
      'fechaRegistro': DateTime.now().toIso8601String(),
      'precioPorAsiento': precioPorAsiento,
    };
  }
}

class AgenciaConReservas {
  final Agencia agencia;
  final int totalReservas;

  AgenciaConReservas({
    required this.agencia,
    required this.totalReservas,
  });

  // Exponer propiedades de la Agencia interna para conveniencia
  String get id => agencia.id;
  String get nombre => agencia.nombre;
  String? get imagenUrl => agencia.imagenUrl;
  bool get eliminada => agencia.eliminada;
  double? get precioPorAsiento => agencia.precioPorAsiento;
}
