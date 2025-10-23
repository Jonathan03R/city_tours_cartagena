import 'package:supabase_flutter/supabase_flutter.dart';

class TiposDocumentosService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los tipos de documento activos
  Future<List<Map<String, dynamic>>> obtenerTiposDocumentosActivos() async {
    try {
      final response = await _client
          .from('tipos_documentos')
          .select('tipo_documento_codigo, tipo_documento_nombre, tipo_documento_prefijo')
          .eq('tipo_documento_activo', true)
          .order('tipo_documento_nombre', ascending: true);

      return response;
    } catch (e) {
      throw Exception('Error al obtener tipos de documento: $e');
    }
  }
}