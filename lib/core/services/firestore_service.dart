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

  // Versión Future existente
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

  // NUEVO: Versión Stream para reservas por fecha
  Stream<List<Reserva>> getReservasByFechaStream(DateTime fecha) {
    final start = DateTime(fecha.year, fecha.month, fecha.day);
    final end = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
    return _db
        .collection('reservas')
        .where('fechaReserva', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots() // Usar snapshots para tiempo real
        .map((snapshot) {
      return snapshot.docs.map((d) => Reserva.fromFirestore(d.data(), d.id)).toList();
    });
  }

  // Versión Future existente
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

  // NUEVO: Versión Stream para reservas por rango de fechas
  Stream<List<Reserva>> getReservasByDateRangeStream(
      DateTime startDate, DateTime endDate) {
    return _db
        .collection('reservas')
        .where(
          'fechaReserva',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots() // Usar snapshots para tiempo real
        .map((snapshot) {
      return snapshot.docs.map((d) => Reserva.fromFirestore(d.data(), d.id)).toList();
    });
  }

  // Versión Future existente
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

  // NUEVO: Versión Stream para reservas por agencia
  Stream<List<Reserva>> getReservasByAgenciaStream(String agenciaId) {
    return _db
        .collection('reservas')
        .where('agenciaId', isEqualTo: agenciaId)
        .snapshots() // Usar snapshots para tiempo real
        .map((snapshot) {
      final list = snapshot.docs
          .map((d) => Reserva.fromFirestore(d.data(), d.id))
          .toList();
      list.sort((a, b) => b.fecha.compareTo(a.fecha)); // Mantener el orden
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

  // ========== AGENCIAS ==========

  Stream<List<Agencia>> getAgenciasStream() {
    return _db.collection('agencias').orderBy('nombre').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Agencia.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<Agencia>> getAllAgencias() async {
    try {
      final snapshot = await _db.collection('agencias').get();
      return snapshot.docs.map((doc) {
        return Agencia.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error obteniendo agencias: $e');
      return [];
    }
  }

  Future<void> addAgencia(Agencia agencia) async {
    try {
      await _db.collection('agencias').add(agencia.toFirestore());
      debugPrint('✅ Agencia agregada: ${agencia.nombre}');
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

  Future<void> deleteAgencia(String id) async {
    try {
      await _db.collection('agencias').doc(id).delete();
      debugPrint('✅ Agencia eliminada: $id');
    } catch (e) {
      debugPrint('❌ Error eliminando agencia: $e');
      throw e;
    }
  }

  // ========== MÉTODOS DE UTILIDAD ==========
  Future<void> initializeDefaultData() async {
    try {
      // Verificar si ya hay agencias
      final agenciasSnapshot = await _db.collection('agencias').limit(1).get();
      if (agenciasSnapshot.docs.isEmpty) {
        debugPrint('🔄 Inicializando datos por defecto...');
        // Crear agencias por defecto
        final agenciasDefault = [
          Agencia(id: '', nombre: 'Viajes del Sol'),
          Agencia(id: '', nombre: 'Turismo Express'),
          Agencia(id: '', nombre: 'Aventuras Tropicales'),
        ];
        for (final agencia in agenciasDefault) {
          await addAgencia(agencia);
        }
        debugPrint('✅ Datos por defecto inicializados');
      }
    } catch (e) {
      debugPrint('❌ Error inicializando datos por defecto: $e');
    }
  }
}
