class Entidad {
  final String nombreCliente;

  Entidad({required this.nombreCliente});

  factory Entidad.fromMap(Map<String, dynamic> map) {
    return Entidad(
      nombreCliente: map['nombre_cliente_agencia'] as String,
    );
  }
}
