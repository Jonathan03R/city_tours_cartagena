import 'package:citytourscartagena/core/models/agencia/contacto_agencia.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgenciasContactosService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los contactos de una agencia
  Future<List<ContactoAgencia>> obtenerPorAgencia(int agenciaCodigo) async {
    try {
      final response = await _client
          .from('contactos_agencias')
          .select('contacto_agencia_codigo, tipo_contacto_codigo, contacto_agencia_descripcion, agencia_codigo, tipos_contactos(tipo_contacto_codigo, tipo_contacto_descripcion, tipo_contacto_activo)')
          .eq('agencia_codigo', agenciaCodigo);
      return (response as List).map((map) => ContactoAgencia.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error obteniendo contactos: $e');
    }
  }

  /// Crea un nuevo contacto para una agencia
  Future<Map<String, dynamic>> crear(Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('contactos_agencias')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error creando contacto: $e');
    }
  }

  /// Actualiza un contacto existente
  Future<Map<String, dynamic>> actualizar(int codigo, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from('contactos_agencias')
          .update(data)
          .eq('contacto_agencia_codigo', codigo)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error actualizando contacto: $e');
    }
  }

  /// Elimina un contacto
  Future<void> eliminar(int codigo) async {
    try {
      await _client
          .from('contactos_agencias')
          .delete()
          .eq('contacto_agencia_codigo', codigo);
    } catch (e) {
      throw Exception('Error eliminando contacto: $e');
    }
  }
}