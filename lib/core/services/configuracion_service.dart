import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/configuracion.dart';

class ConfiguracionService {
  static final _doc = FirebaseFirestore.instance
      .collection('configuracion')
      .doc('general');

  /// Obtiene la configuración general de la aplicación
  /// Retorna un objeto Configuracion o null si no existe
  static Future<Configuracion?> getConfiguracion() async {
    final snapshot = await _doc.get();
    if (!snapshot.exists) return null;
    return Configuracion.fromMap(snapshot.data()!);
  }

  /// Actualiza el precio por asiento en la configuración
  /// @param nuevoPrecio El nuevo precio por asiento a establecer
  static Future<void> actualizarPrecio(double nuevoPrecio) async {
    await _doc.update({
      'precio_por_asiento': nuevoPrecio,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
  }

  static Future<double> getPrecioPorAsiento() async {
    final snapshot = await _doc.get();
    if (!snapshot.exists) return 0.0;
    final value = snapshot.data()?['precio_por_asiento'];
    return (value is num) ? value.toDouble() : 0.0;
  }

  static Future<void> inicializarConfiguracion() async {
    final docRef = FirebaseFirestore.instance
        .collection('configuracion')
        .doc('general');

    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'precio_por_asiento': 5000,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Configuración inicial creada.');
    } else {
      debugPrint('🔄 Configuración ya existe.');
    }
  }
}
