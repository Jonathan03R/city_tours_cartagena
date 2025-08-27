import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class GastosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> agregar({
    required double monto,
    required String descripcion,
    required DateTime fecha,
  }) async {
    try {
      await _firestore.collection('gastos').add({
        'monto': monto,
        'descripcion': descripcion,
        'fecha': fecha,
        'estado': 'activo',
      });
    } catch (e) {
      throw Exception('Error al agregar gasto: $e');
    }
  }

  Stream<QuerySnapshot> obtenerEnTiempoReal({
    required int limite,
    DocumentSnapshot? ultimoDocumento,
  }) {
    try {
      Query query = _firestore
          .collection('gastos')
          .where('estado', isNotEqualTo: 'inactivo') // Excluye los inactivos
          .orderBy('fecha')
          .limit(limite);

      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }

      return query.snapshots(); // Devuelve un Stream en tiempo real
    } catch (e) {
      throw Exception('Error al obtener gastos en tiempo real: $e');
    }
  }

  Future<List<QueryDocumentSnapshot>> obtener({
    required int limite,
    DocumentSnapshot? ultimoDocumento,
  }) async {
    try {
      Query query = _firestore
          .collection('gastos')
          .where('estado', isNotEqualTo: 'inactivo') // Excluye los inactivos
          .orderBy('fecha')
          .limit(limite);

      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }

      QuerySnapshot snapshot = await query.get(); // Realiza una consulta única
      return snapshot.docs; // Devuelve los documentos obtenidos
    } catch (e) {
      throw Exception('Error al obtener gastos: $e');
    }
  }

  Future<int> obtenerCantidadGastos() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('gastos').get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error al obtener cantidad de gastos: $e');
    }
  }

  Future<void> eliminar(String id) async {
    try {
      await _firestore.collection('gastos').doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar gasto: $e');
    }
  }

  Future<double> obtenerSumaDeGastosEntre(DateTime inicio, DateTime fin) async {
    try {
      final snapshot = await _firestore
          .collection('gastos')
          .where('estado', isEqualTo: 'activo')
          .where('fecha', isGreaterThanOrEqualTo: inicio)
          .where('fecha', isLessThanOrEqualTo: fin)
          .get();
      return snapshot.docs.fold<double>(0.0, (suma, doc) {
        final data = doc.data();
        return suma + (data['monto'] as num).toDouble();
      });
    } catch (e) {
      throw Exception('Error al obtener la suma de gastos: $e');
    }
  }
}
