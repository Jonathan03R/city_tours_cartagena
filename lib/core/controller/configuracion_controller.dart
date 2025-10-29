import 'dart:async';

import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/enum/tipo_documento.dart';
import 'package:citytourscartagena/core/services/configuracion_service.dart';
import 'package:flutter/material.dart';

class ConfiguracionController extends ChangeNotifier {
 
  /// Actualizar WhatsApp de contacto
  Future<void> actualizarWhatsapp(String? numero) async {
    try {
      await ConfiguracionService.actualizarWhatsapp(numero);
    } catch (e) {
      debugPrint('❌ Error actualizando WhatsApp: $e');
      rethrow;
    }
  }
  /// Actualizar nombre de la empresa
  Future<void> actualizarNombreEmpresa(String nombre) async {
    try {
      await ConfiguracionService.actualizarNombreEmpresa(nombre);
    } catch (e) {
      debugPrint('❌ Error actualizando nombre de empresa: $e');
      rethrow;
    }
  }

  /// Actualizar max cupos turno mañana
  Future<void> actualizarMaxCuposTurnoManana(int cupos) async {
    try {
      await ConfiguracionService.actualizarMaxCuposTurnoManana(cupos);
    } catch (e) {
      debugPrint('❌ Error actualizando max cupos turno mañana: $e');
      rethrow;
    }
  }

  /// Actualizar max cupos turno tarde
  Future<void> actualizarMaxCuposTurnoTarde(int cupos) async {
    try {
      await ConfiguracionService.actualizarMaxCuposTurnoTarde(cupos);
    } catch (e) {
      debugPrint('❌ Error actualizando max cupos turno tarde: $e');
      rethrow;
    }
  }
  Configuracion? _configuracion;
  StreamSubscription<Configuracion?>? _configSub;

  Configuracion? get configuracion => _configuracion;

  // Adicionales
  List<Map<String, dynamic>> _adicionales = [];
  StreamSubscription<List<Map<String, dynamic>>>? _adicionalesSub;

  List<Map<String, dynamic>> get adicionales => _adicionales;

  /// Agregar adicional
  Future<void> agregarAdicional(String nombre, double precio, String icono) async {
    try {
      await ConfiguracionService.agregarAdicional(nombre, precio, icono);
    } catch (e) {
      debugPrint('❌ Error agregando adicional: $e');
      rethrow;
    }
  }

  /// Actualizar adicional
  Future<void> actualizarAdicional(String docId, String nombre, double precio, String icono) async {
    try {
      await ConfiguracionService.actualizarAdicional(docId, nombre, precio, icono);
    } catch (e) {
      debugPrint('❌ Error actualizando adicional: $e');
      rethrow;
    }
  }

  /// Eliminar adicional (marcar inactivo)
  Future<void> eliminarAdicional(String docId) async {
    try {
      await ConfiguracionService.eliminarAdicional(docId);
    } catch (e) {
      debugPrint('❌ Error eliminando adicional: $e');
      rethrow;
    }
  }

  /// Activar adicional
  Future<void> activarAdicional(String docId) async {
    try {
      await ConfiguracionService.activarAdicional(docId);
    } catch (e) {
      debugPrint('❌ Error activando adicional: $e');
      rethrow;
    }
  }

  /// Iniciar stream para adicionales
  void _iniciarStreamAdicionales() {
    _adicionalesSub = ConfiguracionService.getAdicionalesStream().listen(
      (adicionales) {
        _adicionales = adicionales;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Error en stream de adicionales: $error');
      },
    );
  }

  ConfiguracionController() {
    _iniciarStreamConfiguracion();
    _iniciarStreamAdicionales();
  }

  /// NUEVO: Stream en tiempo real para configuración
  void _iniciarStreamConfiguracion() {
    _configSub = ConfiguracionService.getConfiguracionStream().listen(
      (config) {
        debugPrint('🔄 Configuración actualizada en tiempo real: ${config?.precioGeneralAsientoTemprano} / ${config?.precioGeneralAsientoTarde}');
        _configuracion = config;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('❌ Error en stream de configuración: $error');
      },
    );
  }

  /// Actualizar precio de mañana
  Future<void> actualizarPrecioManana(double nuevoPrecio) async {
    try {
      await ConfiguracionService.actualizarPrecioManana(nuevoPrecio);
      // No necesitamos recargar manualmente, el stream lo hará
    } catch (e) {
      debugPrint('❌ Error actualizando precio mañana: $e');
      rethrow;
    }
  }

  /// Actualizar precio de tarde
  Future<void> actualizarPrecioTarde(double nuevoPrecio) async {
    try {
      await ConfiguracionService.actualizarPrecioTarde(nuevoPrecio);
      // No necesitamos recargar manualmente, el stream lo hará
    } catch (e) {
      debugPrint('❌ Error actualizando precio tarde: $e');
      rethrow;
    }
  }
  
  /// Actualizar tipo de documento
  Future<void> actualizarTipoDocumento(TipoDocumento tipo) async {
    try {
      await ConfiguracionService.actualizarTipoDocumento(tipo);
    } catch (e) {
      debugPrint('❌ Error actualizando tipo de documento: $e');
      rethrow;
    }
  }

  /// Actualizar número de documento
  Future<void> actualizarNumeroDocumento(String numero) async {
    try {
      await ConfiguracionService.actualizarNumeroDocumento(numero);
    } catch (e) {
      debugPrint('❌ Error actualizando número de documento: $e');
      rethrow;
    }
  }

  /// Actualizar nombre beneficiario
  Future<void> actualizarNombreBeneficiario(String nombre) async {
    try {
      await ConfiguracionService.actualizarNombreBeneficiario(nombre);
    } catch (e) {
      debugPrint('❌ Error actualizando nombre beneficiario: $e');
      rethrow;
    }
  }

  /// Método helper para obtener precio según turno
  double getPrecioParaTurno(String turno) {
    if (_configuracion == null) return 0.0;
    return _configuracion!.precioParaTurno(turno);
  }

  /// Obtener precio de mañana
  double get precioManana => _configuracion?.precioGeneralAsientoTemprano ?? 0.0;

  /// Obtener precio de tarde
  double get precioTarde => _configuracion?.precioGeneralAsientoTarde ?? 0.0;

  @override
  void dispose() {
    _configSub?.cancel();
    _adicionalesSub?.cancel();
    super.dispose();
  }
}
