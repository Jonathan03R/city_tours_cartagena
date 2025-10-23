import 'dart:io';

import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/tipos/tipo_documento.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:citytourscartagena/core/services/bucket/bucket_agencia_service.dart';
import 'package:citytourscartagena/core/services/tipo_documentos/tipo_documento.dart';
import 'package:flutter/foundation.dart';

class AgenciasControllerSupabase extends ChangeNotifier {
  final AgenciasService _agenciasService = AgenciasService();
  final ServicioAlmacenamientoSupabase _almacenamiento = ServicioAlmacenamientoSupabase();
  final TiposDocumentosService _tiposDocumentosService = TiposDocumentosService();

  bool _cargando = false;
  bool get cargando => _cargando;

  void _setCargando(bool valor) {
    _cargando = valor;
    notifyListeners();
  }

  Future<List<TipoDocumento>> obtenerTiposDocumentosActivos() async {
    try {
      return await _tiposDocumentosService.obtener();
    } catch (e) {
      debugPrint('Error obteniendo tipos de documento: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> crearAgencia({
    required CrearAgenciaDTO datos,
    required File logoArchivo,
  }) async {
    try {
      _setCargando(true);
      final urlLogo = await _almacenamiento.subirArchivo(
        archivo: logoArchivo,
        carpeta: 'agencias',
        nombre: datos.nombre,
      );

      if (urlLogo == null) {
        throw Exception('No se pudo subir la imagen del logo');
      }
      datos = datos.copyWith(logoUrl: urlLogo); 
      final resultado = await _agenciasService.crearAgenciaCompleta(datos);

      return resultado;
    } catch (e) {
      debugPrint('Error en crearAgencia: $e');
      rethrow;
    } finally {
      _setCargando(false);
    }
  }
}
