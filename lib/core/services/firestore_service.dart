import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
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

//   void debugTest() async {
//   final db = FirebaseFirestore.instance;
//   // 1) Todas las reservas de la agencia
//   final snap1 = await db
//       .collection('reservas')
//       .where('agenciaId', isEqualTo: 'Pmlhy3e4n45FjHIL73Ng')
//       .get();
//   debugPrint('>>> TEST agencia only → ${snap1.docs.length} docs');

//   // 2) Mismo + turno = "manana"
//   final snap2 = await db
//       .collection('reservas')
//       .where('agenciaId', isEqualTo: 'Pmlhy3e4n45FjHIL73Ng')
//       .where('turno', isEqualTo: 'manana')
//       .get();
//   debugPrint('>>> TEST agencia+turno → ${snap2.docs.length} docs');

//   // 3) Mismo + turno + filtro fecha today
//   final now = DateTime.now();
//   final ini = DateTime(now.year, now.month, now.day);
//   final fin = ini.add(const Duration(days: 1));
//   final snap3 = await db
//       .collection('reservas')
//       .where('agenciaId', isEqualTo: 'Pmlhy3e4n45FjHIL73Ng')
//       .where('turno',    isEqualTo: 'manana')
//       .where('fechaReserva', isGreaterThanOrEqualTo: Timestamp.fromDate(ini))
//       .where('fechaReserva', isLessThan:            Timestamp.fromDate(fin))
//       .get();
//   debugPrint('>>> TEST agencia+turno+today → ${snap3.docs.length} docs');
// }

  /// Obtiene reservas filtradas por turno, fecha y agencia, sin paginación.
  Stream<QuerySnapshot<Reserva>> getReservasFiltered({
    TurnoType? turno,
    DateFilterType filter = DateFilterType.all,
    DateTime? customDate,
    String? agenciaId,
    EstadoReserva? estado,
  }) async* {
    // debugPrint('ReservasController.getReservasFiltered called with parameters: '
    //     'turno=$turno, filter=$filter, customDate=$customDate, '
    //     'agenciaId=$agenciaId, estado=$estado');
    // 1) traer TODAS las agencias para saber cuáles están eliminadas
    final todasAgencias = await getAllAgencias();
    final eliminadasIds = todasAgencias
        .where((a) => a.eliminada)
        .map((a) => a.id)
        .toList();

    // 2) construir consulta base
    var query =
        _db
                .collection('reservas')
                .withConverter<Reserva>(
                  fromFirestore: (snap, _) =>
                      Reserva.fromFirestore(snap.data()!, snap.id),
                  toFirestore: (res, _) => res.toFirestore(),
                )
            as Query<Reserva>;

    // 3) filtros de turno y agencia explícita
    if (turno != null) {
      final t = turno.toString().split('.').last;
      query = query.where('turno', isEqualTo: t);
    }
    if (agenciaId != null && agenciaId.isNotEmpty) {
      query = query.where('agenciaId', isEqualTo: agenciaId);
    }
    if (estado != null) {
      final e = estado.toString().split('.').last;
      query = query.where('estado', isEqualTo: e);
    }

    // 4) excluir agencias eliminadas: NOT‐IN + ORDER BY campo de inequality
    if (eliminadasIds.isNotEmpty) {
      query = query
          .where('agenciaId', whereNotIn: eliminadasIds);
    }

    // 5) filtros de fecha
    query = _applyDateFilter(query, filter, customDate);

    // 6) orden default por fechaReserva
    query = query.orderBy('fechaReserva', descending: true);

    // 7) entregar stream completo al controlador
    yield* query.snapshots().map((snapshot) {
      return snapshot;
    });
  }

  /// Obtiene un stream de todas las reservas.
  /// @return Un stream de listas de reservas.
  /// en terminos sencillos, este método devuelve un stream que emite
  /// una lista de reservas cada vez que hay un cambio en la colección de reservas en Firestore.
  /// Esto es útil para mantener la UI actualizada en tiempo real con los datos más recientes
  // Stream<List<Reserva>> getReservasStream() {
  //   return _db
  //       .collection('reservas')
  //       .orderBy('fechaRegistro', descending: true)
  //       .snapshots()
  //       .map((snapshot) {
  //         return snapshot.docs.map((doc) {
  //           return Reserva.fromFirestore(doc.data(), doc.id);
  //         }).toList();
  //       });
  // }
  Stream<List<Reserva>> getReservasStream() {
    return _db
        .collection('reservas')
        // 1) ordenamos por fechaReserva (no por fechaRegistro)
        .orderBy('fechaReserva', descending: true)
        .snapshots()
        .map((snapshot) {
          // 2) mapeamos a modelo
          final reservas = snapshot.docs
              .map((doc) => Reserva.fromFirestore(doc.data(), doc.id))
              .toList();
          // 3) separamos en dos listas: no pagadas primero, pagadas al final
          final normales = reservas
              .where((r) => r.estado != EstadoReserva.pagada)
              .toList();
          final pagadas = reservas
              .where((r) => r.estado == EstadoReserva.pagada)
              .toList();
          // 4) combinamos en un solo listado
          return [...normales, ...pagadas];
        });
  }

  /// Agrega una nueva reserva.
  /// @param reserva La reserva a agregar.
  /// @return Un Future que completa cuando la reserva se agrega correctamente.
  Future<void> addReserva(Reserva reserva) async {
    try {
      await _db.collection('reservas').add(reserva.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  /// Actualiza una reserva existente.
  /// @param id El ID de la reserva a actualizar.
  /// @param reserva La reserva con los nuevos datos.
  /// @return Un Future que completa cuando la reserva se actualiza correctamente.
  Future<void> updateReserva(String id, Reserva reserva) async {
    try {
      await _db
          .collection('reservas')
          .doc(id)
          .set(reserva.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina una reserva.
  /// @param id El ID de la reserva a eliminar.
  Future<void> deleteReserva(String id) async {
    try {
      await _db.collection('reservas').doc(id).delete();
    } catch (e) {
      throw e;
    }
  }


  Future<void> updateReservasCostoAsientoManana(
    String agenciaId,
    double newCostoAsiento,
  ) async {
    try {
      /// Obtiene todas las reservas de la agencia en el turno de mañana
      /// y actualiza el campo costoAsiento.
      /// Este método es útil para actualizar el costo de los asientos
      final querySnapshot = await _db
          .collection('reservas')
          .where('agenciaId', isEqualTo: agenciaId)
          .where('turno', isEqualTo: 'manana')
          .get();

      final batch = _db.batch();
      // for (var doc in querySnapshot.docs) {
      //   // batch.update(doc.reference, {'costoAsiento': newCostoAsiento});
      // }
      await batch.commit();
      debugPrint(
        '✅ Costo por asiento (mañana) actualizado para '
        '${querySnapshot.docs.length} reservas de la agencia $agenciaId a '
        '$newCostoAsiento',
      );
    } catch (e) {
      debugPrint(
        '❌ Error actualizando costo por asiento (mañana) de reservas para '
        'agencia $agenciaId: $e',
      );
      rethrow;
    }
  }

  /// Actualiza el costoAsiento de todas las reservas de una agencia en el turno de tarde.
  Future<void> updateReservasCostoAsientoTarde(
    String agenciaId,
    double newCostoAsiento,
  ) async {
    try {
      final querySnapshot = await _db
          .collection('reservas')
          .where('agenciaId', isEqualTo: agenciaId)
          .where('turno', isEqualTo: 'tarde')
          .get();

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'costoAsiento': newCostoAsiento});
      }
      await batch.commit();
      // debugPrint(
      //   '✅ Costo por asiento (tarde) actualizado para '
      //   '${querySnapshot.docs.length} reservas de la agencia $agenciaId a '
      //   '$newCostoAsiento',
      // );
    } catch (e) {
      // debugPrint(
      //   '❌ Error actualizando costo por asiento (tarde) de reservas para '
      //   'agencia $agenciaId: $e',
      // );
      rethrow;
    }
  }

  // ========== AGENCIAS ==========

  //// Obtiene un stream de agencias ordenadas por nombre.
  /// @return Un stream de listas de agencias.

  Stream<List<Agencia>> getAgenciasStream() {
    return _db.collection('agencias').snapshots().map((
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
      final snapshot = await _db.collection('agencias').get();
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
      // debugPrint(
      //   '✅ Agencia agregada: ${newAgencia.nombre} con ID: ${newAgencia.id}',
      // );
      return newAgencia;
    } catch (e) {
      // debugPrint('❌ Error agregando agencia: $e');
      rethrow;
    }
  }

  Future<void> updateAgencia(String id, Agencia agencia) async {
    try {
      // Construir el map a actualizar a partir de toFirestore()
      final data = agencia.toFirestore();
      // Eliminar el campo obsoleto 'precioPorAsiento'
      data['precioPorAsiento'] = FieldValue.delete();

      await _db.collection('agencias').doc(id).update(data);
      // debugPrint('✅ Agencia actualizada: ${agencia.nombre}');
    } catch (e) {
      // debugPrint('❌ Error actualizando agencia: $e');
      rethrow;
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
    // debugPrint('✅ Migración de campo "eliminada" completada.');
  }

  /// Inicializa los datos por defecto en Firestore.
  /// Este método se utiliza para migrar datos existentes y asegurarse de que
  Future<void> initializeDefaultData() async {
    try {
      await migrateAgenciasEliminadas();
    } catch (e) {
      // debugPrint('❌ Error inicializando datos: $e');
    }
  }

  Future<bool> seAlcanzoLimiteCuposFirestore({
    required TurnoType turno,
    required DateTime fecha,
    required int maxCupos,
  }) async {
    // debugPrint(
    //   'Verificando límite de cupos para $turno en fecha $fecha con máximo $maxCupos',
    // );
    final fechaInicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fechaFin = fechaInicio.add(const Duration(days: 1));

    final snapshot = await _db
        .collection('reservas')
        .where(
          'fechaReserva',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio),
        )
        .where('fechaReserva', isLessThan: Timestamp.fromDate(fechaFin))
        .where('turno', isEqualTo: turno.name)
        .where('estado', isNotEqualTo: 'pagada') // para excluir pagadas
        .get();

    final totalPax = snapshot.docs.fold<int>(
      0,
      // ignore: avoid_types_as_parameter_names
      (sum, doc) => sum + (doc.data()['pax'] as int? ?? 0),
    );

    // debugPrint('Total de pax reservados: $totalPax');

    return totalPax >= maxCupos;
  }

  Future<int> getTotalPaxReservados({
    required TurnoType turno,
    required DateTime fecha,
  }) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));
    final snap = await _db
        .collection('reservas')
        .where(
          'fechaReserva',
          isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
        )
        .where('fechaReserva', isLessThan: Timestamp.fromDate(fin))
        .where('turno', isEqualTo: turno.name)
        .where('estado', isNotEqualTo: 'pagada')
        .get();
    return snap.docs.fold<int>(
      0,
      (sum, doc) => sum + (doc.data()['pax'] as int? ?? 0),
    );
  }
}
