import 'package:citytourscartagena/core/models/enum/tipo_documento.dart';

class Configuracion {
  final double precioGeneralAsientoTarde;
  final double precioGeneralAsientoTemprano;
  final DateTime actualizadoEn;

  final TipoDocumento tipoDocumento;
  final String? numeroDocumento;
  final String? nombreBeneficiario;

  final String nombreEmpresa;
  final int maxCuposTurnoManana; 
  final int maxCuposTurnoTarde;

  final String? contact_whatsapp;
  final bool? cuposCerradas;

  Configuracion({
    required this.precioGeneralAsientoTarde,
    required this.precioGeneralAsientoTemprano,
    required this.actualizadoEn,
    required this.tipoDocumento,
    required this.numeroDocumento,
    this.nombreBeneficiario,
    required this.nombreEmpresa,
    required this.maxCuposTurnoManana, // Valor por defecto
    required this.maxCuposTurnoTarde,
    this.contact_whatsapp,
    this.cuposCerradas,
  });

  factory Configuracion.fromMap(Map<String, dynamic> data) {
    // ARREGLADO: Leer correctamente los campos separados
    final precioTarde = data['precio_general_asiento_tarde'];
    final precioTemprano = data['precio_general_asiento_temprano'];

    // Solo usar precio_por_asiento como fallback si los nuevos no existen
    final precioFallback = data['precio_por_asiento'] ?? 0.0;

    return Configuracion(
      precioGeneralAsientoTarde: (precioTarde is num) ? precioTarde.toDouble() : (precioFallback is num ? precioFallback.toDouble() : 0.0),
      precioGeneralAsientoTemprano: (precioTemprano is num) ? precioTemprano.toDouble() : (precioFallback is num ? precioFallback.toDouble() : 0.0),
      actualizadoEn: DateTime.parse(data['actualizado_en'] ?? DateTime.now().toIso8601String(),),
      tipoDocumento: TipoDocumento.values.firstWhere((e) => e.toString() == 'TipoDocumento.${data['tipo_documento']}',
        orElse: () => TipoDocumento.cc,
      ),
      numeroDocumento: data['numero_documento'],
      nombreBeneficiario: data['nombre_beneficiario'],
      nombreEmpresa: data['nombre_empresa'],
      maxCuposTurnoManana: _parseMaxCupos(data['max_cupos_turno_manana']),
      maxCuposTurnoTarde: _parseMaxCupos(data['max_cupos_turno_tarde']),
      contact_whatsapp: data['contact_whatsapp'],
      cuposCerradas: data['cuposCerradas'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'precio_general_asiento_tarde': precioGeneralAsientoTarde,
      'precio_general_asiento_temprano': precioGeneralAsientoTemprano,
      'actualizado_en': actualizadoEn.toIso8601String(),

      'tipo_documento': tipoDocumento.toString().split('.').last,
      'numero_documento': numeroDocumento,
      'nombre_beneficiario': nombreBeneficiario,
      'nombre_empresa': nombreEmpresa,
      'max_cupos_turno_manana': maxCuposTurnoManana,
      'max_cupos_turno_tarde': maxCuposTurnoTarde,
      'contact_whatsapp': contact_whatsapp,
      'cuposCerradas': cuposCerradas,
    };
  }

  /// Retorna el precio del asiento según el turno
  double precioParaTurno(String turno) {
    if (turno == 'manana') {
      return precioGeneralAsientoTemprano;
    } else if (turno == 'tarde') {
      return precioGeneralAsientoTarde;
    }
    return precioGeneralAsientoTemprano;
  }
  /// Parsea el valor de max cupos de forma robusta
  static int _parseMaxCupos(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw ArgumentError('El valor de max_cupos_turno es inválido o nulo: $value');
  }
}
