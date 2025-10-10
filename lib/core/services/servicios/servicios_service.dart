import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiciosService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TipoServicio>> obtenerTiposServicios({
    required int operadorCodigo,
  }) async {
    final response = await _client
        .from('tipos_servicios')
        .select('tipo_servicio_codigo, tipo_servicio_descripcion')
        .eq('operador_codigo', operadorCodigo)
        .eq('tipo_servicio_activo', true);

    return response.map((e) => TipoServicio.fromMap(e)).toList();
  }


  Future<Map<String, dynamic>> crearTipoServicio({
    required int operadorCodigo,
    required String descripcion,
    required int creadoPor,
    bool activo = true,
  }) async {
    final nuevo = await _client
        .from('tipos_servicios')
        .insert({
          'operador_codigo': operadorCodigo,
          'tipo_servicio_descripcion': descripcion,
          'tipo_servicio_activo': activo,
          'tipo_servicio_creado_por': creadoPor,
        })
        .select()
        .single();

    return nuevo;
  }

  Future<Map<String, dynamic>> actualizarTipoServicio({
    required int tipoServicioCodigo,
    required String descripcion,
    required bool activo,
    required int actualizadoPor,
  }) async {
    final actualizado = await _client
        .from('tipos_servicios')
        .update({
          'tipo_servicio_descripcion': descripcion,
          'tipo_servicio_activo': activo,
          'tipo_servicio_actualizado_por': actualizadoPor,
        })
        .eq('tipo_servicio_codigo', tipoServicioCodigo)
        .select()
        .single();

    return actualizado;
  }
}
