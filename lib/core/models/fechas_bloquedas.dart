import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';

enum TurnoCerrado { manana, tarde, ambos }

class FechaBloqueada {
  final DateTime fecha;
  final bool cerrado;
  final String turno; // 'manana', 'tarde', 'ambos'
  final String? motivo;

  FechaBloqueada({
    required this.fecha,
    required this.cerrado,
    required this.turno,
    this.motivo,
  });

  factory FechaBloqueada.fromMap(Map<String, dynamic> data, String docId) {
    return FechaBloqueada(
      fecha: DateTime.parse(docId),
      cerrado: data['cerrado'] ?? false,
      turno: data['turno'] ?? 'ambos',
      motivo: data['motivo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cerrado': cerrado,
      'turno': turno,
      if (motivo != null) 'motivo': motivo,
    };
  }
}
