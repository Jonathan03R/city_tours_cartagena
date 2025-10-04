import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:citytourscartagena/core/services/reservas/reservas_service.supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservasSupabaseController {
  final SupabaseClient _client = Supabase.instance.client;
  late final ReservasSupabaseService _service = ReservasSupabaseService(_client);

  Future<List<ReservaResumen>> obtenerReservaAgencia({
    required int idAgencia,
    required int idOperador,
  }) async {
    return await _service.obtenerResumenReservas(
      agenciaId: idAgencia,
      operadorId: idOperador,
    );
  }
}