import 'dart:io';

import 'package:flutter/foundation.dart'; // para debugPrint
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class ServicioAlmacenamientoSupabase {
  final _cliente = Supabase.instance.client;
  final String bucket;

  // El bucket raíz es "logos"
  ServicioAlmacenamientoSupabase({this.bucket = 'logos'});

  /// Sube un archivo al bucket en la carpeta indicada (por ejemplo: 'agencias')
  Future<String?> subirArchivo({
    required File archivo,
    required String carpeta,
    required String nombre,
  }) async {
    try {
      // Crear nombre único para evitar conflictos
      final nombreArchivo =
          '$carpeta/${nombre}_${DateTime.now().millisecondsSinceEpoch}${p.extension(archivo.path)}';

      final bytes = await archivo.readAsBytes();

      // uploadBinary devuelve la ruta del archivo subido (String)
      final rutaSubida = await _cliente.storage
          .from(bucket)
          .uploadBinary(nombreArchivo, bytes, fileOptions: const FileOptions(upsert: false));

      // Si falla, lanza una excepción automáticamente
      debugPrint('Archivo subido correctamente: $rutaSubida');

      // Obtener URL pública
      final urlPublica = _cliente.storage.from(bucket).getPublicUrl(nombreArchivo);
      debugPrint('URL pública: $urlPublica');

      return urlPublica;
    } catch (e) {
      debugPrint('Error subiendo archivo: $e');
      return null;
    }
  }

  /// Elimina un archivo del bucket
  Future<bool> eliminarArchivo(String rutaArchivo) async {
    try {
      await _cliente.storage.from(bucket).remove([rutaArchivo]);
      debugPrint('Archivo eliminado correctamente.');
      return true;
    } catch (e) {
      debugPrint('Error eliminando archivo: $e');
      return false;
    }
  }
}
