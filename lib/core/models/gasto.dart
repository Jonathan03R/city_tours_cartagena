import 'package:cloud_firestore/cloud_firestore.dart';

class Gasto {
  final String id;
  final double monto;
  final DateTime fecha;
  final String? descripcion;

  Gasto({
    required this.id,
    required this.monto,
    required this.fecha,
    this.descripcion,
  });

  factory Gasto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gasto(
      id: doc.id,
      monto: (data['amount'] as num).toDouble(),
      fecha: (data['date'] as Timestamp).toDate(),
      descripcion: data['description'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': monto,
      'date': Timestamp.fromDate(fecha),
      'description': descripcion,
    };
  }
}
