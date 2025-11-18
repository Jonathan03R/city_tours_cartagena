import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarioNoLaboralesService {
  final SupabaseClient _client = Supabase.instance.client;
  /// Listar por un día específico [fecha] usando comparación exacta de fecha (sin horas)
  Future<List<Map<String, dynamic>>> listarDia({
    required DateTime fecha,
    required int operadorCodigo,
    required int tipoServicioId,  
    bool? activo,
  }) async {
    final fechaString = fecha.toIso8601String().split('T')[0]; 
    //debug para saber que datos estoy dandole
    debugPrint('Fecha enviada: $fechaString, OperadorCodigo: $operadorCodigo, TipoServicioId: $tipoServicioId');

    // Usar función RPC para filtrar correctamente por fecha
    final Map<String, dynamic> params = {
      'p_fecha': fechaString,
      'p_operador_codigo': operadorCodigo,
      'p_tipo_servicio_id': tipoServicioId,
      // solo enviar p_activo si viene especificado; si es null, el RPC devolverá todos
    };
    if (activo != null) {
      params['p_activo'] = activo;
    }

    final res = await _client.rpc('obtener_no_laborables_por_fecha', params: params);
    final rows = (res as List).cast<Map<String, dynamic>>();

    debugPrint('Filas retornadas: ${rows.length}');
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      debugPrint('Fila#$i -> fechaDB=${r['calendario_no_laborable_fecha']} tipo_servicio_id=${r['tipo_servicio_id']} activo=${r['calendario_no_laborable_activo']}');
    }

    return rows;
  }

  /// Crear un día no laborable.
  /// Nota: No enviamos `calendario_no_laborable_activo` para respetar el default=true del schema.
  Future<Map<String, dynamic>> crear({
    required DateTime fecha,
    required int operadorCodigo,
    required int creadoPor,
    required int tipoServicioId,
    String? descripcion,
    bool? activo, // si viene null, no se envía
  }) async {
    final payload = <String, dynamic>{
      'calendario_no_laborable_fecha': fecha.toIso8601String(),
      'operador_codigo': operadorCodigo,
      'calendario_no_laborable_creado_por': creadoPor,
      'tipo_servicio_id': tipoServicioId,
    };

    // Solo enviar activo si el caller lo especifica explícitamente
    if (activo != null) {
      payload['calendario_no_laborable_activo'] = activo;
    }
    if (descripcion != null && descripcion.trim().isNotEmpty) {
      payload['calendarios_descripcion'] = descripcion.trim();
    }

  final res = await _client
        .from('calendarios_no_laborables')
        .insert(payload)
        .select()
        .single();
  return res;
  }

  /// Actualizar un registro por su código.
  /// Envía sólo los campos que quieras modificar.
  Future<Map<String, dynamic>> actualizar({
    required int codigo,
    DateTime? fecha,
    bool? activo,
    int? tipoServicioId,
    String? descripcion,
    required int actualizadoPor,
  }) async {
    if (fecha == null && activo == null) {
      debugPrint(
          '[CalendarioNoLaboralesService.actualizar] Nada que actualizar para codigo=$codigo');
    }

    final payload = <String, dynamic>{
      'calendario_no_laborable_actualizado_por': actualizadoPor,
    };
    if (fecha != null) {
      payload['calendario_no_laborable_fecha'] = fecha.toIso8601String();
    }
    if (activo != null) {
      payload['calendario_no_laborable_activo'] = activo;
    }
    if (tipoServicioId != null) {
      payload['tipo_servicio_id'] = tipoServicioId;
    }
    if (descripcion != null && descripcion.trim().isNotEmpty) {
      payload['calendarios_descripcion'] = descripcion.trim();
    }

  final res = await _client
        .from('calendarios_no_laborables')
        .update(payload)
        .eq('calendario_no_laborable_codigo', codigo)
        .select()
        .single();
  return res;
  }

  /// Acceso rápido: upsert por (operador_codigo, fecha) si tuvieras una restricción única en esos campos.
  /// Útil si quieres idempotencia.
  Future<Map<String, dynamic>> upsertPorFecha({
    required DateTime fecha,
    required int operadorCodigo,
    required int usuarioId,
    required int tipoServicioId,
    bool? activo,
    String? descripcion,
  }) async {
    final payload = <String, dynamic>{
      'calendario_no_laborable_fecha': fecha.toIso8601String(),
      'operador_codigo': operadorCodigo,
      'tipo_servicio_id': tipoServicioId,
      // si existe, actualiza; si no, crea usando `creado_por`
      'calendario_no_laborable_creado_por': usuarioId,
      'calendario_no_laborable_actualizado_por': usuarioId,
    };
    if (activo != null) {
      payload['calendario_no_laborable_activo'] = activo;
    }
    if (descripcion != null && descripcion.trim().isNotEmpty) {
      payload['calendarios_descripcion'] = descripcion.trim();
    }

  final res = await _client
        .from('calendarios_no_laborables')
        .upsert(payload, onConflict: 'operador_codigo,calendario_no_laborable_fecha,tipo_servicio_id')
        .select()
        .single();
  return res;
  }

  /// Verifica directamente en la tabla si existe un cierre ACTIVO
  /// para el día (rango [00:00, 24:00)) del operador y tipo de servicio dados.
  Future<bool> existeCierreActivoDia({
    required DateTime fecha,
    required int operadorCodigo,
    required int tipoServicioId,
  }) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day);
    final fin = inicio.add(const Duration(days: 1));

    final res = await _client
        .from('calendarios_no_laborables')
        .select('calendario_no_laborable_codigo')
        .eq('operador_codigo', operadorCodigo)
        .eq('tipo_servicio_id', tipoServicioId)
        .eq('calendario_no_laborable_activo', true)
        .gte('calendario_no_laborable_fecha', inicio.toIso8601String())
        .lt('calendario_no_laborable_fecha', fin.toIso8601String());

    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.isNotEmpty;
  }
}

