import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // Método auxiliar para aplicar filtros de fecha
  /// Aplica un filtro de fecha a la consulta de reservas.
  /// @param query La consulta de reservas a filtrar.
  /// @param filter El tipo de filtro de fecha a aplicar. 
  /// @param customDate Una fecha personalizada para el filtro, si es necesario.
  /// @return La consulta de reservas filtrada por fecha.
  Query<Reserva> _applyDateFilter(
    Query<Reserva> query,
    DateFilterType filter,
    DateTime? customDate,
  ) {
    final now = DateTime.now();
    switch (filter) {
      case DateFilterType.today:
        final ini = DateTime(now.year, now.month, now.day);
        query = query
            .where(
              'fechaReserva',
              isGreaterThanOrEqualTo: Timestamp.fromDate(ini),
            )
            .where(
              'fechaReserva',
              isLessThan: Timestamp.fromDate(ini.add(const Duration(days: 1))),
            );
        break;
      case DateFilterType.yesterday:
        final ayer = now.subtract(const Duration(days: 1));
        final iniY = DateTime(ayer.year, ayer.month, ayer.day);
        query = query
            .where(
              'fechaReserva',
              isGreaterThanOrEqualTo: Timestamp.fromDate(iniY),
            )
            .where(
              'fechaReserva',
              isLessThan: Timestamp.fromDate(iniY.add(const Duration(days: 1))),
            );
        break;
      case DateFilterType.tomorrow:
        final man = now.add(const Duration(days: 1));
        final iniM = DateTime(man.year, man.month, man.day);
        query = query
            .where(
              'fechaReserva',
              isGreaterThanOrEqualTo: Timestamp.fromDate(iniM),
            )
            .where(
              'fechaReserva',
              isLessThan: Timestamp.fromDate(iniM.add(const Duration(days: 1))),
            );
        break;
      case DateFilterType.lastWeek:
        final iniW = now.subtract(const Duration(days: 7));
        query = query.where(
          'fechaReserva',
          isGreaterThanOrEqualTo: Timestamp.fromDate(iniW),
        );
        break;
      case DateFilterType.custom:
        if (customDate != null) {
          final iniC = DateTime(
            customDate.year,
            customDate.month,
            customDate.day,
          );
          query = query
              .where(
                'fechaReserva',
                isGreaterThanOrEqualTo: Timestamp.fromDate(iniC),
              )
              .where(
                'fechaReserva',
                isLessThan: Timestamp.fromDate(
                  iniC.add(const Duration(days: 1)),
                ),
              );
        }
        break;
      case DateFilterType.all:
        break;
    }
    return query;
  }

  // ========== RESERVAS ==========
  /// Obtiene reservas filtradas por turno, fecha y agencia.
  /// @param turno El tipo de turno a filtrar (opcional). 
  /// @param filter El tipo de filtro de fecha a aplicar (opcional, por defecto es DateFilterType.all).
  /// @param customDate Una fecha personalizada para el filtro (opcional).
  // Stream<List<Reserva>> getReservasFiltered({
  //   TurnoType? turno,
  //   DateFilterType filter = DateFilterType.all,
  //   DateTime? customDate,
  //   String? agenciaId,
  // }) {
  //   var query =
  //       _db
  //               .collection('reservas')
  //               .withConverter<Reserva>(
  //                 fromFirestore: (snap, _) =>
  //                     Reserva.fromFirestore(snap.data()!, snap.id),
  //                 toFirestore: (res, _) => res.toFirestore(),
  //               )
  //           as Query<Reserva>;

  //   if (turno != null) {
  //     final t = turno.toString().split('.').last;
  //     query = query.where('turno', isEqualTo: t);
  //   }

  //   if (agenciaId != null && agenciaId.isNotEmpty) {
  //     query = query.where('agenciaId', isEqualTo: agenciaId);
  //   }

  //   query = _applyDateFilter(
  //     query,
  //     filter,
  //     customDate,
  //   ); // Usar el método auxiliar

  //   query = query.orderBy('fechaReserva', descending: true);

  //   return query.snapshots().map(
  //     (snap) => snap.docs.map((d) => d.data()).toList(),
  //   );
  // }

  // NUEVO MÉTODO: Para obtener reservas con paginación
  Stream<QuerySnapshot<Reserva>> getPaginatedReservasFiltered({
    TurnoType? turno,
    DateFilterType filter = DateFilterType.all,
    DateTime? customDate,
    String? agenciaId,
    required int limit,
    DocumentSnapshot? startAfterDocument,
  }) {
    // 🐞 DEBUG: imprime TODO lo que llega al servicio
    debugPrint(
      ' 🔎 filtro prueba  🔥 FirestoreService.getPaginatedReservasFiltered → '
      'turno=${turno?.toString() ?? "null"}, '
      'filter=$filter, '
      'customDate=${customDate?.toIso8601String() ?? "null"}, '
      'agenciaId=${agenciaId ?? "null"}, '
      'limit=$limit, '
      'startAfterDoc=${startAfterDocument != null}',
    );
    var query =
        _db
                .collection('reservas')
                .withConverter<Reserva>(
                  fromFirestore: (snap, _) =>
                      Reserva.fromFirestore(snap.data()!, snap.id),
                  toFirestore: (res, _) => res.toFirestore(),
                )
            as Query<Reserva>;

    if (turno != null) {
      final t = turno.toString().split('.').last;
      query = query.where('turno', isEqualTo: t);
    }

    if (agenciaId != null && agenciaId.isNotEmpty) {
      query = query.where('agenciaId', isEqualTo: agenciaId);
    }

    query = _applyDateFilter(
      query,
      filter,
      customDate,
    ); // Usar el método auxiliar

    query = query.orderBy('fechaReserva', descending: true);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    query = query.limit(limit);

    return query.snapshots();
  }

  /// Obtiene todas las reservas.
  /// @return Una lista de reservas.

  // Future<List<Reserva>> getAllReservas() async {
  //   try {
  //     final snap = await _db.collection('reservas').get();
  //     return snap.docs
  //         .map((d) => Reserva.fromFirestore(d.data(), d.id))
  //         .toList();
  //   } catch (e) {
  //     debugPrint('❌ Error obteniendo todas las reservas: $e');
  //     return [];
  //   }
  // }

  /// Obtiene un stream de todas las reservas.
  /// @return Un stream de listas de reservas.
  /// en terminos sencillos, este método devuelve un stream que emite 
  /// una lista de reservas cada vez que hay un cambio en la colección de reservas en Firestore.
  /// Esto es útil para mantener la UI actualizada en tiempo real con los datos más recientes
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

  /// Obtiene reservas por fecha específica.
  /// @param fecha La fecha para filtrar las reservas.

  // Future<List<Reserva>> getReservasByFecha(DateTime fecha) async {
  //   final start = DateTime(fecha.year, fecha.month, fecha.day);
  //   final end = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
  //   final snap = await _db
  //       .collection('reservas')
  //       .where(
  //         'fechaReserva',
  //         isGreaterThanOrEqualTo: Timestamp.fromDate(start),
  //       )
  //       .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(end))
  //       .get();
  //   return snap.docs.map((d) => Reserva.fromFirestore(d.data(), d.id)).toList();
  // }

  /// Obtiene un stream de reservas por fecha específica.
  /// @param fecha La fecha para filtrar las reservas.
  // Stream<List<Reserva>> getReservasByFechaStream(DateTime fecha) {
  //   final start = DateTime(fecha.year, fecha.month, fecha.day);
  //   final end = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
  //   return _db
  //       .collection('reservas')
  //       .where(
  //         'fechaReserva',
  //         isGreaterThanOrEqualTo: Timestamp.fromDate(start),
  //       )
  //       .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(end))
  //       .snapshots()
  //       .map((snapshot) {
  //         return snapshot.docs
  //             .map((d) => Reserva.fromFirestore(d.data(), d.id))
  //             .toList();
  //       });
  // }

  /// Obtiene reservas por rango de fechas.
  /// @param start La fecha de inicio del rango.
  // Future<List<Reserva>> getReservasByDateRange(
  //   DateTime start,
  //   DateTime end,
  // ) async {
  //   final snap = await _db
  //       .collection('reservas')
  //       .where(
  //         'fechaReserva',
  //         isGreaterThanOrEqualTo: Timestamp.fromDate(start),
  //       )
  //       .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(end))
  //       .get();
  //   return snap.docs.map((d) => Reserva.fromFirestore(d.data(), d.id)).toList();
  // }

  /// Obtiene un stream de reservas por rango de fechas.
  /// @param startDate La fecha de inicio del rango.
  /// @param endDate La fecha de fin del rango.

  // Stream<List<Reserva>> getReservasByDateRangeStream(
  //   DateTime startDate,
  //   DateTime endDate,
  // ) {
  //   return _db
  //       .collection('reservas')
  //       .where(
  //         'fechaReserva',
  //         isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
  //       )
  //       .where('fechaReserva', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
  //       .snapshots()
  //       .map((snapshot) {
  //         return snapshot.docs
  //             .map((d) => Reserva.fromFirestore(d.data(), d.id))
  //             .toList();
  //       });
  // }

  /// Obtiene reservas por agencia.
  /// @param agenciaId El ID de la agencia para filtrar las reservas. 
  // Future<List<Reserva>> getReservasByAgencia(String agenciaId) async {
  //   try {
  //     final snap = await _db
  //         .collection('reservas')
  //         .where('agenciaId', isEqualTo: agenciaId)
  //         .get();
  //     final list = snap.docs
  //         .map((d) => Reserva.fromFirestore(d.data(), d.id))
  //         .toList();
  //     list.sort((a, b) => b.fecha.compareTo(a.fecha));
  //     debugPrint('✅ Reservas obtenidas por agencia: ${list.length}');
  //     return list;
  //   } catch (e) {
  //     debugPrint('Error obteniendo reservas por agencia: $e');
  //     return [];
  //   }
  // }

  // Stream<List<Reserva>> getReservasByAgenciaStream(String agenciaId) {
  //   return _db
  //       .collection('reservas')
  //       .where('agenciaId', isEqualTo: agenciaId)
  //       .snapshots()
  //       .map((snapshot) {
  //         final list = snapshot.docs
  //             .map((d) => Reserva.fromFirestore(d.data(), d.id))
  //             .toList();
  //         list.sort((a, b) => b.fecha.compareTo(a.fecha));
  //         return list;
  //       });
  // }

  /// Agrega una nueva reserva.
  /// @param reserva La reserva a agregar.
  /// @return Un Future que completa cuando la reserva se agrega correctamente.
  Future<void> addReserva(Reserva reserva) async {
    try {
      await _db.collection('reservas').add(reserva.toFirestore());
      debugPrint('✅ Reserva agregada: ${reserva.nombreCliente}');
    } catch (e) {
      debugPrint('❌ Error agregando reserva: $e');
      throw e;
    }
  }
  /// Actualiza una reserva existente.
  /// @param id El ID de la reserva a actualizar. 
  /// @param reserva La reserva con los nuevos datos.
  /// @return Un Future que completa cuando la reserva se actualiza correctamente.
  Future<void> updateReserva(String id, Reserva reserva) async {
    try {
      await _db.collection('reservas').doc(id).update(reserva.toFirestore());
      debugPrint('✅ Reserva actualizada: ${reserva.nombreCliente}');
    } catch (e) {
      debugPrint('❌ Error actualizando reserva: $e');
      throw e;
    }
  }
  /// Elimina una reserva.
  /// @param id El ID de la reserva a eliminar.
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
  Future<void> updateReservasCostoAsiento(
    String agenciaId,
    double newCostoAsiento,
  ) async {
    try {
      final querySnapshot = await _db
          .collection('reservas')
          .where('agenciaId', isEqualTo: agenciaId)
          .get();

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'costoAsiento': newCostoAsiento});
      }
      await batch.commit();
      debugPrint(
        '✅ Costo por asiento actualizado para ${querySnapshot.docs.length} reservas de la agencia $agenciaId a $newCostoAsiento',
      );
    } catch (e) {
      debugPrint(
        '❌ Error actualizando costo por asiento de reservas para agencia $agenciaId: $e',
      );
      throw e;
    }
  }

  // ========== AGENCIAS ==========

  //// Obtiene un stream de agencias ordenadas por nombre.
  /// @return Un stream de listas de agencias.  

  Stream<List<Agencia>> getAgenciasStream() {
    return _db.collection('agencias').orderBy('nombre').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Agencia.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
  /// Obtiene todas las agencias ordenadas por nombre.
  /// @return Una lista de agencias ordenadas por nombre.
  Future<List<Agencia>> getAllAgencias() async {
    try {
      final snapshot = await _db.collection('agencias').orderBy('nombre').get();
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
      final docRef = await _db
          .collection('agencias')
          .add(agencia.toFirestore());
      final newAgencia = agencia.copyWith(
        id: docRef.id,
      ); // Usar copyWith para añadir el ID
      debugPrint(
        '✅ Agencia agregada: ${newAgencia.nombre} con ID: ${newAgencia.id}',
      );
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

  /// Elimina una agencia por su ID.
  /// @param id El ID de la agencia a eliminar.

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
  /// Inicializa los datos por defecto en Firestore.
  /// Este método se utiliza para migrar datos existentes y asegurarse de que
  Future<void> initializeDefaultData() async {
    try {
      await migrateAgenciasEliminadas();
    } catch (e) {
      debugPrint('❌ Error inicializando datos: $e');
    }
  }
}
