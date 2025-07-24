import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ========== RESERVAS ==========

  Future<List<Reserva>> getAllReservas() async {
    try {
      final snap = await _db.collection('reservas').get();
      return snap.docs
          .map((d) => Reserva.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo todas las reservas: $e');
      return [];
    }
  }

  Stream<List<Reserva>> getReservasStream() {
    return _db
        .collection('reservas')
        .orderBy('fechaRegistro', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Reserva.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<Reserva>> getReservasByFecha(DateTime fecha) async {
    final start = DateTime(fecha.year, fecha.month, fecha.day);
    final end = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
    final snap = await _db
        .collection('reservas')
        .where(
          'fechaReserva',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snap.docs.map((d) => Reserva.fromFirestore(d.data(), d.id)).toList();
  }

  Stream<List<Reserva>> getReservasByFechaStream(DateTime fecha) {
    final start = DateTime(fecha.year, fecha.month, fecha.day);
    final end = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
    return _db
        .collection('reservas')
        .where('fechaReserva', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((d) => Reserva.fromFirestore(d.data(), d.id)).toList();
    });
  }

  Future<List<Reserva>> getReservasByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snap = await _db
        .collection('reservas')
        .where(
          'fechaReserva',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snap.docs.map((d) => Reserva.fromFirestore(d.data(), d.id)).toList();
  }

  Stream<List<Reserva>> getReservasByDateRangeStream(
      DateTime startDate, DateTime endDate) {
    return _db
        .collection('reservas')
        .where(
          'fechaReserva',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((d) => Reserva.fromFirestore(d.data(), d.id)).toList();
    });
  }

  Future<List<Reserva>> getReservasByAgencia(String agenciaId) async {
    try {
      final snap = await _db
          .collection('reservas')
          .where('agenciaId', isEqualTo: agenciaId)
          .get();
      final list = snap.docs
          .map((d) => Reserva.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      debugPrint('✅ Reservas obtenidas por agencia: ${list.length}');
      return list;
    } catch (e) {
      debugPrint('Error obteniendo reservas por agencia: $e');
      return [];
    }
  }

  Stream<List<Reserva>> getReservasByAgenciaStream(String agenciaId) {
    return _db
        .collection('reservas')
        .where('agenciaId', isEqualTo: agenciaId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => Reserva.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      return list;
    });
  }

  Future<void> addReserva(Reserva reserva) async {
    try {
      await _db.collection('reservas').add(reserva.toFirestore());
      debugPrint('✅ Reserva agregada: ${reserva.nombreCliente}');
    } catch (e) {
      debugPrint('❌ Error agregando reserva: $e');
      throw e;
    }
  }

  Future<void> updateReserva(String id, Reserva reserva) async {
    try {
      await _db.collection('reservas').doc(id).update(reserva.toFirestore());
      debugPrint('✅ Reserva actualizada: ${reserva.nombreCliente}');
    } catch (e) {
      debugPrint('❌ Error actualizando reserva: $e');
      throw e;
    }
  }

  Future<void> deleteReserva(String id) async {
    try {
      await _db.collection('reservas').doc(id).delete();
      debugPrint('✅ Reserva eliminada: $id');
    } catch (e) {
      debugPrint('❌ Error eliminando reserva: $e');
      throw e;
    }
  }

  // NUEVO MÉTODO: Actualiza el costoAsiento de todas las reservas de una agencia
  Future<void> updateReservasCostoAsiento(String agenciaId, double newCostoAsiento) async {
    try {
      final querySnapshot = await _db.collection('reservas')
          .where('agenciaId', isEqualTo: agenciaId)
          .get();

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'costoAsiento': newCostoAsiento});
      }
      await batch.commit();
      debugPrint('✅ Costo por asiento actualizado para ${querySnapshot.docs.length} reservas de la agencia $agenciaId a $newCostoAsiento');
    } catch (e) {
      debugPrint('❌ Error actualizando costo por asiento de reservas para agencia $agenciaId: $e');
      throw e;
    }
  }

  // ========== AGENCIAS ==========

  Stream<List<Agencia>> getAgenciasStream() {
    return _db
      .collection('agencias')
      .orderBy('nombre')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
          .map((doc) => Agencia.fromFirestore(doc.data(), doc.id))
          .toList();
      });
  }

  Future<List<Agencia>> getAllAgencias() async {
    try {
      final snapshot = await _db
        .collection('agencias')
        .orderBy('nombre')
        .get();
      return snapshot.docs
        .map((doc) => Agencia.fromFirestore(doc.data(), doc.id))
        .toList();
    } catch (e) {
      debugPrint('Error obteniendo agencias: $e');
      return [];
    }
  }

  // MODIFICADO: addAgencia ahora devuelve la Agencia con su ID generado
  Future<Agencia> addAgencia(Agencia agencia) async {
    try {
      final docRef = await _db.collection('agencias').add(agencia.toFirestore());
      final newAgencia = agencia.copyWith(id: docRef.id); // Usar copyWith para añadir el ID
      debugPrint('✅ Agencia agregada: ${newAgencia.nombre} con ID: ${newAgencia.id}');
      return newAgencia;
    } catch (e) {
      debugPrint('❌ Error agregando agencia: $e');
      throw e;
    }
  }

  Future<void> updateAgencia(String id, Agencia agencia) async {
    try {
      await _db.collection('agencias').doc(id).update(agencia.toFirestore());
      debugPrint('✅ Agencia actualizada: ${agencia.nombre}');
    } catch (e) {
      debugPrint('❌ Error actualizando agencia: $e');
      throw e;
    }
  }

  // ========== MÉTODOS DE UTILIDAD ==========

  Future<void> migrateAgenciasEliminadas() async {
    final snap = await _db.collection('agencias').get();
    final batch = _db.batch();
    for (var doc in snap.docs) {
      final data = doc.data();
      if (!data.containsKey('eliminada')) {
        batch.update(doc.reference, {'eliminada': false});
      }
    }
    await batch.commit();
    debugPrint('✅ Migración de campo "eliminada" completada.');
  }

  Future<void> initializeDefaultData() async {
    try {
      await migrateAgenciasEliminadas();
    } catch (e) {
      debugPrint('❌ Error inicializando datos: $e');
    }
  }
}
