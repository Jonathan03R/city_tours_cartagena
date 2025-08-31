import 'package:cloud_firestore/cloud_firestore.dart';

class ReservasService {
  final _reservasRef = FirebaseFirestore.instance.collection('reservas');

  /// Retorna la suma de pasajeros en el rango de fechas [inicio, fin].
  /// Si [turno] es null, suma todos los turnos. Si no, solo ese turno.
  Future<int> obtenerSumaPasajerosPorRango(DateTime inicio, DateTime fin, {String? turno}) async {
    final snapshot = await _reservasRef.get();
    return snapshot.docs.fold<int>(0, (sum, doc) {
      final fechaReserva = (doc['fechaReserva'] as Timestamp).toDate();
      final fechaSolo = DateTime(fechaReserva.year, fechaReserva.month, fechaReserva.day);
      final inicioSolo = DateTime(inicio.year, inicio.month, inicio.day);
      final finSolo = DateTime(fin.year, fin.month, fin.day);
      final turnoDoc = doc['turno'] as String?;
      final cumpleTurno = turno == null || turnoDoc == turno;
      if (!fechaSolo.isBefore(inicioSolo) && !fechaSolo.isAfter(finSolo) && cumpleTurno) {
        return sum + ((doc['pax'] ?? 0) as int);
      }
      return sum;
    });
  }
}