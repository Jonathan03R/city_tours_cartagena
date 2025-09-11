import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/finanzas/finanzas_service.dart';
import 'package:citytourscartagena/core/services/reservas/reservas_service.dart';
import 'package:citytourscartagena/core/utils/date_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

typedef _Metric =
    int Function(
      List<ReservaConAgencia> reservas,
      DateTime inicio,
      DateTime fin, {
      TurnoType? turno,
    });

/// Controller to provide reporting data and calculations for UI
class ReportesController extends ChangeNotifier {
  // ============================================================
  // Campos y constructor
  // ============================================================
  final ReservasController reservasController;
  final FinanzasService _finanzasService = FinanzasService();
  final ReservasService _reservasService = ReservasService();
    final GastosController _gastosController = GastosController();

  ReportesController({ReservasController? reservasController})
    : reservasController = reservasController ?? ReservasController();

  /// Stream of reservations with agency information
  Stream<List<ReservaConAgencia>> get reservasStream =>
      reservasController.getAllReservasConAgenciaStream();

  final List<Map<String, dynamic>> _gastos = [];
  List<Map<String, dynamic>> get gastos => _gastos;

  // Indica si hay más datos para cargar
  final bool _hasMore = true;
  bool get hasMore => _hasMore;

  // Indica si se está cargando
  final bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Último documento cargado (para la paginación)

  // ============================================================
  // Métodos privados auxiliares
  // ============================================================
  List<ChartCategoryData> _agruparPorPeriodo(
    List<ReservaConAgencia> reservas,
    DateTime inicio,
    DateTime fin, {
    TurnoType? turno,
    required FiltroPeriodo tipoAgrupacion,
    required _Metric metric,
  }) {
    final List<ChartCategoryData> resultado = [];

    switch (tipoAgrupacion) {
      case FiltroPeriodo.semana:
        DateTime pi = inicio;
        int semanaNum = 1;
        while (pi.isBefore(fin) || pi.isAtSameMomentAs(fin)) {
          DateTime pf = pi.add(const Duration(days: 6));
          if (pf.isAfter(fin)) pf = fin;

          final valor = metric(reservas, pi, pf, turno: turno);
          final label = (pi.month != pf.month || pi.year != pf.year)
              ? 'Semana $semanaNum (${pi.day} ${DateHelper.nombreMes(pi.month)} ${pi.year} - '
                    '${pf.day} ${DateHelper.nombreMes(pf.month)} ${pf.year})'
              : 'Semana $semanaNum (${pi.day}-${pf.day} ${DateHelper.nombreMes(pi.month)} ${pi.year})';

          resultado.add(ChartCategoryData(label, valor));

          pi = pf.add(const Duration(days: 1));
          semanaNum++;
        }
        break;

      case FiltroPeriodo.mes:
        DateTime pi = DateTime(inicio.year, inicio.month, 1);
        while (pi.isBefore(fin) || pi.isAtSameMomentAs(fin)) {
          DateTime pf = DateTime(
            pi.year,
            pi.month + 1,
            1,
          ).subtract(const Duration(days: 1));
          if (pf.isAfter(fin)) pf = fin;

          final valor = metric(reservas, pi, pf, turno: turno);
          resultado.add(
            ChartCategoryData(
              '${DateHelper.nombreMes(pi.month)} ${pi.year}',
              valor,
            ),
          );

          pi = DateTime(pi.year, pi.month + 1, 1);
        }
        break;

      case FiltroPeriodo.anio:
        for (int y = inicio.year; y <= fin.year; y++) {
          DateTime pi = DateTime(y, 1, 1);
          DateTime pf = DateTime(y, 12, 31);
          if (pi.isBefore(inicio)) pi = inicio;
          if (pf.isAfter(fin)) pf = fin;

          final valor = metric(reservas, pi, pf, turno: turno);
          resultado.add(ChartCategoryData(y.toString(), valor));
        }
        break;
    }

    return resultado;
  }

