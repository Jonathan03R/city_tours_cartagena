import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:citytourscartagena/core/services/servicios/servicios_service.dart';
import 'package:flutter/material.dart';

class ServiciosController extends ChangeNotifier {
  final ServiciosService _servicio;
  List<TipoServicio> _tiposServicios = [];
  bool _isLoading = false;

  ServiciosController(this._servicio);

  List<TipoServicio> get tiposServicios => _tiposServicios;
  bool get isLoading => _isLoading;

  Future<void> cargarTiposServicios(int operadorCodigo) async {
    _isLoading = true;
    notifyListeners();
    try {
      _tiposServicios = await _servicio.obtenerTiposServicios(
        operadorCodigo: operadorCodigo,
      );
    } catch (e) {
      debugPrint('Error cargando tipos de servicios: $e');
      _tiposServicios = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> crearTipoServicio({
    required int operadorCodigo,
    required String descripcion,
    required int creadoPor,
  }) async {
    try {
      final nuevo = await _servicio.crearTipoServicio(
        operadorCodigo: operadorCodigo,
        descripcion: descripcion,
        creadoPor: creadoPor,
      );
      // Recargar lista después de crear
      await cargarTiposServicios(operadorCodigo);
      return nuevo;
    } catch (e) {
      debugPrint('Error creando tipo de servicio: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> actualizarTipoServicio({
    required int tipoServicioCodigo,
    required String descripcion,
    required bool activo,
    required int actualizadoPor,
    required int operadorCodigo,
  }) async {
    try {
      final actualizado = await _servicio.actualizarTipoServicio(
        tipoServicioCodigo: tipoServicioCodigo,
        descripcion: descripcion,
        activo: activo,
        actualizadoPor: actualizadoPor,
      );
      await cargarTiposServicios(operadorCodigo);
      return actualizado;
    } catch (e) {
      debugPrint('Error actualizando tipo de servicio: $e');
      return null;
    }
  }
}
