import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgenciasService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> obtenerDeudaAgencia(int agenciaId) async {
    final response = await _client.rpc(
      'obtener_deuda_agencia',
      params: {'p_agencia_id': agenciaId},
    );
    return response[0]
        as Map<String, dynamic>; // Asume que devuelve lista con un objeto
  }

  Future<List<AgenciaSupabase>> obtenerAgenciasDeOperador({
    required int operadorCod,
  }) async {
    final response = await _client
        .from('operadores_agencias')
        .select('*, agencias(*)')
        .eq('operador_codigo', operadorCod)
        .eq('agencias.agencia_activo', true);

    final agencias = response
        .where((item) => item['agencias'] != null)
        .map(
          (item) =>
              AgenciaSupabase.fromMap(item['agencias'] as Map<String, dynamic>),
        )
        .toList();

    // Obtener deuda para cada agencia
    final futures = agencias.map((agencia) async {
      try {
        final deudaData = await obtenerDeudaAgencia(agencia.codigo);
        return agencia.copyWith(
          deuda: (deudaData['deuda_total'] as num?)?.toDouble() ?? 0.0,
          totalPasajeros: (deudaData['total_pasajeros'] as int?) ?? 0,
          totalReservas: (deudaData['total_reservas'] as int?) ?? 0,
        );
      } catch (e) {
        debugPrint('Error obteniendo deuda para agencia ${agencia.codigo}: $e');
        return agencia;
      }
    });

    return await Future.wait(futures);
  }

  Future<AgenciaSupabase?> obtenerAgenciaPorId(int agenciaId) async {
    try {
      final response = await _client
          .from('agencias')
          .select()
          .eq('agencia_codigo', agenciaId)
          .single();

      if (response.isEmpty) {
        debugPrint('Agencia no encontrada para el ID $agenciaId');
        return null;
      }

      return AgenciaSupabase.fromMap(response);
    } catch (e, s) {
      debugPrint('Error al obtener agencia por ID $agenciaId: $e\n$s');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerPreciosServiciosAgencia({
    required int operadorCodigo,
    required int agenciaCodigo,
  }) async {
    final response = await _client
        .from('servicio_precios_agencias')
        .select(
          'servicio_agencias_codigo, servicio_agencias_precio, tipos_servicios(tipo_servicio_descripcion)',
        )
        .eq('operador_codigo', operadorCodigo)
        .eq('agencia_codigo', agenciaCodigo)
        .eq('tipos_servicios.tipo_servicio_activo', true);

    return (response as List)
        .map(
          (item) => {
            'codigo': item['servicio_agencias_codigo'],
            'precio': item['servicio_agencias_precio'],
            'descripcion':
                item['tipos_servicios']?['tipo_servicio_descripcion'],
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> obtenerPreciosServiciosOperador({
    required int operadorCodigo,
  }) async {
    final response = await _client
        .from('servicios_precios')
        .select(
          'servicio_precio_codigo, precio, tipos_servicios(tipo_servicio_descripcion)',
        )
        .eq('tipos_servicios.operador_codigo', operadorCodigo);

    return (response as List)
        .map(
          (item) => {
            'codigo': item['servicio_precio_codigo'],
            'precio': item['precio'],
            'descripcion':
                item['tipos_servicios']?['tipo_servicio_descripcion'],
          },
        )
        .toList();
  }

  Future<({bool hasContact, String? telefono, String? link})>
  getContactoAgencia(int agenciaId) async {
    // Llama a la función SQL que hiciste en Supabase
    final res = await _client.rpc(
      'get_agencia_contacto',
      params: {'p_agencia': agenciaId},
    );

    // res suele venir como List con 1 fila
    final row = (res is List && res.isNotEmpty)
        ? (res.first as Map<String, dynamic>)
        : <String, dynamic>{};

    return (
      hasContact: row['has_contact'] == true,
      telefono: row['telefono'] as String?,
      link: row['link'] as String?,
    );
  }
}
