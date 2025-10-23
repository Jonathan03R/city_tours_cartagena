import 'package:citytourscartagena/core/models/tipos/tipo_documento.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class TiposDocumentosService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TipoDocumento>> obtener() async {
    try {
      final response = await _client
          .from('tipos_documentos')
          .select('tipo_documento_codigo, tipo_documento_nombre, tipo_documento_prefijo, tipo_documento_activo')
          .eq('tipo_documento_activo', true);
      return (response as List).map((map) => TipoDocumento.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error obteniendo tipos de documento: $e');
    }
  }
}