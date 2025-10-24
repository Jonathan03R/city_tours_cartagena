import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/operadores/contacto_operador.dart';
import 'package:citytourscartagena/core/models/operadores/operdadores.dart';
import 'package:citytourscartagena/core/models/tipos/tipo_contacto.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:citytourscartagena/core/services/colaboradores/colaboradores_service.dart';
import 'package:citytourscartagena/core/services/operadores/contactos_operadores_service.dart';
import 'package:citytourscartagena/core/services/tipos/tipos_contactos_service.dart';
import 'package:citytourscartagena/core/services/tipos_documentos_service.dart';
import 'package:citytourscartagena/core/services/tipos_empresas_service.dart';
import 'package:flutter/foundation.dart';

class OperadoresController extends ChangeNotifier {
  final OperadoresService _operadoresService = OperadoresService();
  final AgenciasService _agenciasService = AgenciasService();
  final ContactosOperadoresService _contactosService = ContactosOperadoresService();
  final TiposContactosService _tiposContactosService = TiposContactosService();
  final TiposDocumentosService _tiposDocumentosService = TiposDocumentosService();
  final TiposEmpresasService _tiposEmpresasService = TiposEmpresasService();
  final AuthSupabaseController auth;

  Future<Operadores?>? _operadorFuture;
  Future<List<ContactoOperador>>? _contactosFuture;
  Future<List<TipoContacto>>? _tiposContactosFuture;
  List<AgenciaSupabase>? _agenciasCache;

  OperadoresController(this.auth);

  int get codigoUsuario => auth.perfilUsuario!.usuario.codigo;

  List<AgenciaSupabase> get agencias => _agenciasCache ?? [];

  // ===== MÉTODOS PARA OPERADORES =====

  /// Obtiene el operador del usuario actual
  Future<Operadores?> obtenerOperador() {
    _operadorFuture ??= _obtenerOperadorInterno();
    return _operadorFuture!;
  }

  Future<Operadores?> _obtenerOperadorInterno() async {
    try {
      final operadorId = await _operadoresService.obtenerIdOperador(
        idUsuario: codigoUsuario,
      );
      final operador = await _operadoresService.obtener(id: operadorId);
      return operador;
    } catch (e) {
      debugPrint('Error obteniendo operador: $e');
      return null;
    }
  }

  /// Obtiene todos los operadores activos
  Future<List<Operadores>> obtenerTodosOperadores() async {
    try {
      return await _operadoresService.obtenerTodos();
    } catch (e) {
      debugPrint('Error obteniendo todos los operadores: $e');
      rethrow;
    }
  }

  /// Actualiza el operador del usuario actual
  Future<Operadores> actualizarOperador({
    String? nombre,
    String? beneficiario,
    int? tipoEmpresa,
    int? tipoDocumento,
    String? documento,
    String? logoUrl,
    String? direccion,
  }) async {
    try {
      final operador = await obtenerOperador();
      if (operador == null) {
        throw Exception('Operador no encontrado');
      }

      final operadorActualizado = await _operadoresService.actualizar(
        operadorId: operador.id,
        nombre: nombre,
        beneficiario: beneficiario,
        tipoEmpresa: tipoEmpresa,
        tipoDocumento: tipoDocumento,
        documento: documento,
        logoUrl: logoUrl,
        direccion: direccion,
        usuarioId: codigoUsuario,
      );

      // Limpiar cache para forzar recarga
      _operadorFuture = null;
      notifyListeners();

      return operadorActualizado;
    } catch (e) {
      debugPrint('Error actualizando operador: $e');
      rethrow;
    }
  }

  // ===== MÉTODOS PARA CONTACTOS =====

  /// Obtiene los contactos del operador actual
  Future<List<ContactoOperador>> obtenerContactosOperador() async {
    try {
      final operador = await obtenerOperador();
      if (operador == null) {
        throw Exception('Operador no encontrado');
      }

      _contactosFuture ??= _contactosService.obtenerContactosPorOperador(
        operadorId: operador.id,
      );

      return await _contactosFuture!;
    } catch (e) {
      debugPrint('Error obteniendo contactos: $e');
      rethrow;
    }
  }

