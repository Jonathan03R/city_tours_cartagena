import 'dart:async';
import 'package:citytourscartagena/core/models/fechas_bloquedas.dart';
import 'package:citytourscartagena/core/services/fechas_bloquedas_service.dart';
import 'package:flutter/material.dart';

class BloqueoFechaController extends ChangeNotifier {
  FechaBloqueada? _bloqueoActual;
  bool _cargando = false;
  String? _error;

  FechaBloqueada? get bloqueoActual => _bloqueoActual;
  bool get cargando => _cargando;
  String? get error => _error;

  Stream<FechaBloqueada?>? _stream;
  StreamSubscription? _streamSub;
  Stream<FechaBloqueada?>? get stream => _stream;

  void listenBloqueo(DateTime fecha) {
    _streamSub?.cancel();
    _stream = FechasBloquedasService.getBloqueoParaFecha(fecha);
    _streamSub = _stream!.listen((bloqueo) {
      if (!hasListeners) return;
      _bloqueoActual = bloqueo;
      notifyListeners();
    });
  }

  Future<void> bloquear(DateTime fecha, String turno, String motivo) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await FechasBloquedasService.bloquearFecha(fecha, turno, motivo);
    } catch (e) {
      _error = e.toString();
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> desbloquear(DateTime fecha) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await FechasBloquedasService.desbloquearFecha(fecha);
    } catch (e) {
      _error = e.toString();
    }
    _cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
