import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fechas_bloquedas.dart';
import '../models/enum/tipo_turno.dart';

class FechasBloquedasService {
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
