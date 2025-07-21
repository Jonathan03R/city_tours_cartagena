import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:flutter/foundation.dart';

import '../services/firestore_service.dart';

class ReservasController {
  static final FirestoreService _firestoreService = FirestoreService();
  static List<Reserva> _reservasCache = [];
  static List<Agencia> _agenciasCache = [];
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      debugPrint('🔄 Inicializando Firebase Controller...');

      // Inicializar datos por defecto si es necesario
      await _firestoreService.initializeDefaultData();

      // Cargar agencias en cache
      _agenciasCache = await _firestoreService.getAllAgencias();
      debugPrint('✅ ${_agenciasCache.length} agencias cargadas en cache');

      _initialized = true;
      debugPrint('🎉 Firebase Controller inicializado exitosamente');
    } catch (e) {
      debugPrint('❌ Error inicializando Firebase Controller: $e');
    }
  }

  // ========== RESERVAS ==========

  static Future<List<ReservaConAgencia>> getAllReservas() async {
    // 1) trae todas las reservas
    final raw = await _firestoreService.getAllReservas();
    // 2) actualiza cache si quieres
    _reservasCache = raw;
    // 3) combínalas con agencias en cache
    return await _combineReservasWithAgencias(raw);
  }

  static Stream<List<ReservaConAgencia>> getReservasStream() {
    return _firestoreService.getReservasStream().asyncMap((reservas) async {
      _reservasCache = reservas;
      return await _combineReservasWithAgencias(reservas);
    });
  }

  static Future<List<ReservaConAgencia>> getReservasByFecha(
    DateTime fecha,
  ) async {
    try {
      final reservas = await _firestoreService.getReservasByFecha(fecha);
      return await _combineReservasWithAgencias(reservas);
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas por fecha: $e');
      return [];
    }
  }

  static Future<List<ReservaConAgencia>> getReservasByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final reservas = await _firestoreService.getReservasByDateRange(
        startDate,
        endDate,
      );
      return await _combineReservasWithAgencias(reservas);
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas por rango: $e');
      return [];
    }
  }

  static Future<List<ReservaConAgencia>> getReservasLastWeek() async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return await getReservasByDateRange(lastWeek, now);
  }

  static Future<List<ReservaConAgencia>> getReservasByAgencia(
    String agenciaId,
  ) async {
    try {
      final reservas = await _firestoreService.getReservasByAgencia(agenciaId);
      return await _combineReservasWithAgencias(reservas);
    } catch (e) {
      debugPrint('❌ Error obteniendo reservas por agencia: $e');
      return [];
    }
  }

  static Future<void> addReserva(Reserva reserva) async {
    try {
      await _firestoreService.addReserva(reserva);
      debugPrint('✅ Reserva agregada exitosamente');
    } catch (e) {
      debugPrint('❌ Error agregando reserva: $e');
      throw e;
    }
  }

  static Future<void> updateReserva(String id, Reserva reserva) async {
    try {
      await _firestoreService.updateReserva(id, reserva);
      debugPrint('✅ Reserva actualizada exitosamente');
    } catch (e) {
      debugPrint('❌ Error actualizando reserva: $e');
      throw e;
    }
  }

  static Future<void> deleteReserva(String id) async {
    try {
      await _firestoreService.deleteReserva(id);
      debugPrint('✅ Reserva eliminada exitosamente');
    } catch (e) {
      debugPrint('❌ Error eliminando reserva: $e');
      throw e;
    }
  }

  // ========== AGENCIAS ==========

  static Stream<List<AgenciaConReservas>> getAgenciasStream() {
    return _firestoreService.getAgenciasStream().asyncMap((agencias) async {
      _agenciasCache = agencias;

      // Calcular total de reservas para cada agencia
      final agenciasConReservas = <AgenciaConReservas>[];

      for (final agencia in agencias) {
        final reservasAgencia = await _firestoreService.getReservasByAgencia(
          agencia.id,
        );
        agenciasConReservas.add(
          AgenciaConReservas(
            id: agencia.id,
            nombre: agencia.nombre,
            totalReservas: reservasAgencia.length,
          ),
        );
      }

      return agenciasConReservas;
    });
  }

  static List<AgenciaConReservas> getAllAgencias() {
    return _agenciasCache.map((agencia) {
      final totalReservas = _reservasCache
          .where((r) => r.agenciaId == agencia.id)
          .length;
      return AgenciaConReservas(
        id: agencia.id,
        nombre: agencia.nombre,
        totalReservas: totalReservas,
      );
    }).toList();
  }

  static Agencia? getAgenciaById(String id) {
    try {
      return _agenciasCache.firstWhere((a) => a.id == id);
    } catch (e) {
      debugPrint('❌ Agencia no encontrada: $id');
      return null;
    }
  }

  static List<Agencia> searchAgencias(String query) {
    return _agenciasCache
        .where(
          (agencia) =>
              agencia.nombre.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  static Future<Agencia> addAgencia(String nombre) async {
    try {
      final newAgencia = Agencia(id: '', nombre: nombre);
      await _firestoreService.addAgencia(newAgencia);

      // Recargar cache
      _agenciasCache = await _firestoreService.getAllAgencias();

      // Encontrar la agencia recién creada
      final createdAgencia = _agenciasCache.firstWhere(
        (a) => a.nombre == nombre,
      );
      debugPrint('✅ Agencia agregada: $nombre');
      return createdAgencia;
    } catch (e) {
      debugPrint('❌ Error agregando agencia: $e');
      throw e;
    }
  }

  // ========== MÉTODOS AUXILIARES ==========

  static Future<List<ReservaConAgencia>> _combineReservasWithAgencias(
    List<Reserva> reservas,
  ) async {
    // Asegurar que tenemos las agencias en cache
    if (_agenciasCache.isEmpty) {
      _agenciasCache = await _firestoreService.getAllAgencias();
    }

    return reservas.map((reserva) {
      final agencia = _agenciasCache.firstWhere(
        (a) => a.id == reserva.agenciaId,
        orElse: () => Agencia(id: '', nombre: 'Sin agencia'),
      );
      return ReservaConAgencia(reserva: reserva, agencia: agencia);
    }).toList();
  }

  static DateTime getTodayDate() {
    return DateTime.now();
  }

  // Método para debug
  static void printDebugInfo() {
    debugPrint('=== FIREBASE DEBUG INFO ===');
    debugPrint('Initialized: $_initialized');
    debugPrint('Reservas en cache: ${_reservasCache.length}');
    debugPrint('Agencias en cache: ${_agenciasCache.length}');
    for (var reserva in _reservasCache) {
      debugPrint(
        '- ${reserva.nombreCliente} (${reserva.fecha}) - Hotel: ${reserva.hotel}',
      );
    }
    for (var agencia in _agenciasCache) {
      debugPrint('- ${agencia.nombre}');
    }
    debugPrint('============================');
  }
}
