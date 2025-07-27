class Configuracion {
  final double precioGeneralAsientoTarde;
  final double precioGeneralAsientoTemprano;
  final DateTime actualizadoEn;

  Configuracion({
    required this.precioGeneralAsientoTarde,
    required this.precioGeneralAsientoTemprano,
    required this.actualizadoEn,
  });

  factory Configuracion.fromMap(Map<String, dynamic> data) {
    // ARREGLADO: Leer correctamente los campos separados
    final precioTarde = data['precio_general_asiento_tarde'];
    final precioTemprano = data['precio_general_asiento_temprano'];
    
    // Solo usar precio_por_asiento como fallback si los nuevos no existen
    final precioFallback = data['precio_por_asiento'] ?? 0.0;

    return Configuracion(
      precioGeneralAsientoTarde: (precioTarde is num) 
          ? precioTarde.toDouble() 
          : (precioFallback is num ? precioFallback.toDouble() : 0.0),
      precioGeneralAsientoTemprano: (precioTemprano is num) 
          ? precioTemprano.toDouble() 
          : (precioFallback is num ? precioFallback.toDouble() : 0.0),
      actualizadoEn: DateTime.parse(
        data['actualizado_en'] ?? DateTime.now().toIso8601String()
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'precio_general_asiento_tarde': precioGeneralAsientoTarde,
      'precio_general_asiento_temprano': precioGeneralAsientoTemprano,
      'actualizado_en': actualizadoEn.toIso8601String(),
    };
  }

  double precioParaTurno(String turno) {
    if (turno == 'manana') {
      return precioGeneralAsientoTemprano;
    } else if (turno == 'tarde') {
      return precioGeneralAsientoTarde;
    }
    return precioGeneralAsientoTemprano;
  }
}
