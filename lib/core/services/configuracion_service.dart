import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/configuracion.dart';
import 'package:citytourscartagena/core/models/enum/tipo_documento.dart';

class ConfiguracionService {
  static final _doc = FirebaseFirestore.instance
      .collection('configuracion')
      .doc('general');

  /// NUEVO: Stream en tiempo real para configuración
  static Stream<Configuracion?> getConfiguracionStream() {
    return _doc.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return Configuracion.fromMap(snapshot.data()!);
    });
  }

  /// Obtiene la configuración una sola vez
  static Future<Configuracion?> getConfiguracion() async {
    final snapshot = await _doc.get();
    if (!snapshot.exists) return null;
    return Configuracion.fromMap(snapshot.data()!);
  }

  /// Actualiza el precio por asiento de mañana
  static Future<void> actualizarPrecioManana(double nuevoPrecio) async {
    await _doc.update({
      'precio_general_asiento_temprano': nuevoPrecio,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Precio mañana actualizado: $nuevoPrecio');
  }

  /// Actualiza el precio por asiento de tarde
  static Future<void> actualizarPrecioTarde(double nuevoPrecio) async {
    await _doc.update({
      'precio_general_asiento_tarde': nuevoPrecio,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Precio tarde actualizado: $nuevoPrecio');
  }
  
  /// Actualiza el tipo de documento
  static Future<void> actualizarTipoDocumento(TipoDocumento tipo) async {
    await _doc.update({
      'tipo_documento': tipo.toString().split('.').last,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Tipo de documento actualizado: $tipo');
  }

  /// Actualiza el número de documento
  static Future<void> actualizarNumeroDocumento(String numero) async {
    await _doc.update({
      'numero_documento': numero,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Número de documento actualizado: $numero');
  }

  /// Actualiza el nombre del beneficiario
  static Future<void> actualizarNombreBeneficiario(String nombre) async {
    await _doc.update({
      'nombre_beneficiario': nombre,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Nombre beneficiario actualizado: $nombre');
  }

  /// Inicializar configuración con ambos precios
  static Future<void> inicializarConfiguracion() async {
    final snapshot = await _doc.get();

    if (!snapshot.exists) {
      await _doc.set({
        'precio_general_asiento_temprano': 60000.0,
        'precio_general_asiento_tarde': 55000.0,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ Configuración inicial creada con precios separados.');
    } else {
      debugPrint('🔄 Configuración ya existe.');
    }
  }
}