  // ============================================================
  // Cálculos base
  // ============================================================
  /// Calcula el total de pasajeros en un rango de fechas

  // ============================================================
  // Agrupaciones públicas
  // ============================================================
  // Versión pública para agrupar pasajeros
  List<ChartCategoryData> agruparPasajerosPorRangos(
    List<ReservaConAgencia> reservas,
    List<DateTimeRange> rangos, {
    TurnoType? turno,
  }) {
    final List<ChartCategoryData> resultado = [];
    final hoy = DateTime.now();
    final lunesActual = hoy.subtract(Duration(days: hoy.weekday - 1));
    for (int i = 0; i < rangos.length; i++) {
      final rango = rangos[i];
      final valor = _finanzasService.calcularPasajerosEnRango(
        reservas,
        rango.start,
        rango.end,
        turno: turno,
      );
      String label;
      if (rango.start.year == lunesActual.year && rango.start.month == lunesActual.month && rango.start.day == lunesActual.day) {
        label = 'Semana Actual';
      } else {
        label = '${rango.start.day.toString().padLeft(2, '0')}/${rango.start.month.toString().padLeft(2, '0')} - '
                '${rango.end.day.toString().padLeft(2, '0')}/${rango.end.month.toString().padLeft(2, '0')}';
      }
      resultado.add(ChartCategoryData(label, valor));
    }
    return resultado;
  }
  

  // Devuelve agrupación de ganancias por múltiples rangos
  List<ChartCategoryData> agruparGananciasPorRangos(
    List<ReservaConAgencia> reservas,
    List<DateTimeRange> rangos, {
    TurnoType? turno,
    required List<Map<String, dynamic>> gastos,
  }) {
    final List<ChartCategoryData> resultado = [];

    for (int i = 0; i < rangos.length; i++) {
      final rango = rangos[i];
      final ganancias = _finanzasService
          .calcularGananciasEnRango(
            reservas,
            rango.start,
            rango.end,
            turno: turno,
          )
          .round();

      final gastosFiltrados = gastos.where((gasto) {
        final fecha = (gasto['fecha'] as Timestamp).toDate();
        final fechaSolo = DateTime(fecha.year, fecha.month, fecha.day);
        final startSolo = DateTime(rango.start.year, rango.start.month, rango.start.day);
        final endSolo = DateTime(rango.end.year, rango.end.month, rango.end.day);
        return fechaSolo.isAfter(startSolo.subtract(const Duration(days: 1))) &&
               fechaSolo.isBefore(endSolo.add(const Duration(days: 1)));
      }).toList();

      final gastosValor = gastosFiltrados.fold(0.0, (sum, gasto) => sum + (gasto['monto'] as double)).round();

      // Debug prints
            debugPrint('Rango ${i + 1}: ${rango.start} - ${rango.end}');
      debugPrint('Ganancias: $ganancias');
      debugPrint('Gastos filtrados: ${gastosFiltrados.length}');
      debugPrint('Montos de gastos filtrados: ${gastosFiltrados.map((g) => g['monto'])}'); // Nuevo debug
      debugPrint('Gastos valor: $gastosValor');
      debugPrint('Total gastos en lista: ${gastos.length}');


      final label = 'Semana ${i + 1}';

      resultado.add(ChartCategoryData(label, ganancias, gastosValor));
    }

    return resultado;
  }

  // Versión pública para agrupar ganancias
  List<ChartCategoryData> agruparGananciasPorPeriodo(
    List<ReservaConAgencia> reservas,
    DateTime inicio,
    DateTime fin, {
    TurnoType? turno,
    required FiltroPeriodo tipoAgrupacion,
  }) {
    return _agruparPorPeriodo(
      reservas,
      inicio,
      fin,
      turno: turno,
      tipoAgrupacion: tipoAgrupacion,
      metric: (list, i, f, {turno}) => _finanzasService
          .calcularGananciasEnRango(list, i, f, turno: turno)
          .round(),
    );
  }
  // ============================================================
  // Cálculos por semana
  // ============================================================

