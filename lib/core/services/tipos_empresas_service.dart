import 'package:supabase_flutter/supabase_flutter.dart';

class TiposEmpresasService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Obtiene todos los tipos de empresa activos
  Future<List<Map<String, dynamic>>> obtenerTiposEmpresasActivos() async {
    try {
      final response = await _client
          .from('tipos_empresas')
          .select('tipo_empresa_codigo, tipo_empresa_nombre')
          .eq('tipo_empresa_activo', true)
          .order('tipo_empresa_nombre', ascending: true);

      return response;
    } catch (e) {
      throw Exception('Error al obtener tipos de empresa: $e');
    }
  }
}