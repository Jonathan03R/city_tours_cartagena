import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/services/configuracion_service.dart';
import 'package:flutter/material.dart';

class ConfiguracionController extends ChangeNotifier {
  Configuracion? configuracion;

  ConfiguracionController() {
    cargarConfiguracion();
  }

  Future<void> cargarConfiguracion() async {
    configuracion = await ConfiguracionService.getConfiguracion();
    notifyListeners();
  }

  Future<void> actualizarPrecio(double nuevoPrecio) async {
    await ConfiguracionService.actualizarPrecio(nuevoPrecio);
    await cargarConfiguracion();
  }
}