  List<ChartCategoryData> calcularPasajerosPorSemana({
    required List<ReservaConAgencia> reservas,
    required DateTime fecha,
    TurnoType? turno,
  }) {
    final rango = _finanzasService.obtenerRangoPorFecha(
      fecha,
      FiltroPeriodo.semana,
    );

    final Map<int, int> pasajerosPorDia = {for (var i = 1; i <= 7; i++) i: 0};

    for (var reservaConAgencia in reservas) {
      final reserva = reservaConAgencia.reserva;
      final fechaSolo = DateTime(
        reserva.fecha.year,
        reserva.fecha.month,
        reserva.fecha.day,
      );
      for (int i = 1; i <= 7; i++) {
        final diaSemana = rango.start.add(Duration(days: i - 1));
        final diaSolo = DateTime(
          diaSemana.year,
          diaSemana.month,
          diaSemana.day,
        );
        if (fechaSolo == diaSolo) {
          if (turno != null && reserva.turno != turno) break;
          pasajerosPorDia[i] = (pasajerosPorDia[i] ?? 0) + (reserva.pax);
          break;
        }
      }
    }

    return pasajerosPorDia.entries.map((entry) {
      final dia = DateHelper.nombreDia(entry.key);
      final pasajeros = entry.value;
      return ChartCategoryData(dia, pasajeros);
    }).toList();
  }

  List<ChartCategoryData> calcularGananciasPorSemana({
    required List<ReservaConAgencia> reservas,
    required DateTime fecha,
    TurnoType? turno,
  }) {
    final rango = _finanzasService.obtenerRangoPorFecha(
      fecha,
      FiltroPeriodo.semana,
    );

    final Map<int, double> gananciasPorDia = {
      for (var i = 1; i <= 7; i++) i: 0.0,
    };

    for (var reservaConAgencia in reservas) {
      final reserva = reservaConAgencia.reserva;
      final fechaSolo = DateTime(
        reserva.fecha.year,
        reserva.fecha.month,
        reserva.fecha.day,
      );
      for (int i = 1; i <= 7; i++) {
        final diaSemana = rango.start.add(Duration(days: i - 1));
        final diaSolo = DateTime(
          diaSemana.year,
          diaSemana.month,
          diaSemana.day,
        );
        if (fechaSolo == diaSolo) {
          if (turno != null && reserva.turno != turno) break;
          gananciasPorDia[i] = gananciasPorDia[i]! + reserva.ganancia;
          break;
        }
      }
    }

    return gananciasPorDia.entries.map((entry) {
      final dia = DateHelper.nombreDia(entry.key);
      final ganancia = entry.value.round();
      return ChartCategoryData(dia, ganancia);
    }).toList();
  }
}

// ============================================================
// Modelos
// ============================================================

class PasajerosData {
  final int totalPas;
  final double totalRev;
  final List<ChartCategoryData> data;
  PasajerosData({
    required this.totalPas,
    required this.totalRev,
    required this.data,
  });
}

class ChartCategoryData {
  final String label;
  final int value1; // Ganancias
  final int value2; // Gastos
  ChartCategoryData(this.label, this.value1, [this.value2 = 0]);
}
class MetasHistoryData {
  final String id;
  final DateTime date;
  final int weeklyGoal;
  final int monthlyGoal;
  final int pasWeek;
  final int pasMonth;
  final bool weeklyOk;
  final bool monthlyOk;
  MetasHistoryData({
    required this.id,
    required this.date,
    required this.weeklyGoal,
    required this.monthlyGoal,
    required this.pasWeek,
    required this.pasMonth,
    required this.weeklyOk,
    required this.monthlyOk,
  });
}

class FinanceCategoryData {
  final String label;
  final double expenses;
  final double revenues;
  final double utility; // ingresos – gastos
  final double margin; // utilidad / ingresos * 100
  FinanceCategoryData({
    required this.label,
    required this.expenses,
    required this.revenues,
    required this.utility,
    required this.margin,
  });
}

