import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/services/finanzas/finanzas_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MetasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FinanzasService _finanzasService = FinanzasService();

  Future<void> agregar({
    required double numeroMeta,
    required TurnoType turno,
  }) async {
    try {
      final fechaHoy = DateTime.now();
      final rango = _finanzasService.obtenerRangoPorFecha(
        fechaHoy,
        FiltroPeriodo.semana,
      );

      // Buscar si ya existe una meta para esta semana y turno
      final existingDocId = await _obtenerMetaExistente(
        rango.start,
        rango.end,
        turno,
      );
      if (existingDocId != null) {
        // Actualizar la meta existente
        await actualizar(id: existingDocId, numeroMeta: numeroMeta, turno: turno);
        return;
      }

      // Si no existe, agregar nueva
      await _firestore.collection('metas').add({
        'numeroMeta': numeroMeta,
        'turno': turno.name,
        'fechaCreacion': fechaHoy,
        'fechaInicio': rango.start,
        'fechaFin': rango.end,
        'estado': 'activo',
      });
    } catch (e) {
      throw Exception('Error al agregar/actualizar meta: $e');
    }
  }

    Future<String?> _obtenerMetaExistente(
    DateTime inicio,
    DateTime fin,
    TurnoType turno,
  ) async {
    try {
      final startOfWeek = DateTime(inicio.year, inicio.month, inicio.day);
      final endOfWeek = DateTime(fin.year, fin.month, fin.day, 23, 59, 59, 999);
      final snapshot = await _firestore
          .collection('metas')
          .where('estado', isEqualTo: 'activo')
          .where('turno', isEqualTo: turno.name)
          .where(
            'fechaInicio',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .where(
            'fechaInicio',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek),
          )
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty ? snapshot.docs.first.id : null;
    } catch (e) {
      throw Exception('Error al buscar meta existente: $e');
    }
  }

  // Future<bool> _existeMetaParaSemana(
  //   DateTime inicio,
  //   DateTime fin,
  //   TurnoType turno,
  // ) async {
  //   try {
  //     final startOfWeek = DateTime(inicio.year, inicio.month, inicio.day);
  //     final endOfWeek = DateTime(fin.year, fin.month, fin.day, 23, 59, 59, 999);
  //     final snapshot = await _firestore
  //         .collection('metas')
  //         .where('estado', isEqualTo: 'activo')
  //         .where('turno', isEqualTo: turno.name)
  //         .where(
  //           'fechaInicio',
  //           isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
  //         )
  //         .where(
  //           'fechaInicio',
  //           isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek),
  //         )
  //         .get();
  //     return snapshot.docs.isNotEmpty;
  //   } catch (e) {
  //     throw Exception('Error al verificar existencia de meta: $e');
  //   }
  // }

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

  Future<QuerySnapshot> obtenerMetaActivaPorSemanaYTurno(
    DateTime inicio,
    DateTime fin,
    TurnoType turno,
  ) async {
    try {
      debugPrint('Obteniendo metas para semana $inicio - $fin y turno $turno');
      final startOfWeek = DateTime(inicio.year, inicio.month, inicio.day);
      final endOfWeek = DateTime(fin.year, fin.month, fin.day, 23, 59, 59, 999);
      final datos = await _firestore
          .collection('metas')
          .where('estado', isEqualTo: 'activo')
          .where('turno', isEqualTo: turno.name)
          .where(
            'fechaInicio',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek),
          )
          .where(
            'fechaInicio',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek),
          )
          .limit(1)
          .get();
      debugPrint('Datos: ${datos.docs.map((doc) => doc.data()).toList()}');
      return datos;
    } catch (e) {
      throw Exception('Error obteniendo meta activa: $e');
    }
  }
}
