import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:flutter/foundation.dart';

class AgenciasController extends ChangeNotifier {
  final OperadoresController operadoresController;
  final AgenciasService _service = AgenciasService();

  AgenciasController({required this.operadoresController});

  // Future<List<Agencia>> obtenerAgenciasDeOperador() async {
  //   try {
  //     final operador = await operadoresController.obtenerOperador();
  //     if (operador == null) throw Exception('Operador no encontrado');
  //     final agencias = await _service.obtenerAgenciasDeOperador(
  //       operadorCod: operador.id,
  //     );
  //     return agencias;
  //   } catch (e) {
  //     debugPrint('Error obteniendo agencias: $e');
  //     rethrow; // ¡Lanza la excepción!
  //   }
  // }
}
