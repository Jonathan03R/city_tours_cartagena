import 'package:cloud_firestore/cloud_firestore.dart';

class ReservasService {
  final _reservasRef = FirebaseFirestore.instance.collection('reservas');
  final _agenciasRef = FirebaseFirestore.instance.collection('agencias');

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

  //  Future<List<Map<String, dynamic>>> obtenerReservasPorRango(DateTime inicio, DateTime fin) async {
  //   final reservasSnapshot = await _reservasRef.get();
  //   final reservasFiltradas = reservasSnapshot.docs.where((doc) {
  //     final fechaReserva = (doc['fechaReserva'] as Timestamp).toDate();
  //     final fechaSolo = DateTime(fechaReserva.year, fechaReserva.month, fechaReserva.day);
  //     final inicioSolo = DateTime(inicio.year, inicio.month, inicio.day);
  //     final finSolo = DateTime(fin.year, fin.month, fin.day);
  //     return !fechaSolo.isBefore(inicioSolo) && !fechaSolo.isAfter(finSolo);
  //   }).toList();

  //   List<Map<String, dynamic>> reservasValidas = [];
  //   for (final doc in reservasFiltradas) {
  //     final data = doc.data();
  //     final agenciaId = data['agenciaId'];
  //     if (agenciaId == null || agenciaId == '') {
  //       reservasValidas.add(data); // Sin agencia, la reserva es válida
  //       continue;
  //     }
  //     final agenciaSnap = await _agenciasRef.doc(agenciaId).get();
  //     if (!agenciaSnap.exists) continue; // Agencia no existe, reserva fuera
  //     final agenciaData = agenciaSnap.data();
  //     if (agenciaData?['eliminada'] == true) continue; // Agencia eliminada, reserva fuera
  //     reservasValidas.add(data);
  //   }
  //   return reservasValidas;
  // }
  
}