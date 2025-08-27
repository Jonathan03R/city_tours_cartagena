import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/finanzas/finanzas_service.dart';
import 'package:citytourscartagena/core/services/finanzas/gastos_service.dart';
import 'package:citytourscartagena/core/utils/date_helper.dart';
import 'package:flutter/material.dart';

class GastosController extends ChangeNotifier {
  final GastosService _gastosService = GastosService();
  final FinanzasService _finanzasService = FinanzasService();
  final ReservasController reservasController;
  List<Map<String, dynamic>> _gastos = [];
  List<Map<String, dynamic>> get gastos => _gastos;
  bool _cargando = true;
  bool get cargando => _cargando;
   Stream<List<ReservaConAgencia>> get reservasStream =>
      reservasController.getAllReservasConAgenciaStream();

   GastosController({ReservasController? reservasController})
      : reservasController = reservasController ?? ReservasController() {
    _escucharGastosEnTiempoReal();
  }

  void _escucharGastosEnTiempoReal() {
    _gastosService.obtenerEnTiempoReal(limite: 10).listen((snapshot) {
      _gastos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
      notifyListeners(); // Notifica a la vista que los datos han cambiado
    });
  }
  Future<void> cargarMasGastos() async {
    if (_cargando) return; // Evita múltiples llamadas simultáneas
    _cargando = true;
    notifyListeners();

    try {
      final nuevosGastos = await _gastosService.obtener(
        limite: 10,
        ultimoDocumento: _gastos.isNotEmpty
            ? _gastos.last['documentSnapshot']
            : null,
      );

      _gastos.addAll(
        nuevosGastos.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, 'documentSnapshot': doc, ...data};
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error al cargar más gastos: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
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

        final rev = _finanzasService.calcularGananciasEnRango(reservas, pi, pf, turno: turno);
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

        final rev = _finanzasService.calcularGananciasEnRango(reservas, pi, pf, turno: turno);
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

        final rev = _finanzasService.calcularGananciasEnRango(reservas, pi, pf, turno: turno);
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
}
