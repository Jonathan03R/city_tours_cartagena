import 'dart:io';

import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/agencia/contacto_agencia.dart';
import 'package:citytourscartagena/core/models/agencia/perfil_agencia.dart';
import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:citytourscartagena/core/models/tipos/tipo_contacto.dart';
import 'package:citytourscartagena/core/models/tipos/tipo_documento.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_contactos.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_precios.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:citytourscartagena/core/services/bucket/bucket_agencia_service.dart';
import 'package:citytourscartagena/core/services/filtros/servicios/servicios_service.dart';
import 'package:citytourscartagena/core/services/tipos/tipo_documento.dart';
import 'package:citytourscartagena/core/services/tipos/tipos_contactos_service.dart';
import 'package:flutter/foundation.dart';

class AgenciasControllerSupabase extends ChangeNotifier {
  Future<Map<String, dynamic>> actualizarDatosAgencia({
    required int agenciaId,
    required String nombre,
    required String? direccion,
    required int? tipoDocumentoCodigo,
    required String? representante,
    required String? documento,
  }) async {
    try {
      return await _agenciasService.actualizarDatosAgencia(
        agenciaId: agenciaId,
        nombre: nombre,
        direccion: direccion,
        tipoDocumentoCodigo: tipoDocumentoCodigo,
        representante: representante,
        documento: documento,
      );
    } catch (e) {
      debugPrint('Error actualizando datos de agencia: $e');
      rethrow;
    }
  }
  final AgenciasService _agenciasService = AgenciasService();
  final ServicioAlmacenamientoSupabase _almacenamiento = ServicioAlmacenamientoSupabase();
  final TiposDocumentosService _tiposDocumentosService = TiposDocumentosService();
  final AgenciasContactosService _contactosService = AgenciasContactosService();
  final TiposContactosService _tiposContactosService = TiposContactosService();
  final AgenciasPreciosService _preciosService = AgenciasPreciosService();
  final ServiciosService _serviciosService = ServiciosService();

  bool _cargando = false;
  bool get cargando => _cargando;

  void _setCargando(bool valor) {
    _cargando = valor;
    notifyListeners();
  }

  Future<Agenciaperfil?> obtenerAgenciaPorId(int agenciaId) async {
    try {
      return await _agenciasService.obtenerAgenciaPorId(agenciaId);
    } catch (e) {
      debugPrint('Error obteniendo agencia por ID: $e');
      return null;
    }
  }

  Future<List<ContactoAgencia>> obtenerContactosAgencia(int agenciaCodigo) async {
    try {
      return await _contactosService.obtenerPorAgencia(agenciaCodigo);
    } catch (e) {
      debugPrint('Error obteniendo contactos: $e');
      return [];
    }
  }

  Future<List<TipoDocumento>> obtenerTiposDocumentosActivos() async {
    try {
      return await _tiposDocumentosService.obtener();
    } catch (e) {
      debugPrint('Error obteniendo tipos de documento: $e');
      return [];
    }
  }

  Future<List<TipoContacto>> obtenerTiposContactosActivos() async {
    try {
      return await _tiposContactosService.obtenerTiposContactosActivos();
    } catch (e) {
      debugPrint('Error obteniendo tipos de contacto: $e');
      return [];
    }
  }

  Future<ContactoAgencia> crearContacto({
    required int agenciaCodigo,
    required int tipoContactoCodigo,
    required String descripcion,
  }) async {
    try {
      final data = {
        'agencia_codigo': agenciaCodigo,
        'tipo_contacto_codigo': tipoContactoCodigo,
        'contacto_agencia_descripcion': descripcion,
      };

      await _contactosService.crear(data);

      // Recargar contactos para obtener el objeto completo con el tipo de contacto
      final contactos = await obtenerContactosAgencia(agenciaCodigo);
      return contactos.firstWhere((c) => c.descripcion == descripcion && c.tipoContactoCodigo == tipoContactoCodigo);
    } catch (e) {
      debugPrint('Error creando contacto: $e');
      rethrow;
    }
  }

  Future<ContactoAgencia> actualizarContacto({
    required int agenciaId,
    required int contactoCodigo,
    required int tipoContactoCodigo,
    required String descripcion,
  }) async {
    try {
      final data = {
        'tipo_contacto_codigo': tipoContactoCodigo,
        'contacto_agencia_descripcion': descripcion,
      };

      await _contactosService.actualizar(contactoCodigo, data);

      // Recargar contactos para obtener el objeto actualizado
      final contactos = await obtenerContactosAgencia(agenciaId);
      return contactos.firstWhere((c) => c.codigo == contactoCodigo);
    } catch (e) {
      debugPrint('Error actualizando contacto: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerPreciosServiciosAgencia({
    required int operadorCodigo,
    required int agenciaCodigo,
  }) async {
    try {
      return await _agenciasService.obtenerPreciosServiciosAgencia(
        operadorCodigo: operadorCodigo,
        agenciaCodigo: agenciaCodigo,
      );
    } catch (e) {
      debugPrint('Error obteniendo precios de servicios de agencia: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> crearPrecioAgencia({
    required int operadorCodigo,
    required int agenciaCodigo,
    required int tipoServicioCodigo,
    required double precio,
  }) async {
    try {
      // Validar que no exista ya un precio para este servicio en esta agencia
      final preciosExistentes = await obtenerPreciosServiciosAgencia(
        operadorCodigo: operadorCodigo,
        agenciaCodigo: agenciaCodigo,
      );

      final existePrecio = preciosExistentes.any(
        (precioExistente) => precioExistente['tipo_servicio_codigo'] == tipoServicioCodigo
      );

      if (existePrecio) {
        throw Exception('Ya existe un precio personalizado para este tipo de servicio en esta agencia');
      }

      return await _preciosService.crearPrecioAgencia(
        operadorCodigo: operadorCodigo,
        agenciaCodigo: agenciaCodigo,
        tipoServicioCodigo: tipoServicioCodigo,
        precio: precio,
      );
    } catch (e) {
      debugPrint('Error creando precio de agencia: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarPrecioAgencia({
    required int precioCodigo,
    required double precio,
  }) async {
    try {
      return await _preciosService.actualizarPrecioAgencia(
        precioCodigo: precioCodigo,
        precio: precio,
      );
    } catch (e) {
      debugPrint('Error actualizando precio de agencia: $e');
      rethrow;
    }
  }

  Future<void> eliminarPrecioAgencia({
    required int precioCodigo,
  }) async {
    try {
      await _preciosService.eliminarPrecioAgencia(
        precioCodigo: precioCodigo,
      );
    } catch (e) {
      debugPrint('Error eliminando precio de agencia: $e');
      rethrow;
    }
  }

  Future<List<TipoServicio>> obtenerTiposServiciosDisponiblesParaAgencia({
    required int operadorCodigo,
    required int agenciaCodigo,
  }) async {
    try {
      return await _serviciosService.obtenerTiposServiciosDisponiblesParaAgencia(
        operadorCodigo: operadorCodigo,
        agenciaCodigo: agenciaCodigo,
      );
    } catch (e) {
      debugPrint('Error obteniendo tipos de servicios disponibles para agencia: $e');
      return [];
    }
  }

  Future<void> eliminarContacto(int contactoCodigo) async {
    try {
      await _contactosService.eliminar(contactoCodigo);
    } catch (e) {
      debugPrint('Error eliminando contacto: $e');
      rethrow;
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
