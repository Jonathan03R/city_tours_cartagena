import 'package:citytourscartagena/core/models/enum/tipo_documento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/configuracion.dart';

class ConfiguracionService {
  /// Actualiza el estado de cupos cerradas

  /// Actualiza el WhatsApp de contacto
  static Future<void> actualizarWhatsapp(String? numero) async {
    await _doc.update({
      'contact_whatsapp': numero,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ WhatsApp de contacto actualizado: $numero');
  }
  /// Actualiza el nombre de la empresa
  static Future<void> actualizarNombreEmpresa(String nombre) async {
    await _doc.update({
      'nombre_empresa': nombre,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Nombre empresa actualizado: $nombre');
  }

  /// Actualiza el máximo de cupos para el turno de la mañana
  static Future<void> actualizarMaxCuposTurnoManana(int cupos) async {
    await _doc.update({
      'max_cupos_turno_manana': cupos,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Max cupos turno mañana actualizado: $cupos');
  }

  /// Actualiza el máximo de cupos para el turno de la tarde
  static Future<void> actualizarMaxCuposTurnoTarde(int cupos) async {
    await _doc.update({
      'max_cupos_turno_tarde': cupos,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Max cupos turno tarde actualizado: $cupos');
  }
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

  // Métodos para adicionales
  static final _adicionalesCollection = FirebaseFirestore.instance.collection('adicionales');

  /// Agregar un adicional
  static Future<void> agregarAdicional(String nombre, double precio, String icono) async {
    await _adicionalesCollection.add({
      'adicionales_nombres': nombre,
      'adicionales_precio': precio,
      'icono': icono,
      'activo': true,
      'creado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Adicional agregado: $nombre - $precio - $icono');
  }

  /// Actualizar un adicional
  static Future<void> actualizarAdicional(String docId, String nombre, double precio, String icono) async {
    await _adicionalesCollection.doc(docId).update({
      'adicionales_nombres': nombre,
      'adicionales_precio': precio,
      'icono': icono,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Adicional actualizado: $docId - $nombre - $precio - $icono');
  }

  /// Eliminar adicional (marcar inactivo)
  static Future<void> eliminarAdicional(String docId) async {
    await _adicionalesCollection.doc(docId).update({
      'activo': false,
      'eliminado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Adicional marcado como inactivo: $docId');
  }

  /// Activar adicional
  static Future<void> activarAdicional(String docId) async {
    await _adicionalesCollection.doc(docId).update({
      'activo': true,
      'actualizado_en': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ Adicional activado: $docId');
  }

  /// Obtener stream de adicionales
  static Stream<List<Map<String, dynamic>>> getAdicionalesStream() {
    return _adicionalesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Obtener lista de adicionales una vez
  static Future<List<Map<String, dynamic>>> getAdicionales() async {
    final snapshot = await _adicionalesCollection.get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
