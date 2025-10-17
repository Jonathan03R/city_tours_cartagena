import 'package:supabase_flutter/supabase_flutter.dart';

class EstadosReservaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> obtenerEstadosReservas() async {
    final response = await _client
        .from('estados_reservas')
        .select('estado_codigo, estado_nombre');

    return response;
  }
}
