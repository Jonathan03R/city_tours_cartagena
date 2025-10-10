import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservasSupabaseService {
  final SupabaseClient _client;

  ReservasSupabaseService(this._client);

  // RPC: devuelve los datos consolidados (tu función grande)
  // Future<List<ReservaResumen>> obtenerResumenReservas({
  //   required int agenciaId,
  //   required int operadorId,
  // }) async {
  //   final response = await _client.rpc(
  //     'obtener_resumen_reservas',
  //     params: {'p_agencia_codigo': agenciaId, 'p_operador_codigo': operadorId},
  //   );
  //   final data = response as List;
  //   return data
  //       .map((e) => ReservaResumen.fromJson(e as Map<String, dynamic>))
  //       .toList();
  // }

  Future<Map<String, dynamic>> eliminarReserva({
    required int reservaId,
    required int usuarioId,
  }) async {
    final ahora = DateTime.now().toIso8601String();

    try {
      final result = await Supabase.instance.client
          .from('reservas')
          .update({
            'reserva__fecha_actualizacion': ahora,
            'reserva_activo': false,
            'reserva_actualizado_por': usuarioId,
          })
          .eq('reserva_codigo', reservaId)
          .select()
          .single();
      return result;
    } on PostgrestException catch (e) {
      throw Exception('Error al actualizar la reserva: ${e.message}');
    } catch (e, s) {
      debugPrint('eliminarReserva error: $e\n$s');
      throw Exception('No se pudo actualizar la reserva: ${e.toString()}');
    }
  }

  Stream<List<Map<String, dynamic>>> streamEventosReservasAgencia({
    required int agenciaId,
  }) {
    return _client
        .from('reservas')
        .stream(primaryKey: ['reserva_codigo'])
        .eq('agencia_codigo', agenciaId)
        .map((maps) => maps.map((e) => e).toList());
  }

  Future<int> contarReservas({
    required int operadorId,
    int? agenciaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? tipoServicioCodigo,
    int? estadoCodigo,
  }) async {
    try {
      debugPrint(
        'Contando reservas con params: operadorId: $operadorId, agenciaId: $agenciaId, fechaInicio: $fechaInicio, fechaFin: $fechaFin, tipoServicioCodigo: $tipoServicioCodigo, estadoCodigo: $estadoCodigo',
      );
      var consulta = _client
          .from('reservas')
          .select('reserva_codigo')
          .eq('operador_codigo', operadorId)
          .eq('reserva_activo', true);

      if (agenciaId != null) {
        consulta = consulta.eq('agencia_codigo', agenciaId);
      }
      if (fechaInicio != null) {
        consulta = consulta.gte('reserva_fecha', fechaInicio.toIso8601String());
      }
      if (fechaFin != null) {
        consulta = consulta.lte('reserva_fecha', fechaFin.toIso8601String());
      }
      if (tipoServicioCodigo != null) {
        consulta = consulta.eq('tipo_servicio_codigo', tipoServicioCodigo);
      }
      if (estadoCodigo != null) {
        consulta = consulta.eq('estado_codigo', estadoCodigo);
      }

      final respuesta = await consulta;
      debugPrint('Número de reservas contadas: ${(respuesta as List).length}');
      return (respuesta as List).length;
    } catch (e, s) {
      debugPrint('contarReservas error: $e\n$s');
      throw Exception('No se pudo contar reservas: ${e.toString()}');
    }
  }

  Future<List<ReservaResumen>> obtenerResumenReservasPaginado({
    required int operadorId,
    required int limit,
    required int offset,
    int? agenciaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? tipoServicioCodigo,
    int? estadoCodigo,
  }) async {
    try {
      final params = {
        'p_operador_codigo': operadorId,
        if (agenciaId != null) 'p_agencia_codigo': agenciaId,
        if (fechaInicio != null)
          'p_fecha_inicio': fechaInicio.toIso8601String(),
        if (fechaFin != null) 'p_fecha_fin': fechaFin.toIso8601String(),
        if (tipoServicioCodigo != null)
          'p_tipo_servicio_codigo': tipoServicioCodigo,
        if (estadoCodigo != null) 'p_estado_codigo': estadoCodigo,
        'p_limit': limit,
        'p_offset': offset,
      };
      debugPrint('RPC params: $params');
      final response = await _client.rpc(
        'obtener_resumen_reservas',
        params: params,
      );

      final data = response as List;
      debugPrint('Data length from RPC: ${data.length}');
      return data
          .map((e) => ReservaResumen.fromJson(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Error en obtenerResumenReservasPaginado: ${e.message}');
      throw Exception('Error al obtener reservas: ${e.message}');
    } catch (e, s) {
      debugPrint('Error inesperado: $e\n$s');
      throw Exception('Error inesperado al obtener reservas: ${e.toString()}');
    }
  }
}
