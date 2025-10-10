import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:citytourscartagena/core/services/filtros/estado_reserva/estados_reserva.dart';
import 'package:citytourscartagena/core/services/filtros/servicios/servicios_service.dart';
import 'package:flutter/material.dart';

class ServiciosController extends ChangeNotifier {
  final ServiciosService _servicio;
  final EstadosReservaService _estadosService = EstadosReservaService();
  List<TipoServicio> _tiposServicios = [];
  List<Map<String, dynamic>> _estadosReservas = [];
  bool _isLoading = false;
  bool _isLoadingEstados = false;

  ServiciosController(this._servicio);

  List<TipoServicio> get tiposServicios => _tiposServicios;
  List<Map<String, dynamic>> get estadosReservas => _estadosReservas;
  bool get isLoading => _isLoading;
  bool get isLoadingEstados => _isLoadingEstados;

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

  Future<void> cargarEstadosReservas() async {
    _isLoadingEstados = true;
    notifyListeners();
    try {
      _estadosReservas = await _estadosService.obtenerEstadosReservas();
    } catch (e) {
      debugPrint('Error cargando estados de reservas: $e');
      _estadosReservas = [];
    } finally {
      _isLoadingEstados = false;
      notifyListeners();
    }
  }
}
