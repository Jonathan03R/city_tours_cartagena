class PrecioServicio {
  final int codigo;
  final double precio;
  final String descripcion;
  final String origen; 

  PrecioServicio({
    required this.codigo,
    required this.precio,
    required this.descripcion,
    required this.origen,
  });

  factory PrecioServicio.fromMap(Map<String, dynamic> map) {
    return PrecioServicio(
      codigo: map['codigo'] is int ? map['codigo'] : int.tryParse(map['codigo'].toString()) ?? 0,
      precio: map['precio'] is double ? map['precio'] : double.tryParse(map['precio'].toString()) ?? 0.0,
      descripcion: map['descripcion'] ?? '',
      origen: map['origen'] ?? '',
    );
  }
}