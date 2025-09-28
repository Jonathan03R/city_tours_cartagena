import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservasSupabaseService {
  final SupabaseClient _client;

  ReservasSupabaseService(this._client);

  Future<List<ReservaResumen>> obtenerResumenReservas({
    required int agenciaId,
    required int operadorId,
  }) async {
    try {
      final response = await _client.rpc(
        'obtener_resumen_reservas',
        params: {
          'p_agencia_codigo': agenciaId,
          'p_operador_codigo': operadorId,
        },
      );

      final data = response as List;
      return data.map((e) => ReservaResumen.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e, s) {
      debugPrint('Error en obtenerResumenReservas: $e\nStack: $s');
      rethrow;
    }
  }
}
