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
}
