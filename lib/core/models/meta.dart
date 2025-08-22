import 'package:cloud_firestore/cloud_firestore.dart';

class Meta {
  final int semanal;
  final int mensual;

  Meta({required this.semanal, required this.mensual});

  factory Meta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Meta(
      semanal: (data['weekly'] as num?)?.toInt() ?? 0,
      mensual: (data['monthly'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'weekly': semanal,
      'monthly': mensual,
      'date': FieldValue.serverTimestamp(),
    };
  }
}

class HistorialMeta {
  final String id;
  final DateTime fecha;
  final int metaSemanal;
  final int metaMensual;

  HistorialMeta({
    required this.id,
    required this.fecha,
    required this.metaSemanal,
    required this.metaMensual,
  });

  factory HistorialMeta.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HistorialMeta(
      id: doc.id,
      fecha: (data['date'] as Timestamp).toDate(),
      metaSemanal: (data['weekly'] as num).toInt(),
      metaMensual: (data['monthly'] as num).toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(fecha),
      'weekly': metaSemanal,
      'monthly': metaMensual,
    };
  }
}
