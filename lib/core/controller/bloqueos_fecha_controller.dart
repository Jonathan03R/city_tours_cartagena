import 'package:flutter/material.dart';
import '../models/fechas_bloquedas.dart';
import '../services/fechas_bloquedas_service.dart';

class BloqueosFechaController extends ChangeNotifier {
  final DateTime fecha;
  BloqueosFechaController({required this.fecha});

  Stream<List<FechaBloqueada>> get bloqueosStream =>
      FechasBloquedasService.getBloqueosParaFecha(fecha);
}
