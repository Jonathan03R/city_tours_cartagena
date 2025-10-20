import 'package:citytourscartagena/core/models/operadores/contacto_operador.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactosOperadoresService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los contactos de un operador específico
  Future<List<ContactoOperador>> obtenerContactosPorOperador({
    required int operadorId,
  }) async {
    try {
      final response = await _client
          .from('contactos_operadores')
          .select()
          .eq('operador_codigo', operadorId)
          .order('contacto_operador_fecha_creacion', ascending: false);

      return response.map((map) => ContactoOperador.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error al obtener contactos del operador: $e');
    }
  }

  /// Obtiene un contacto específico por su ID
  Future<ContactoOperador?> obtenerContactoPorId({
    required int contactoId,
  }) async {
    try {
      final response = await _client
          .from('contactos_operadores')
          .select()
          .eq('contacto_operador_codigo', contactoId)
          .maybeSingle();

      if (response != null) {
        return ContactoOperador.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener contacto: $e');
    }
  }

  /// Crea un nuevo contacto para un operador
  Future<ContactoOperador> crearContacto({
    required int tipoContactoCodigo,
    required String descripcion,
    required int operadorCodigo,
    required int usuarioId,
  }) async {
    try {
      final response = await _client
          .from('contactos_operadores')
          .insert({
            'tipo_contacto_codigo': tipoContactoCodigo,
            'contacto_operador_descripcion': descripcion,
            'operador_codigo': operadorCodigo,
            'contacto_operador_creado_por': usuarioId,
            'contacto_operador_fecha_creacion': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ContactoOperador.fromMap(response);
    } catch (e) {
      throw Exception('Error al crear contacto: $e');
    }
  }

  /// Actualiza un contacto existente
  Future<ContactoOperador> actualizarContacto({
    required int contactoId,
    int? tipoContactoCodigo,
    String? descripcion,
    required int usuarioId,
  }) async {
    try {
      final updateData = {
        'contacto_operador_actualizado_por': usuarioId,
        'contacto_operador_fecha_actualizacion': DateTime.now().toIso8601String(),
      };

      if (tipoContactoCodigo != null) {
        updateData['tipo_contacto_codigo'] = tipoContactoCodigo;
      }

      if (descripcion != null) {
        updateData['contacto_operador_descripcion'] = descripcion;
      }

      final response = await _client
          .from('contactos_operadores')
          .update(updateData)
          .eq('contacto_operador_codigo', contactoId)
          .select()
          .single();

      return ContactoOperador.fromMap(response);
    } catch (e) {
      throw Exception('Error al actualizar contacto: $e');
    }
  }

  /// Elimina un contacto
  Future<void> eliminarContacto({
    required int contactoId,
  }) async {
    try {
      await _client
          .from('contactos_operadores')
          .delete()
          .eq('contacto_operador_codigo', contactoId);
    } catch (e) {
      throw Exception('Error al eliminar contacto: $e');
    }
  }
}