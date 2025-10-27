import 'dart:async';

import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/models/agencia/perfil_agencia.dart';
import 'package:citytourscartagena/core/models/colores/color_model.dart';
import 'package:citytourscartagena/core/models/reservas/crear_reserva_dto.dart';
import 'package:citytourscartagena/core/models/reservas/precio_servicio.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_contacto.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:citytourscartagena/core/services/reservas/colores_service.dart';
import 'package:citytourscartagena/core/services/reservas/pagos_service.dart';
import 'package:citytourscartagena/core/services/reservas/reservas_contactos.dart';
import 'package:citytourscartagena/core/services/reservas/reservas_service.supabase.dart';
import 'package:flutter/material.dart';

class ControladorDeltaReservas extends ChangeNotifier {
  final ReservasSupabaseService _servicio;
  final PagosService _pagosService;
  final ColoresService _coloresService;
  final ReservasContactosService _contactosService;
  final AgenciasService agenciasService = AgenciasService();
  final Duration debounceDuracion;

  final OperadoresController _operadoresController;

  // List<ReservaResumen> _reservasActuales = [];
  final StreamController<List<ReservaResumen>> _reservasDeltaController =
      StreamController.broadcast();

  Stream<List<ReservaResumen>> get reservasStream =>
      _reservasDeltaController.stream;

  StreamSubscription? _suscripcionStream;

  ControladorDeltaReservas(
    this._servicio,
    this._pagosService,
    this._coloresService,
    this._contactosService,
    this._operadoresController, [
    Duration? debounce,
  ]) : debounceDuracion = debounce ?? const Duration(milliseconds: 350);

  Future<Agenciaperfil?> cargarAgenciaPorId(int agenciaId) async {
    return await agenciasService.obtenerAgenciaPorId(agenciaId);
  }

  Future<List<PrecioServicio>> obtenerPreciosServiciosConFallback({
    required int agenciaCodigo,
  }) async {
    try {
      final operador = await _operadoresController.obtenerOperador();
      if (operador == null) {
        debugPrint('Error: No se pudo obtener el operador.');
        return [];
      }

      List<Map<String, dynamic>> preciosAgencia = [];
      try {
        preciosAgencia = await agenciasService.obtenerPreciosServiciosAgencia(
          operadorCodigo: operador.id,
          agenciaCodigo: agenciaCodigo,
        );
      } catch (e) {
        debugPrint('Error al obtener precios de agencia: $e');
        // Continuar con precios globales
      }

      List<Map<String, dynamic>> preciosGlobal = [];
      try {
        preciosGlobal = await agenciasService.obtenerPreciosServiciosOperador(
          operadorCodigo: operador.id,
        );
      } catch (e) {
        debugPrint('Error al obtener precios globales: $e');
        // Si falla global, devolver agencia si hay
        if (preciosAgencia.isNotEmpty) {
          return preciosAgencia
              .map(
                (item) => PrecioServicio(
                  codigo: item['codigo'] ?? 0,
                  precio: (item['precio'] as num?)?.toDouble() ?? 0.0,
                  descripcion: item['descripcion'] ?? 'Sin descripción',
                  origen: 'especial',
                ),
              )
              .toList();
        }
        return [];
      }

      final Map<String, PrecioServicio> preciosPorDescripcion = {};

      for (final item in preciosGlobal) {
        try {
          final descripcion = item['descripcion'] as String?;
          if (descripcion != null) {
            preciosPorDescripcion[descripcion] = PrecioServicio(
              codigo: item['codigo'] ?? 0,
              precio: (item['precio'] as num?)?.toDouble() ?? 0.0,
              descripcion: descripcion,
              origen: 'global',
            );
          }
        } catch (e) {
          debugPrint('Error procesando precio global: $e');
        }
      }

      for (final item in preciosAgencia) {
        try {
          final descripcion = item['descripcion'] as String?;
          if (descripcion != null) {
            preciosPorDescripcion[descripcion] = PrecioServicio(
              codigo: item['codigo'] ?? 0,
              precio: (item['precio'] as num?)?.toDouble() ?? 0.0,
              descripcion: descripcion,
              origen: 'especial',
            );
          }
        } catch (e) {
          debugPrint('Error procesando precio agencia: $e');
        }
      }

      return preciosPorDescripcion.values.toList();
    } catch (e) {
      debugPrint('Error general en obtenerPreciosServiciosConFallback: $e');
      return [];
    }
  }

