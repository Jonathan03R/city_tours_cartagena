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

  Future<List<TipoServicio>> obtenerTiposServiciosDisponiblesParaAgencia({
    required int operadorCodigo,
    required int agenciaCodigo,
  }) async {
    // Obtener todos los tipos de servicios activos del operador
    final todosServicios = await _client
        .from('tipos_servicios')
        .select('tipo_servicio_codigo, tipo_servicio_descripcion')
        .eq('operador_codigo', operadorCodigo)
        .eq('tipo_servicio_activo', true);

    print('Todos los servicios activos del operador $operadorCodigo: ${todosServicios.length}');
    todosServicios.forEach((s) => print('Servicio: ${s['tipo_servicio_codigo']} - ${s['tipo_servicio_descripcion']}'));

    // Obtener los tipos de servicios que TIENEN precio base en servicios_precios
    final serviciosConPrecioBase = await _client
        .from('servicios_precios')
        .select('tipo_servicio_codigo');

    print('Servicios con precio base: ${serviciosConPrecioBase.length}');
    serviciosConPrecioBase.forEach((s) => print('Servicio con precio base: ${s['tipo_servicio_codigo']}'));

    // Extraer códigos de servicios con precio base
    final codigosConPrecioBase = serviciosConPrecioBase
        .map((servicio) => servicio['tipo_servicio_codigo'] as int)
        .toSet();

    // Obtener los tipos de servicios que ya tienen precio personalizado para esta agencia
    final serviciosConPrecio = await _client
        .from('servicio_precios_agencias')
        .select('tipo_servicio_codigo')
        .eq('operador_codigo', operadorCodigo)
        .eq('agencia_codigo', agenciaCodigo);

    print('Servicios con precio personalizado para agencia $agenciaCodigo: ${serviciosConPrecio.length}');
    serviciosConPrecio.forEach((s) => print('Servicio con precio personalizado: ${s['tipo_servicio_codigo']}'));

    // Extraer los códigos de servicios que ya tienen precio personalizado
    final codigosConPrecioPersonalizado = serviciosConPrecio
        .map((servicio) => servicio['tipo_servicio_codigo'] as int)
        .toSet();

    print('Códigos con precio personalizado: $codigosConPrecioPersonalizado');

    // Filtrar servicios que tienen precio base PERO NO tienen precio personalizado
    final serviciosDisponibles = todosServicios
        .where((servicio) => 
          codigosConPrecioBase.contains(servicio['tipo_servicio_codigo']) &&
          !codigosConPrecioPersonalizado.contains(servicio['tipo_servicio_codigo'])
        )
        .map((e) => TipoServicio.fromMap(e))
        .toList();

    print('Servicios disponibles: ${serviciosDisponibles.length}');
    serviciosDisponibles.forEach((s) => print('Disponible: ${s.codigo} - ${s.descripcion}'));

    return serviciosDisponibles;
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
