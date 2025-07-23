import 'dart:async'; // Importar para StreamSubscription

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
  static StreamSubscription? _agenciasSubscription; // Para escuchar cambios en agencias

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      debugPrint('🔄 Inicializando Firebase Controller...');
      await _firestoreService.initializeDefaultData();

      // Suscribirse al stream de agencias para mantener la caché actualizada en tiempo real
      _agenciasSubscription = _firestoreService.getAgenciasStream().listen((agencias) {
        _agenciasCache = agencias;
        debugPrint('✅ ${_agenciasCache.length} agencias actualizadas en cache (via stream)');
      }, onError: (e) {
        debugPrint('❌ Error en el stream de agencias: $e');
      });

      // Cargar agencias una vez al inicio para asegurar que la caché no esté vacía
      // antes de que el stream entregue el primer evento.
      // Esto es un fallback, el stream debería mantenerla actualizada.
      if (_agenciasCache.isEmpty) {
        _agenciasCache = await _firestoreService.getAllAgencias();
        debugPrint('✅ ${_agenciasCache.length} agencias cargadas inicialmente en cache (fallback)');
      }

      _initialized = true;
      debugPrint('🎉 Firebase Controller inicializado exitosamente');
    } catch (e) {
      debugPrint('❌ Error inicializando Firebase Controller: $e');
    }
  }

  // Método para limpiar la suscripción cuando la app se cierra
  static void dispose() {
    _agenciasSubscription?.cancel();
    debugPrint('🧹 Firebase Controller suscripciones limpiadas.');
  }

  // ========== RESERVAS ==========

  // Método Future existente (no modificado)
  static Future<List<ReservaConAgencia>> getAllReservas() async {
    final raw = await _firestoreService.getAllReservas();
    _reservasCache = raw; // Actualiza la caché de reservas
    return await _combineReservasWithAgencias(raw);
  }

  // Método Stream existente (no modificado)
  static Stream<List<ReservaConAgencia>> getReservasStream() {
    return _firestoreService.getReservasStream().asyncMap((reservas) async {
      _reservasCache = reservas; // Actualiza la caché de reservas
      return await _combineReservasWithAgencias(reservas);
    });
  }

  // Método Future existente (no modificado)
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

  // NUEVO: Método Stream para Reservas por Fecha
  static Stream<List<ReservaConAgencia>> getReservasByFechaStream(
    DateTime fecha,
  ) {
    return _firestoreService.getReservasByFechaStream(fecha).asyncMap((reservas) async {
      // No actualizamos _reservasCache aquí para evitar sobrescribir el stream principal
      return await _combineReservasWithAgencias(reservas);
    });
  }

  // Método Future existente (no modificado)
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

  // NUEVO: Método Stream para Reservas por Rango de Fechas
  static Stream<List<ReservaConAgencia>> getReservasByDateRangeStream(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _firestoreService.getReservasByDateRangeStream(startDate, endDate).asyncMap((reservas) async {
      return await _combineReservasWithAgencias(reservas);
    });
  }

  // Método Future existente (no modificado)
  static Future<List<ReservaConAgencia>> getReservasLastWeek() async {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return await getReservasByDateRange(lastWeek, now);
  }

  // NUEVO: Método Stream para Reservas de la Última Semana
  static Stream<List<ReservaConAgencia>> getReservasLastWeekStream() {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return getReservasByDateRangeStream(lastWeek, now);
  }

  // Método Future existente (no modificado)
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

  // NUEVO: Método Stream para Reservas por Agencia
  static Stream<List<ReservaConAgencia>> getReservasByAgenciaStream(
    String agenciaId,
  ) {
    return _firestoreService.getReservasByAgenciaStream(agenciaId).asyncMap((reservas) async {
      return await _combineReservasWithAgencias(reservas);
    });
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

  // Método Stream existente (no modificado)
  static Stream<List<AgenciaConReservas>> getAgenciasStream() {
    return _firestoreService.getAgenciasStream().asyncMap((agencias) async {
      _agenciasCache = agencias; // Actualiza la caché de agencias
      // Calcular total de reservas para cada agencia
      final agenciasConReservas = <AgenciaConReservas>[];
      for (final agencia in agencias) {
        // Usamos la caché de reservas para calcular el total, que se actualiza
        // con el stream principal de reservas.
        final totalReservas = _reservasCache
            .where((r) => r.agenciaId == agencia.id)
            .length;
        agenciasConReservas.add(
          AgenciaConReservas(
            id: agencia.id,
            nombre: agencia.nombre,
            imagenUrl: agencia.imagenUrl,
            totalReservas: totalReservas,
          ),
        );
      }
      return agenciasConReservas;
    });
  }

  // Método existente (no modificado)
  static List<AgenciaConReservas> getAllAgencias() {
    return _agenciasCache.map((agencia) {
      final totalReservas = _reservasCache
          .where((r) => r.agenciaId == agencia.id)
          .length;
      return AgenciaConReservas(
        id: agencia.id,
        nombre: agencia.nombre,
        imagenUrl: agencia.imagenUrl,
        totalReservas: totalReservas,
      );
    }).toList();
  }

  // Método existente (no modificado)
  static Agencia? getAgenciaById(String id) {
    try {
      return _agenciasCache.firstWhere((a) => a.id == id);
    } catch (e) {
      debugPrint('❌ Agencia no encontrada: $id');
      return null;
    }
  }

  // Método existente (no modificado)
  static List<Agencia> searchAgencias(String query) {
    return _agenciasCache
        .where(
          (agencia) =>
              agencia.nombre.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Método existente (no modificado)
  static Future<Agencia> addAgencia(String nombre) async {
    try {
      final newAgencia = Agencia(id: '', nombre: nombre);
      await _firestoreService.addAgencia(newAgencia);
      // Recargar cache (esto se hará automáticamente por el listener del stream de agencias)
      // _agenciasCache = await _firestoreService.getAllAgencias(); // Ya no es necesario aquí
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
      debugPrint('⚠️ Caché de agencias cargada por fallback en _combineReservasWithAgencias.');
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
