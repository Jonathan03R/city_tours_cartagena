import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/services/finanzas/finanzas_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MetasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FinanzasService _finanzasService = FinanzasService();

  Future<void> agregar({
    required double numeroMeta,
    required TurnoType turno,
  }) async {
    try {
      final fechaHoy = DateTime.now();
      final rango = _finanzasService.obtenerRangoPorFecha(fechaHoy, FiltroPeriodo.semana);

      // Verificar si ya existe una meta para esta semana y turno
      final existe = await _existeMetaParaSemana(rango.start, rango.end, turno);
      if (existe) {
        throw Exception('Ya existe una meta activa para esta semana y turno. ¡No seas repetitivo!');
      }

      await _firestore.collection('metas').add({
        'numeroMeta': numeroMeta,
        'turno': turno.name, // Cambiado a turno.name para guardar solo "manana", "tarde", etc.
        'fechaCreacion': fechaHoy,
        'fechaInicio': rango.start,
        'fechaFin': rango.end,
        'estado': 'activo',
      });
    } catch (e) {
      throw Exception('Error al agregar meta: $e');
    }
  }

  Future<bool> _existeMetaParaSemana(DateTime inicio, DateTime fin, TurnoType turno) async {
    try {
      final snapshot = await _firestore
          .collection('metas')
          .where('estado', isEqualTo: 'activo')
          .where('turno', isEqualTo: turno.name) // Cambiado a turno.name
          .where('fechaInicio', isEqualTo: inicio)
          .where('fechaFin', isEqualTo: fin)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar existencia de meta: $e');
    }
  }

  Future<QuerySnapshot> obtenerMetas({int limite = 10}) async {
    try {
      return await _firestore
          .collection('metas')
          .where('estado', isEqualTo: 'activo')
          .orderBy('fechaCreacion', descending: true)
          .limit(limite)
          .get();
    } catch (e) {
      throw Exception('Error al obtener metas: $e');
    }
  }

  // Nuevo método para obtener todas las metas (activas e inactivas) para historial
  Future<QuerySnapshot> obtenerTodasMetas({int limite = 10}) async {
    try {
      return await _firestore
          .collection('metas')
          .orderBy('fechaCreacion', descending: true)
          .limit(limite)
          .get();
    } catch (e) {
      throw Exception('Error al obtener todas las metas: $e');
    }
  }

  Future<void> actualizar({
    required String id,
    required double numeroMeta,
    required TurnoType turno,
  }) async {
    try {
      await _firestore.collection('metas').doc(id).update({
        'numeroMeta': numeroMeta,
        'turno': turno.name, // Cambiado a turno.name
      });
    } catch (e) {
      throw Exception('Error al actualizar meta: $e');
    }
  }
}