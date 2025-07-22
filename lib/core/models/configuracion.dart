class Configuracion {
  final double precioPorAsiento;
  final DateTime actualizadoEn;

  Configuracion({
    required this.precioPorAsiento,
    required this.actualizadoEn,
  });

  factory Configuracion.fromMap(Map<String, dynamic> data) {
    final precioRaw = data['precio_por_asiento'];
    final precio = (precioRaw is num)
      ? precioRaw.toDouble()
      : double.tryParse(precioRaw.toString()) ?? 0.0;

    return Configuracion(
      precioPorAsiento: precio,
      actualizadoEn: DateTime.parse(data['actualizado_en']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'precio_por_asiento': precioPorAsiento,
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }
}
