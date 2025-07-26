import 'dart:async';

import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/services/configuracion_service.dart';
import 'package:flutter/material.dart';

class ConfiguracionController extends ChangeNotifier {
  Configuracion? _configuracion;
  StreamSubscription<Configuracion?>? _configSub;

  Configuracion? get configuracion => _configuracion;

  ConfiguracionController() {
    _iniciarStreamConfiguracion();
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
    super.dispose();
  }
}
