import 'package:citytourscartagena/core/models/operadores/operdadores.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OperadoresService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene un operador por su ID
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
      throw Exception('Error al obtener operador: $e');
    }
  }

  /// Obtiene todos los operadores activos
  Future<List<Operadores>> obtenerTodos() async {
    try {
      final response = await _client
          .from('operadores')
          .select()
          .eq('operador_activo', true)
          .order('operador_nombre', ascending: true);

      return response.map((map) => Operadores.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener operadores: $e');
    }
  }

  /// Obtiene el ID del operador de un usuario
  Future<int> obtenerIdOperador({required int idUsuario}) async {
    try {
      final res = await _client
          .from('usuarios_operadores')
          .select()
          .eq('usuario_codigo', idUsuario)
          .maybeSingle();

      if (res == null) {
        throw Exception('Usuario no tiene operador asignado');
      }

      return (res as Map)['operador_codigo'] as int;
    } catch (e) {
      throw Exception('Error al obtener ID del operador: $e');
    }
  }

  /// Crea un nuevo operador
  Future<Operadores> crear({
    required String nombre,
    required String beneficiario,
    required int tipoEmpresa,
    required int tipoDocumento,
    String? documento,
    String? logoUrl,
    required int usuarioId,
  }) async {
    try {
      final response = await _client
          .from('operadores')
          .insert({
            'operador_nombre': nombre,
            'operador_beneficiario': beneficiario,
            'tipo_empresa_codigo': tipoEmpresa,
            'tipo_documento_codigo': tipoDocumento,
            'operador_documento': documento,
            'operador_logo_url': logoUrl,
            'operador_activo': true,
            'operador_creado_por': usuarioId,
            'operador_fecha_creacion': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return Operadores.fromMap(response);
    } catch (e) {
      throw Exception('Error al crear operador: $e');
    }
  }

  /// Actualiza un operador existente
  Future<Operadores> actualizar({
    required int operadorId,
    String? nombre,
    String? beneficiario,
    int? tipoEmpresa,
    int? tipoDocumento,
    String? documento,
    String? logoUrl,
    String? direccion,
    required int usuarioId,
  }) async {
    try {
      final updateData = {
        'operador_actualizado_por': usuarioId,
        'operador_fecha_actualizacion': DateTime.now().toIso8601String(),
      };

      if (nombre != null) updateData['operador_nombre'] = nombre;
      if (beneficiario != null) updateData['operador_beneficiario'] = beneficiario;
      if (tipoEmpresa != null) updateData['tipo_empresa_codigo'] = tipoEmpresa;
      if (tipoDocumento != null) updateData['tipo_documento_codigo'] = tipoDocumento;
      if (documento != null) updateData['operador_documento'] = documento;
      if (logoUrl != null) updateData['operador_logo_url'] = logoUrl;
      if (direccion != null) updateData['operador_direccion'] = direccion;

      final response = await _client
          .from('operadores')
          .update(updateData)
          .eq('operador_codigo', operadorId)
          .select()
          .single();

      return Operadores.fromMap(response);
    } catch (e) {
      throw Exception('Error al actualizar operador: $e');
    }
  }

  /// Activa/Desactiva un operador
  Future<Operadores> cambiarEstado({
    required int operadorId,
    required bool activo,
    required int usuarioId,
  }) async {
    try {
      final response = await _client
          .from('operadores')
          .update({
            'operador_activo': activo,
            'operador_actualizado_por': usuarioId,
            'operador_fecha_actualizacion': DateTime.now().toIso8601String(),
          })
          .eq('operador_codigo', operadorId)
          .select()
          .single();

      return Operadores.fromMap(response);
    } catch (e) {
      throw Exception('Error al cambiar estado del operador: $e');
    }
  }
}
