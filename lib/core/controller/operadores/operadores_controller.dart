import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/operadores/operdadores.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:citytourscartagena/core/services/colaboradores/colaboradores_service.dart';
import 'package:flutter/foundation.dart';

class OperadoresController extends ChangeNotifier {
  final OperadoresService _service = OperadoresService();
  final AgenciasService _agenciasService = AgenciasService();
  final AuthSupabaseController auth;
  Future<Operadores?>? _operadorFuture;

  OperadoresController(this.auth);

  int get codigoUsuario => auth.perfilUsuario!.usuario.codigo;

  Future<Operadores?> obtenerOperador() {
    _operadorFuture ??= _obtenerOperadorInterno();
    return _operadorFuture!;
  }

  Future<Operadores?> _obtenerOperadorInterno() async {
    try {
      final operadorid = await _service.obtenerIdOperador(
        idUsuario: codigoUsuario,
      );
      final res = await _service.obtener(id: operadorid);
      return res;
    } catch (e) {
      return null;
    }
  }

  Future<List<AgenciaSupabase>> obtenerAgenciasDeOperador() async {
    try {
      final operador = await obtenerOperador();
      if (operador == null) throw Exception('Operador no encontrado');
      final agencias = await _agenciasService.obtenerAgenciasDeOperador(
        operadorCod: operador.id,
      );
      return agencias;
    } catch (e) {
      debugPrint('Error obteniendo agencias: $e');
      rethrow;
    }
  }

  // Future<Operadores?> obtenerOperador() async {
  //   try {
  //     final operadorid = await _service.obtenerIdOperador(
  //       idUsuario: codigoUsuario,
  //     );
  //     final res = await _service.obtener(id: operadorid);

  //     debugPrint('Operador: $res');
  //     return res;
  //   } catch (e) {
  //     debugPrint('Error en obtenerOperador(): $e');
  //     return null; // O lanza excepción si prefieres
  //   }
  // }
}
