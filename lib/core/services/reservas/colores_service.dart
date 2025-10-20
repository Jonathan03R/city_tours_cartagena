import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/colores/color_model.dart';

class ColoresService {
  final SupabaseClient _client;

  ColoresService(this._client);

  Future<List<ColorModel>> obtenerColores() async {
    final response = await _client.from('colores').select('*');
    return response.map((e) => ColorModel.fromJson(e)).toList();
  }
}