  int paginaSiguiente(int paginaActual, int totalReservas, int tamanoPagina) {
    final totalPaginas = (totalReservas / tamanoPagina).ceil();
    return paginaActual < totalPaginas ? paginaActual + 1 : totalPaginas;
  }

  int paginaAnterior(int paginaActual) {
    return paginaActual > 1 ? paginaActual - 1 : 1;
  }

  Future<int> contarReservas({
    required int operadorId,
    int? agenciaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? tipoServicioCodigo,
    int? estadoCodigo,
  }) async {
    return await _servicio.contarReservas(
      operadorId: operadorId,
      agenciaId: agenciaId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipoServicioCodigo: tipoServicioCodigo,
      estadoCodigo: estadoCodigo,
    );
  }

  Future<List<ReservaResumen>> obtenerReservasPaginadas({
    required int operadorId,
    int? agenciaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? tipoServicioCodigo,
    int? estadoCodigo,
    required int pagina,
    int tamanoPagina = 10,
  }) async {
    final offset = (pagina - 1) * tamanoPagina;

    final reservas = await _servicio.obtenerResumenReservasPaginado(
      operadorId: operadorId,
      agenciaId: agenciaId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipoServicioCodigo: tipoServicioCodigo,
      estadoCodigo: estadoCodigo,
      limit: tamanoPagina,
      offset: offset,
    );

    // Emitir las reservas al stream
    _reservasDeltaController.add(reservas);

    return reservas;
  }

  Future<Map<String, dynamic>> actualizarObservaciones({
    required int reservaId,
    required String observaciones,
    required int usuarioId,
  }) async {
    return await _servicio.actualizarObservacionesReserva(
      reservaId: reservaId,
      observaciones: observaciones,
      usuarioId: usuarioId,
    );
  }

  Future<double> procesarPago({
    required ReservaResumen reserva,
    int? pagadoPor,
  }) async {
    if (reserva.estadoNombre.toLowerCase() == 'pendiente') {
      // Pagar reserva
      return await _pagosService.pagarReserva(
        reservaCodigo: reserva.reservaCodigo,
        tipoPagoCodigo: 1, // Siempre 1
        pagadoPor: pagadoPor,
      );
    } else if (reserva.estadoNombre.toLowerCase() == 'pagada') {
      // Revertir pago
      return await _pagosService.revertirPago(
        reservaCodigo: reserva.reservaCodigo,
      );
    } else {
      throw Exception(
        'Estado de reserva no válido para procesar pago: ${reserva.estadoNombre}',
      );
    }
  }

  Future<List<ColorModel>> obtenerColores() async {
    return await _coloresService.obtenerColores();
  }

  Future<Map<String, dynamic>> actualizarColorReserva({
    required int reservaId,
    required int colorCodigo,
    required int usuarioId,
  }) async {
    return await _servicio.actualizarColorReserva(
      reservaId: reservaId,
      colorCodigo: colorCodigo,
      usuarioId: usuarioId,
    );
  }

  Future<Map<String, dynamic>> actualizarReserva({
    required int reservaId,
    int? agenciaCodigo,
    String? reservaFecha,
    String? numeroTickete,
    String? numeroHabitacion,
    String? reservaPuntoEncuentro,
    required int usuarioId,
  }) async {
    return await _servicio.actualizarReserva(
      reservaId: reservaId,
      agenciaCodigo: agenciaCodigo,
      reservaFecha: reservaFecha,
      numeroTickete: numeroTickete,
      numeroHabitacion: numeroHabitacion,
      reservaPuntoEncuentro: reservaPuntoEncuentro,
      usuarioId: usuarioId,
    );
  }

  Future<int> crearReservaCompleta({
    required CrearReservaDto dto,
    required List<ReservaContacto> contactos,
  }) async {
    try {
      // Crear la reserva
      final reservaId = await _servicio.crearReserva(dto);

      // Si se creó, insertar contactos
      if (contactos.isNotEmpty) {
        await _contactosService.insertarContactosReserva(
          reservaId: reservaId,
          contactos: contactos,
        );
      }

      return reservaId;
    } catch (e) {
      // Si falla la reserva, no insertar contactos
      rethrow;
    }
  }
}