  /// Crea un nuevo contacto para el operador
  Future<ContactoOperador> crearContacto({
    required int tipoContactoCodigo,
    required String descripcion,
  }) async {
    try {
      final operador = await obtenerOperador();
      if (operador == null) {
        throw Exception('Operador no encontrado');
      }

      final contacto = await _contactosService.crearContacto(
        tipoContactoCodigo: tipoContactoCodigo,
        descripcion: descripcion,
        operadorCodigo: operador.id,
        usuarioId: codigoUsuario,
      );

      // Limpiar cache para forzar recarga
      _contactosFuture = null;
      notifyListeners();

      return contacto;
    } catch (e) {
      debugPrint('Error creando contacto: $e');
      rethrow;
    }
  }

  /// Actualiza un contacto existente
  Future<ContactoOperador> actualizarContacto({
    required int contactoId,
    int? tipoContactoCodigo,
    String? descripcion,
  }) async {
    try {
      final contacto = await _contactosService.actualizarContacto(
        contactoId: contactoId,
        tipoContactoCodigo: tipoContactoCodigo,
        descripcion: descripcion,
        usuarioId: codigoUsuario,
      );

      // Limpiar cache para forzar recarga
      _contactosFuture = null;
      notifyListeners();

      return contacto;
    } catch (e) {
      debugPrint('Error actualizando contacto: $e');
      rethrow;
    }
  }

  /// Elimina un contacto
  Future<void> eliminarContacto({
    required int contactoId,
  }) async {
    try {
      await _contactosService.eliminarContacto(
        contactoId: contactoId,
      );

      // Limpiar cache para forzar recarga
      _contactosFuture = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error eliminando contacto: $e');
      rethrow;
    }
  }

  // ===== MÉTODOS PARA TIPOS DE CONTACTO =====

  /// Obtiene todos los tipos de contacto activos
  Future<List<TipoContacto>> obtenerTiposContactosActivos() async {
    try {
      _tiposContactosFuture ??= _tiposContactosService.obtenerTiposContactosActivos();
      return await _tiposContactosFuture!;
    } catch (e) {
      debugPrint('Error obteniendo tipos de contacto: $e');
      rethrow;
    }
  }

  /// Obtiene un tipo de contacto por ID
  Future<TipoContacto?> obtenerTipoContactoPorId({
    required int tipoContactoId,
  }) async {
    try {
      return await _tiposContactosService.obtenerTipoContactoPorId(
        tipoContactoId: tipoContactoId,
      );
    } catch (e) {
      debugPrint('Error obteniendo tipo de contacto: $e');
      rethrow;
    }
  }

  // ===== MÉTODOS PARA AGENCIAS =====

  /// Obtiene las agencias del operador actual
  Future<List<AgenciaSupabase>> obtenerAgenciasDeOperador() async {
    if (_agenciasCache != null) return _agenciasCache!;

    try {
      final operador = await obtenerOperador();
      if (operador == null) {
        throw Exception('Operador no encontrado');
      }

      final agencias = await _agenciasService.obtenerAgenciasDeOperador(
        operadorCod: operador.id,
      );
      _agenciasCache = agencias;
      notifyListeners();
      return agencias;
    } catch (e) {
      debugPrint('Error obteniendo agencias: $e');
      rethrow;
    }
  }

  /// Limpia toda la cache del controlador
  void limpiarCache() {
    _operadorFuture = null;
    _contactosFuture = null;
    _tiposContactosFuture = null;
    _agenciasCache = null;
    notifyListeners();
  }

  // ===== MÉTODOS PARA TIPOS =====

  /// Obtiene todos los tipos de documento activos
  Future<List<Map<String, dynamic>>> obtenerTiposDocumentosActivos() async {
    try {
      return await _tiposDocumentosService.obtenerTiposDocumentosActivos();
    } catch (e) {
      debugPrint('Error obteniendo tipos de documento: $e');
      rethrow;
    }
  }

  /// Obtiene todos los tipos de empresa activos
  Future<List<Map<String, dynamic>>> obtenerTiposEmpresasActivos() async {
    try {
      return await _tiposEmpresasService.obtenerTiposEmpresasActivos();
    } catch (e) {
      debugPrint('Error obteniendo tipos de empresa: $e');
      rethrow;
    }
  }
}
