import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/finanzas/finanzas_service.dart';
import 'package:citytourscartagena/core/services/finanzas/gastos_service.dart';
import 'package:citytourscartagena/core/utils/date_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GastosController extends ChangeNotifier {
  final GastosService _gastosService = GastosService();
  final FinanzasService _finanzasService = FinanzasService();
  final ReservasController reservasController = ReservasController();
  List<Map<String, dynamic>> _gastos = [];
  List<Map<String, dynamic>> get gastos => _gastos;
  bool _cargando = true;
  bool get cargando => _cargando;

  int _paginaActual = 1;
  int _totalPaginas = 1;
  int _limite = 5;
  int _totalGastos = 0;

  DocumentSnapshot? _ultimoDoc;
  final List<DocumentSnapshot> _historialDocs = [];
  List<QueryDocumentSnapshot> gastosActuales = [];
  final List<List<QueryDocumentSnapshot>> _cachePaginas = [];

  int get paginaActual => _paginaActual;
  int get totalPaginas => _totalPaginas;
  int get totalGastos => _totalGastos;
  int get limite => _limite;

  Stream<List<ReservaConAgencia>> get reservasStream =>
      reservasController.getAllReservasConAgenciaStream();

  Future<void> inicializar({int limite = 5}) async {
    _limite = limite;
    _paginaActual = 1;
    _ultimoDoc = null;
    _historialDocs.clear();

    _totalGastos = await _gastosService.obtenerCantidadGastos();
    _totalPaginas = (_totalGastos / _limite).ceil();

    await cargarPagina();
  }

  Future<double> obtenerSumaGastosSemanaActual() async {
    final now = DateTime.now();
    final primerDiaSemana = now.subtract(Duration(days: now.weekday % 7));
    final ultimoDiaSemana = primerDiaSemana.add(const Duration(days: 6));
    return await _gastosService.obtenerSumaDeGastosEntre(primerDiaSemana, ultimoDiaSemana);
  }

  Future<void> cargarPagina() async {
    // Si ya está en cache, la usamos
    if (_paginaActual <= _cachePaginas.length) {
      gastosActuales = _cachePaginas[_paginaActual - 1];
      notifyListeners();
      return;
    }

    // Si no está en cache, pedimos a Firestore
    final snapshot = await _gastosService.obtenerPagina(
      limite: _limite,
      ultimoDoc: _ultimoDoc,
    );

    gastosActuales = snapshot.docs;

    if (gastosActuales.isNotEmpty) {
      _ultimoDoc = gastosActuales.last;
    }

    // Guardamos en cache
    _cachePaginas.add(gastosActuales);

    notifyListeners();
  }

  Future<void> siguientePagina() async {
    if (_paginaActual < _totalPaginas) {
      _paginaActual++;
      await cargarPagina();
    }
  }

  Future<void> paginaAnterior() async {
    if (_paginaActual > 1) {
      _paginaActual--;
      // Ya está en cache, no hace falta pedir a Firestore
      gastosActuales = _cachePaginas[_paginaActual - 1];
      notifyListeners();
    }
  }

  String get estadoTexto {
    final desde = ((_paginaActual - 1) * _limite) + 1;
    final hasta = ((_paginaActual - 1) * _limite) + gastosActuales.length;
    return "Página $_paginaActual de $_totalPaginas "
        "($desde–$hasta de $_totalGastos)";
  }

  Future<void> agregarGasto({
    required double monto,
    required String descripcion,
    required DateTime fecha,
  }) async {
    try {
      _cargando = true;
      notifyListeners();
      await _gastosService.agregar(
        monto: monto,
        descripcion: descripcion,
        fecha: fecha,
      );
    } catch (e) {
      debugPrint('Error al agregar gasto: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> eliminarGasto(String id) async {
    try {
      _cargando = true;
      notifyListeners();
      await _gastosService.eliminar(id);
    } catch (e) {
      debugPrint('Error al eliminar gasto: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Modelo para métricas financieras por periodo.
  /// Agrupa gastos + ganancias + utilidad + margen según el periodo seleccionado.
  /// Usa las mismas reglas de intervalo (semana/mes/año) que _agruparPorPeriodo.
  Future<List<FinanceCategoryData>> agruparFinanzasPorPeriodo(
    List<ReservaConAgencia> reservas,
    DateTime inicio,
    DateTime fin, {
    TurnoType? turno,
    required String tipoAgrupacion,
  }) async {
    final List<FinanceCategoryData> resultado = [];

    if (tipoAgrupacion == 'semana') {
      DateTime pi = inicio;
      int semanaNum = 1;
      while (pi.isBefore(fin) || pi.isAtSameMomentAs(fin)) {
        DateTime pf = pi.add(const Duration(days: 6));
        if (pf.isAfter(fin)) pf = fin;

        final rev = _finanzasService.calcularGananciasEnRango(
          reservas,
          pi,
          pf,
          turno: turno,
        );
        final exp = await _gastosService.obtenerSumaDeGastosEntre(pi, pf);
        final util = rev - exp;
        final double margin = rev != 0 ? util / rev * 100 : 0;

        final label = 'Semana $semanaNum';
        resultado.add(
          FinanceCategoryData(
            label: label,
            expenses: exp,
            revenues: rev,
            utility: util,
            margin: margin,
          ),
        );

        pi = pf.add(const Duration(days: 1));
        semanaNum++;
      }
    } else if (tipoAgrupacion == 'mes') {
      DateTime pi = DateTime(inicio.year, inicio.month, 1);
      while (pi.isBefore(fin) || pi.isAtSameMomentAs(fin)) {
        DateTime pf = DateTime(
          pi.year,
          pi.month + 1,
          1,
        ).subtract(const Duration(days: 1));
        if (pf.isAfter(fin)) pf = fin;

        final rev = _finanzasService.calcularGananciasEnRango(
          reservas,
          pi,
          pf,
          turno: turno,
        );
        final exp = await _gastosService.obtenerSumaDeGastosEntre(pi, pf);
        final util = rev - exp;
        final double margin = rev != 0 ? util / rev * 100 : 0;

        final label = '${DateHelper.nombreMes(pi.month)} ${pi.year}';
        resultado.add(
          FinanceCategoryData(
            label: label,
            expenses: exp,
            revenues: rev,
            utility: util,
            margin: margin,
          ),
        );

        pi = DateTime(pi.year, pi.month + 1, 1);
      }
    } else if (tipoAgrupacion == 'año') {
      for (int y = inicio.year; y <= fin.year; y++) {
        DateTime pi = DateTime(y, 1, 1);
        DateTime pf = DateTime(y, 12, 31);
        if (pi.isBefore(inicio)) pi = inicio;
        if (pf.isAfter(fin)) pf = fin;

        final rev = _finanzasService.calcularGananciasEnRango(
          reservas,
          pi,
          pf,
          turno: turno,
        );
        final exp = await _gastosService.obtenerSumaDeGastosEntre(pi, pf);
        final util = rev - exp;
        final double margin = rev != 0 ? util / rev * 100 : 0;

        final label = y.toString();
        resultado.add(
          FinanceCategoryData(
            label: label,
            expenses: exp,
            revenues: rev,
            utility: util,
            margin: margin,
          ),
        );
      }
    }

    return resultado;
  }

  Future<Map<String, double>> calcularTotales(
    List<FinanceCategoryData> datos,
  ) async {
    final double totalGastos = datos.fold(
      0,
      (suma, item) => suma + item.expenses,
    );
    final double totalGanancias = datos.fold(
      0,
      (suma, item) => suma + item.revenues,
    );
    final double utilidadNeta = datos.fold(
      0,
      (suma, item) => suma + item.utility,
    );

    // Margen global: utilidad total / ingresos totales
    final double margen = totalGanancias != 0
        ? (utilidadNeta / totalGanancias) * 100
        : 0;

    return {
      "gastos": totalGastos,
      "ganancias": totalGanancias,
      "utilidad": utilidadNeta,
      "margen": margen,
    };
  }
}
