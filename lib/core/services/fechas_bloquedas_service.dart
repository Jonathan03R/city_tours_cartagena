import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fechas_bloquedas.dart';
import '../models/enum/tipo_turno.dart';

class FechasBloquedasService {
  /// Retorna un stream con todos los bloqueos de la fecha (puede haber más de uno por turno)
  static Stream<List<FechaBloqueada>> getBloqueosParaFecha(DateTime fecha) {
    final docId = _dateToDocId(fecha);
    // Si solo hay un documento por fecha, devolvemos una lista con 0 o 1 elemento
    return _col
        .where(FieldPath.documentId, isEqualTo: docId)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.exists && d.data() != null)
            .map((d) => FechaBloqueada.fromMap(d.data()!, d.id))
            .toList());
  }
  static final _col = FirebaseFirestore.instance.collection('fechas_bloqueadas');

  static Future<void> bloquearFecha(DateTime fecha, String turno, String motivo) async {
    final docId = _dateToDocId(fecha);
    await _col.doc(docId).set({
      'cerrado': true,
      'turno': turno, // 'manana', 'tarde', 'ambos'
      'motivo': motivo,
    });
  }

  static Future<void> desbloquearFecha(DateTime fecha) async {
    final docId = _dateToDocId(fecha);
    await _col.doc(docId).delete();
  }

  static Stream<FechaBloqueada?> getBloqueoParaFecha(DateTime fecha) {
    final docId = _dateToDocId(fecha);
    return _col.doc(docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return FechaBloqueada.fromMap(snap.data()!, docId);
    });
  }

  static String _dateToDocId(DateTime fecha) {
    return fecha.toIso8601String().split('T').first;
  }
}
