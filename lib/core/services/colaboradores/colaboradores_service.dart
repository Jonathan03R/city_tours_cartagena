import 'package:citytourscartagena/core/models/operadores/operdadores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OperadoresService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Operadores?> obtener({required int id}) async {
    try {
      final response = await _client
          .from('operadores')
          .select()
          .eq('operador_codigo', id)
          .eq('operador_activo', true)
          .maybeSingle();

      if (response != null) {
        return Operadores.fromMap(response);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<int> obtenerIdOperador({required int idUsuario}) async {
    final res = await _client
        .from('usuarios_operadores')
        .select()
        .eq('usuario_codigo', idUsuario)
        .maybeSingle();
    final operadorId = (res as Map)['operador_codigo'] as int;
    return operadorId;
  }
}
