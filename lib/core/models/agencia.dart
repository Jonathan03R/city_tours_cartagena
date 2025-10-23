import 'package:citytourscartagena/core/models/enum/tipo_documento.dart';

class Agencia {
  final String id;
  final String nombre;
  final String? imagenUrl;
  final bool eliminada;
  // final double? precioPorAsiento;
  final double? precioPorAsientoTurnoManana;
  final double? precioPorAsientoTurnoTarde;

  final TipoDocumento? tipoDocumento;
  final String? numeroDocumento;
  final String? nombreBeneficiario;
  final String? contactoAgencia;
  final String? linkContactoAgencia;

  Agencia({
    required this.id,
    required this.nombre,
    this.imagenUrl,
    this.eliminada = false,
    // this.precioPorAsiento,
    this.precioPorAsientoTurnoManana,
    this.precioPorAsientoTurnoTarde,
    this.tipoDocumento,
    this.numeroDocumento,
    this.nombreBeneficiario,
    this.contactoAgencia,
    this.linkContactoAgencia,
  });

  // Añadir el método copyWith para facilitar la creación de nuevas instancias con ID
  Agencia copyWith({
    String? id,
    String? nombre,
    String? imagenUrl,
    bool? eliminada,
    // double? precioPorAsiento,
    double? precioPorAsientoTurnoManana,
    double? precioPorAsientoTurnoTarde,
    TipoDocumento? tipoDocumento,
    String? numeroDocumento,
    String? nombreBeneficiario,
    String? contactoAgencia,
    String? linkContactoAgencia,
  }) {
    return Agencia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      eliminada: eliminada ?? this.eliminada,
      precioPorAsientoTurnoManana:
          precioPorAsientoTurnoManana ?? this.precioPorAsientoTurnoManana,
      precioPorAsientoTurnoTarde:
          precioPorAsientoTurnoTarde ?? this.precioPorAsientoTurnoTarde,

      // precioPorAsiento: precioPorAsiento ?? this.precioPorAsiento,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      nombreBeneficiario: nombreBeneficiario ?? this.nombreBeneficiario,
      contactoAgencia: contactoAgencia ?? this.contactoAgencia,
      linkContactoAgencia: linkContactoAgencia ?? this.linkContactoAgencia,
    );
  }

  factory Agencia.fromFirestore(Map<String, dynamic> data, String id) {
    return Agencia(
      id: id,
      nombre: data['nombre'] ?? '',
      imagenUrl: data['imagenUrl'],
      eliminada: data['eliminada'] ?? false,
      // precioPorAsiento: (data['precioPorAsiento'] is num) ? data['precioPorAsiento'].toDouble() : null, // NUEVO
      precioPorAsientoTurnoManana: (data['precioPorAsientoTurnoManana'] is num)
          ? data['precioPorAsientoTurnoManana'].toDouble()
          : null,
      precioPorAsientoTurnoTarde: (data['precioPorAsientoTurnoTarde'] is num)
          ? data['precioPorAsientoTurnoTarde'].toDouble()
          : null,

      tipoDocumento: data['tipoDocumento'] != null
          ? TipoDocumento.values.firstWhere(
              (e) => e.name == data['tipoDocumento'],
              orElse: () => TipoDocumento.cc,
            )
          : null,
      numeroDocumento: data['numeroDocumento'],
      nombreBeneficiario: data['nombreBeneficiario'],
      contactoAgencia: data['contactoAgencia'],
      linkContactoAgencia: data['linkContactoAgencia'],
    );
  }

  ///esto me sirve para guardar en Firestore
  ///para que no se confunda con el de la agencia
  ///que es el que se usa para mostrar en la pantalla
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'imagenUrl': imagenUrl,
      'eliminada': eliminada,
      'fechaRegistro': DateTime.now().toIso8601String(),
      // 'precioPorAsiento': precioPorAsiento,
      'precioPorAsientoTurnoManana': precioPorAsientoTurnoManana,
      'precioPorAsientoTurnoTarde': precioPorAsientoTurnoTarde,
      if (tipoDocumento != null) 'tipoDocumento': tipoDocumento!.name,
      'numeroDocumento': numeroDocumento,
      'nombreBeneficiario': nombreBeneficiario,
      'contactoAgencia': contactoAgencia,
      'linkContactoAgencia': linkContactoAgencia,
    };
  }
}

class AgenciaConReservas {
  final Agencia agencia;
  final int totalReservas;

  AgenciaConReservas({required this.agencia, required this.totalReservas});

  // Exponer propiedades de la Agencia interna para conveniencia
  String get id => agencia.id;
  String get nombre => agencia.nombre;
  String? get imagenUrl => agencia.imagenUrl;
  bool get eliminada => agencia.eliminada;
  // double? get precioPorAsiento => agencia.precioPorAsiento;
  double? get precioPorAsientoTurnoManana =>
      agencia.precioPorAsientoTurnoManana;
  double? get precioPorAsientoTurnoTarde => agencia.precioPorAsientoTurnoTarde;
  TipoDocumento? get tipoDocumento => agencia.tipoDocumento;
  String? get numeroDocumento => agencia.numeroDocumento;
  String? get nombreBeneficiario => agencia.nombreBeneficiario;
  String? get contactoAgencia => agencia.contactoAgencia;
  String? get linkContactoAgencia => agencia.linkContactoAgencia;
}
