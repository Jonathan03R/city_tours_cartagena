import 'package:supabase_flutter/supabase_flutter.dart';

class AgenciasPreciosService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Crear un precio personalizado para una agencia
  Future<Map<String, dynamic>> crearPrecioAgencia({
    required int operadorCodigo,
    required int agenciaCodigo,
    required int tipoServicioCodigo,
    required double precio,
  }) async {
    final response = await _client
        .from('servicio_precios_agencias')
        .insert({
          'operador_codigo': operadorCodigo,
          'agencia_codigo': agenciaCodigo,
          'tipo_servicio_codigo': tipoServicioCodigo,
          'servicio_agencias_precio': precio,
        })
        .select()
        .single();

    return response;
  }

  /// Actualizar un precio personalizado de agencia
  Future<Map<String, dynamic>> actualizarPrecioAgencia({
    required int precioCodigo,
    required double precio,
  }) async {
    final response = await _client
        .from('servicio_precios_agencias')
        .update({
          'servicio_agencias_precio': precio,
        })
        .eq('servicio_agencias_codigo', precioCodigo)
        .select()
        .single();

    return response;
  }

  /// Eliminar un precio personalizado de agencia
  Future<void> eliminarPrecioAgencia({
    required int precioCodigo,
  }) async {
    await _client
        .from('servicio_precios_agencias')
        .delete()
        .eq('servicio_agencias_codigo', precioCodigo);
  }

  /// Obtener un precio específico por código
  Future<Map<String, dynamic>?> obtenerPrecioPorCodigo({
    required int precioCodigo,
  }) async {
    final response = await _client
        .from('servicio_precios_agencias')
        .select(
          'servicio_agencias_codigo, servicio_agencias_precio, tipos_servicios(tipo_servicio_descripcion)',
        )
        .eq('servicio_agencias_codigo', precioCodigo)
        .maybeSingle();

    return response;
  }
}