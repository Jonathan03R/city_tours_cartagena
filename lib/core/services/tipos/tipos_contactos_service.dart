import 'package:citytourscartagena/core/models/tipos/tipo_contacto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TiposContactosService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los tipos de contacto activos
  Future<List<TipoContacto>> obtenerTiposContactosActivos() async {
    try {
      final response = await _client
          .from('tipos_contactos')
          .select()
          .eq('tipo_contacto_activo', true)
          .order('tipo_contacto_descripcion', ascending: true);

      return response.map((map) => TipoContacto.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de contacto: $e');
    }
  }

  /// Obtiene todos los tipos de contacto (activos e inactivos)
  Future<List<TipoContacto>> obtenerTodosTiposContactos() async {
    try {
      final response = await _client
          .from('tipos_contactos')
          .select()
          .order('tipo_contacto_descripcion', ascending: true);

      return response.map((map) => TipoContacto.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de contacto: $e');
    }
  }

  /// Obtiene un tipo de contacto específico por su ID
  Future<TipoContacto?> obtenerTipoContactoPorId({
    required int tipoContactoId,
  }) async {
    try {
      final response = await _client
          .from('tipos_contactos')
          .select()
          .eq('tipo_contacto_codigo', tipoContactoId)
          .maybeSingle();

      if (response != null) {
        return TipoContacto.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener tipo de contacto: $e');
    }
  }

  /// Crea un nuevo tipo de contacto
  Future<TipoContacto> crearTipoContacto({
    required String descripcion,
    required int usuarioId,
  }) async {
    try {
      final response = await _client
          .from('tipos_contactos')
          .insert({
            'tipo_contacto_descripcion': descripcion,
            'tipo_contacto_activo': true,
            'tipo_contacto_creado_por': usuarioId,
            'tipo_contacto_fecha_creacion': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return TipoContacto.fromMap(response);
    } catch (e) {
      throw Exception('Error al crear tipo de contacto: $e');
    }
  }

  /// Actualiza un tipo de contacto existente
  Future<TipoContacto> actualizarTipoContacto({
    required int tipoContactoId,
    String? descripcion,
    bool? activo,
    required int usuarioId,
  }) async {
    try {
      final updateData = {
        'tipo_contacto_actualizado_por': usuarioId,
        'tipo_contacto_fecha_actualizacion': DateTime.now().toIso8601String(),
      };

      if (descripcion != null) {
        updateData['tipo_contacto_descripcion'] = descripcion;
      }

      if (activo != null) {
        updateData['tipo_contacto_activo'] = activo;
      }

      final response = await _client
          .from('tipos_contactos')
          .update(updateData)
          .eq('tipo_contacto_codigo', tipoContactoId)
          .select()
          .single();

      return TipoContacto.fromMap(response);
    } catch (e) {
      throw Exception('Error al actualizar tipo de contacto: $e');
    }
  }

  /// Activa/Desactiva un tipo de contacto
  Future<TipoContacto> cambiarEstadoTipoContacto({
    required int tipoContactoId,
    required bool activo,
    required int usuarioId,
  }) async {
    try {
      final response = await _client
          .from('tipos_contactos')
          .update({
            'tipo_contacto_activo': activo,
            'tipo_contacto_actualizado_por': usuarioId,
            'tipo_contacto_fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('tipo_contacto_codigo', tipoContactoId)
          .select()
          .single();

      return TipoContacto.fromMap(response);
    } catch (e) {
      throw Exception('Error al cambiar estado del tipo de contacto: $e');
    }
  }
}