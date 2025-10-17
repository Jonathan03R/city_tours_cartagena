import 'package:flutter/material.dart';

class RegistroWizardController extends ChangeNotifier {
  int _pasoActual = 0;
  final int _totalPasos = 5;
  
  // Controladores para cada campo
  final nombreController = TextEditingController();
  final apellidoController = TextEditingController();
  final aliasController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String tipoEquipo = '';
  final codigoRelacionController = TextEditingController();
  
  // Estado de validación para cada paso
  bool _paso1Valido = false;
  bool _paso2Valido = false;
  bool _paso3Valido = false;
  bool _paso4Valido = false;
  bool _paso5Valido = false;

  // Getters
  int get pasoActual => _pasoActual;
  int get totalPasos => _totalPasos;
  bool get esUltimoPaso => _pasoActual == _totalPasos - 1;
  bool get esPrimerPaso => _pasoActual == 0;
  double get progreso => (_pasoActual + 1) / _totalPasos;
  
  bool get pasoActualValido {
    switch (_pasoActual) {
      case 0: return _paso1Valido;
      case 1: return _paso2Valido;
      case 2: return _paso3Valido;
      case 3: return _paso4Valido;
      case 4: return _paso5Valido;
      default: return false;
    }
  }

  // Métodos de navegación
  void siguientePaso() {
    if (_pasoActual < _totalPasos - 1 && pasoActualValido) {
      _pasoActual++;
      notifyListeners();
    }
  }

  void pasoAnterior() {
    if (_pasoActual > 0) {
      _pasoActual--;
      notifyListeners();
    }
  }

  void irAPaso(int paso) {
    if (paso >= 0 && paso < _totalPasos) {
      _pasoActual = paso;
      notifyListeners();
    }
  }

  // Métodos de validación
  void validarPaso1() {
    _paso1Valido = nombreController.text.isNotEmpty && 
                   apellidoController.text.isNotEmpty && 
                   aliasController.text.isNotEmpty;
    notifyListeners();
  }

  void validarPaso2() {
    _paso2Valido = emailController.text.contains('@') && 
                   emailController.text.isNotEmpty;
    notifyListeners();
  }

  void validarPaso3() {
    _paso3Valido = passwordController.text.length >= 6;
    notifyListeners();
  }

  void validarPaso4() {
    _paso4Valido = tipoEquipo.isNotEmpty;
    notifyListeners();
  }

  void validarPaso5() {
    _paso5Valido = codigoRelacionController.text.isNotEmpty;
    notifyListeners();
  }

  void seleccionarTipoEquipo(String tipo) {
    tipoEquipo = tipo;
    validarPaso4();
  }

  // Obtener datos para registro
  Map<String, dynamic> obtenerDatosRegistro() {
    return {
      'nombre': nombreController.text,
      'apellido': apellidoController.text,
      'alias': aliasController.text,
      'email': emailController.text,
      'password': passwordController.text,
      'rol': 2, // Siempre 2 como especificaste
      'tipoUsuario': tipoEquipo,
      'codigoRelacion': int.tryParse(codigoRelacionController.text) ?? 0,
    };
  }

  void reiniciar() {
    _pasoActual = 0;
    nombreController.clear();
    apellidoController.clear();
    aliasController.clear();
    emailController.clear();
    passwordController.clear();
    tipoEquipo = '';
    codigoRelacionController.clear();
    _paso1Valido = false;
    _paso2Valido = false;
    _paso3Valido = false;
    _paso4Valido = false;
    _paso5Valido = false;
    notifyListeners();
  }

  @override
  void dispose() {
    nombreController.dispose();
    apellidoController.dispose();
    aliasController.dispose();
    emailController.dispose();
    passwordController.dispose();
    codigoRelacionController.dispose();
    super.dispose();
  }
}
