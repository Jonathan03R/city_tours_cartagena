import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/services/finanzas/finanzas_service.dart';
import 'package:citytourscartagena/core/services/finanzas/metas_service.dart';
import 'package:citytourscartagena/core/services/reservas/reservas_service.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MetasController extends ChangeNotifier {
  final ReservasController _reservasController;
  final MetasService _metasService;
  final FinanzasService _finanzasService;
  final ReservasService _reservasService;

  MetasController({
    ReservasController? reservasController,
    MetasService? metasService,
    FinanzasService? finanzasService,
  })  : _reservasController = reservasController ?? ReservasController(),
        _metasService = metasService ?? MetasService(),
        _finanzasService = finanzasService ?? FinanzasService(),
        _reservasService = ReservasService();

  /// Verifica si la suma de pasajeros de la semana actual >= meta para el turno dado.
  Future<bool> verificarMetaSemanal(TurnoType turno) async {
    try {
      final fechaHoy = DateTime.now();
      final rango = _finanzasService.obtenerRangoPorFecha(fechaHoy, FiltroPeriodo.semana);

      final sumaPasajeros = await _calcularSumaPasajeros(rango.start, rango.end, turno);

      // Obtener meta activa para la semana y turno
      final metasSnapshot = await _metasService.obtenerMetas();
      final metas = metasSnapshot.docs.map((doc) => doc.data()).toList();

      final metaActiva = metas.firstWhere(
        (meta) {
          final metaData = meta as Map<String, dynamic>;
          final metaInicio = (metaData['fechaInicio'] as Timestamp).toDate();
          final metaFin = (metaData['fechaFin'] as Timestamp).toDate();
          final metaTurno = metaData['turno'] as String;
          return metaData['estado'] == 'activo' &&
                 metaTurno == turno.name && // Cambiado a turno.name
                 metaInicio == rango.start &&
                 metaFin == rango.end;
        },
        orElse: () => null,
      );

      if (metaActiva == null) return false; // No hay meta, no se cumple

      final numeroMeta = (metaActiva as Map<String, dynamic>)['numeroMeta'] as double;
      return sumaPasajeros >= numeroMeta;
    } catch (e) {
      throw Exception('Error verificando meta semanal: $e');
    }
  }

  /// Verifica si una meta específica se cumplió en su rango de fechas.
  Future<bool> verificarMetaPorRango(double numeroMeta, TurnoType turno, DateTime inicio, DateTime fin) async {
    try {
      final sumaPasajeros = await _calcularSumaPasajeros(inicio, fin, turno);
      return sumaPasajeros >= numeroMeta;
    } catch (e) {
      throw Exception('Error verificando meta por rango: $e');
    }
  }

  /// Obtiene la suma de pasajeros para la semana actual y turno dado.
  // Future<int> obtenerSumaPasajerosSemanaActual(TurnoType turno) async {
  //   final fechaHoy = DateTime.now();
  //   final rango = _finanzasService.obtenerRangoPorFecha(fechaHoy, FiltroPeriodo.semana);
  //   return await _calcularSumaPasajeros(rango.start, rango.end, turno);
  // }

  /// Obtiene la meta activa para la semana actual y turno dado.
  Future<double?> obtenerMetaSemanaActual(TurnoType turno) async {
    try {
      final fechaHoy = DateTime.now();
      final rango = _finanzasService.obtenerRangoPorFecha(fechaHoy, FiltroPeriodo.semana);

      final snapshot = await _metasService.obtenerMetaActivaPorSemanaYTurno(rango.start, rango.end, turno);
      if (snapshot.docs.isEmpty) return null;
      final metaData = snapshot.docs.first.data() as Map<String, dynamic>;
      debugPrint('Meta semanal obtenida: $metaData');
      return metaData['numeroMeta'] as double;
    } catch (e) {
      throw Exception('Error obteniendo meta semanal: $e');
    }
  }


  /// Método auxiliar para calcular suma de pasajeros en un rango.
  Future<int> _calcularSumaPasajeros(DateTime inicio, DateTime fin, TurnoType turno) async {
    final reservas = await _reservasController.getAllReservasConAgenciaStream().first;

    final reservasEnRango = reservas.where((reserva) {
      final fecha = reserva.reserva.fecha;
      return !fecha.isBefore(inicio) &&
             !fecha.isAfter(fin) &&
             reserva.reserva.turno == turno;
    }).toList();

    return reservasEnRango.fold<int>(0, (sum, r) => sum + r.reserva.pax);
  }

  /// Agrega una nueva meta usando el servicio.
  Future<void> agregarMeta({
    required double numeroMeta,
    required TurnoType turno,
  }) async {
    await _metasService.agregar(numeroMeta: numeroMeta, turno: turno);
  }

  /// Elimina una meta (cambia estado a inactivo o borra físicamente).
  Future<void> eliminarMeta(String id) async {
    try {
      await FirebaseFirestore.instance.collection('metas').doc(id).delete();
    } catch (e) {
      throw Exception('Error eliminando meta: $e');
    }
  }

  /// Obtiene todas las metas activas.
  Future<QuerySnapshot> obtenerMetas() async {
    return await _metasService.obtenerMetas();
  }

  /// Obtiene todas las metas (activas e inactivas) para historial.
  Future<QuerySnapshot> obtenerTodasMetas() async {
    return await _metasService.obtenerTodasMetas();
  }

//   Future<int> obtenerSumaPasajerosSemanaActualTurnoActual() async {
//   final fechaHoy = DateTime.now();
//   final rango = _finanzasService.obtenerRangoPorFecha(fechaHoy, FiltroPeriodo.semana);
//   final turno = Formatters.getTurnoActual().name; // O pásalo como String si tu servicio lo pide
//   // Si quieres todos los turnos, pásalo sin turno: reservasService.obtenerSumaPasajerosPorRango(rango.start, rango.end)
//   return await _reservasService.obtenerSumaPasajerosPorRango(rango.start, rango.end, turno: turno);
// }
  
Future<int> obtenerSumaPasajerosSemanaActualTurno(TurnoType turno) async {
  final fechaHoy = DateTime.now();
  final rango = _finanzasService.obtenerRangoPorFecha(fechaHoy, FiltroPeriodo.semana);
  return await _reservasService.obtenerSumaPasajerosPorRango(rango.start, rango.end, turno: turno.name);
}

  /// Obtiene la meta activa para la semana actual usando el turno actual (mañana o tarde).
  Future<double?> obtenerMetaSemanaActualTurnoActual() async {
    final turno = Formatters.getTurnoActual();
    return await obtenerMetaSemanaActual(turno);
  }

  Future<List<Map<String, dynamic>>> obtenerEstadoSemanaActual() async {
  final estados = <Map<String, dynamic>>[];
  final fechaHoy = DateTime.now();
  final rango = _finanzasService.obtenerRangoPorFecha(fechaHoy, FiltroPeriodo.semana);

  for (final turno in TurnoType.values) {
    try {
      final cumplida = await verificarMetaSemanal(turno);
      final pasajeros = await _reservasService.obtenerSumaPasajerosPorRango(
        rango.start,
        rango.end,
        turno: turno.name,
      );
      final meta = await obtenerMetaSemanaActual(turno);
      estados.add({
        'turno': turno.label,
        'pasajeros': pasajeros,
        'meta': meta ?? 0,
        'cumplida': cumplida,
      });
    } catch (e) {
      debugPrint('Error obteniendo estado para $turno: $e');
    }
  }
  return estados;
  }
}