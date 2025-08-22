import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/metrics_service.dart';
import 'package:flutter/material.dart';

/// Controller to provide reporting data and calculations for UI
class ReportesController extends ChangeNotifier {
  /// Calcula el total de pasajeros en un rango de fechas
  int calcularPasajerosEnRango(List<ReservaConAgencia> reservas, DateTime inicio, DateTime fin) {
    print('DEBUG: --- calcularPasajerosEnRango ---');
    print('DEBUG: Rango recibido: inicio=${inicio.toIso8601String()} fin=${fin.toIso8601String()}');
    int totalPasajeros = 0;
    for (var reserva in reservas) {
      final fechaReservaOriginal = reserva.reserva.fecha;
      final fechaReserva = DateTime(
        fechaReservaOriginal.year,
        fechaReservaOriginal.month,
        fechaReservaOriginal.day,
      );
      final inicioDia = DateTime(inicio.year, inicio.month, inicio.day);
      final finDia = DateTime(fin.year, fin.month, fin.day);
      final incluida = !fechaReserva.isBefore(inicioDia) && !fechaReserva.isAfter(finDia);
      print('DEBUG: Reserva ${reserva.reserva.id} - Fecha: $fechaReservaOriginal (normalizada: $fechaReserva) - Incluida: $incluida');
      if (incluida) {
        totalPasajeros += reserva.reserva.pax;
        print('DEBUG: --> Suma pax: ${reserva.reserva.pax} (Total acumulado: $totalPasajeros)');
      }
    }
    print('DEBUG: Total pasajeros en rango: $totalPasajeros');
    return totalPasajeros;
  }
  /// Agrega un nuevo gasto a la colección 'gastos' en Firestore
  /// Guarda el monto, fecha y descripción opcional
  Future<void> agregarGasto({
    required double monto,
    required DateTime fecha,
    String? descripcion,
  }) async {
    await metricsService.addExpense(
      amount: monto,
      date: fecha,
      description: descripcion,
    );
  }

  /// Calcula las ganancias (COP) agrupadas por semana (Domingo-Sábado), mes (Enero-Diciembre) o año (todos los años en la base).
  /// Solo cuenta reservas donde estado == "pagada". Si no hay reservas en una categoría, se muestra 0.
  /// Para reservas cuyo "turno" es "privado", el total es solo costoAsiento (no se multiplica por pax).
  /// Retorna una lista de ChartCategoryData con la etiqueta y el valor de ganancia.
  List<ChartCategoryData> calcGanancias({
    required List<ReservaConAgencia> list,
    required String periodo,
  }) {
    final now = DateTime.now();
    List<ChartCategoryData> data = [];

    if (periodo == 'Semana') {
      final primerDiaSemana = now.subtract(Duration(days: now.weekday % 7));
      final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
      List<double> gananciasPorDia = List.filled(7, 0.0);
      for (var ra in list) {
        final d = ra.reserva.fecha;
        if (ra.reserva.estado != EstadoReserva.pagada) continue;
        if (d.isBefore(primerDiaSemana) ||
            d.isAfter(primerDiaSemana.add(const Duration(days: 6))))
          continue;
        int dia = d.weekday % 7; // Domingo=0, Lunes=1, ..., Sábado=6
        final ingreso = ra.reserva.turno == TurnoType.privado
            ? ra.reserva.costoAsiento
            : ra.reserva.costoAsiento * ra.reserva.pax;
        gananciasPorDia[dia] += ingreso;
      }
      for (int i = 0; i < 7; i++) {
        data.add(ChartCategoryData(dias[i], gananciasPorDia[i].round()));
      }
    } else if (periodo == 'Mes') {
      final meses = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      int mesActual = now.month;
      List<double> gananciasPorMes = List.filled(mesActual, 0.0);
      for (var ra in list) {
        final d = ra.reserva.fecha;
        if (ra.reserva.estado != EstadoReserva.pagada) continue;
        if (d.year != now.year || d.month > mesActual) continue;
        final ingreso = ra.reserva.turno == TurnoType.privado
            ? ra.reserva.costoAsiento
            : ra.reserva.costoAsiento * ra.reserva.pax;
        gananciasPorMes[d.month - 1] += ingreso;
      }
      for (int i = 0; i < mesActual; i++) {
        data.add(ChartCategoryData(meses[i], gananciasPorMes[i].round()));
      }
    } else if (periodo == 'Año') {
      final anios = <int>{};
      for (var ra in list) {
        anios.add(ra.reserva.fecha.year);
      }
      final aniosOrdenados = anios.toList()..sort();
      Map<int, double> gananciasPorAnio = {
        for (var a in aniosOrdenados) a: 0.0,
      };
      for (var ra in list) {
        final anio = ra.reserva.fecha.year;
        if (ra.reserva.estado != EstadoReserva.pagada) continue;
        final ingreso = ra.reserva.turno == TurnoType.privado
            ? ra.reserva.costoAsiento
            : ra.reserva.costoAsiento * ra.reserva.pax;
        gananciasPorAnio[anio] = (gananciasPorAnio[anio] ?? 0) + ingreso;
      }
      for (final anio in aniosOrdenados) {
        data.add(
          ChartCategoryData(anio.toString(), gananciasPorAnio[anio]!.round()),
        );
      }
    }
    return data;
  }

  final ReservasController reservasController;
  final MetricsService metricsService;

  ReportesController({
    ReservasController? reservasController,
    MetricsService? metricsService,
  }) : reservasController = reservasController ?? ReservasController(),
       metricsService = metricsService ?? MetricsService();

  /// Stream of reservations with agency information
  Stream<List<ReservaConAgencia>> get reservasStream =>
      reservasController.getAllReservasConAgenciaStream();

  /// Calcula los pasajeros agrupados por semana (Domingo-Sábado), mes (Enero-Diciembre) o año (todos los años en la base).
  /// Si no hay reservas en una categoría, se muestra 0.
  /// Para reservas cuyo "turno" es "privado", el conteo de pasajeros es 1 y el ingreso es solo costoAsiento.
  /// Para las demás reservas, el conteo de pasajeros es pax y el ingreso es costoAsiento * pax.
  PasajerosData calcPasajeros({
    required List<ReservaConAgencia> list,
    required String periodo,
  }) {
    final now = DateTime.now();
    int totalPas = 0;
    double totalRev = 0;
    List<ChartCategoryData> data = [];

    print('DEBUG calcPasajeros: periodo=$periodo, reservas=${list.length}');

    if (periodo == 'Semana') {
      final primerDiaSemana = now.subtract(Duration(days: now.weekday % 7));
      final dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
      List<int> paxPorDia = List.filled(7, 0);
      for (var ra in list) {
        final d = ra.reserva.fecha;
        if (d.isBefore(primerDiaSemana) ||
            d.isAfter(primerDiaSemana.add(const Duration(days: 6))))
          continue;
        int dia = d.weekday % 7;
        final isPrivado = ra.reserva.turno == TurnoType.privado;
        final count = isPrivado ? 1 : ra.reserva.pax;
        final ingreso = isPrivado
            ? ra.reserva.costoAsiento
            : ra.reserva.costoAsiento * ra.reserva.pax;
        print(
          'Reserva: fecha=${d.toIso8601String()}, turno=${ra.reserva.turno}, pax=${ra.reserva.pax}, costoAsiento=${ra.reserva.costoAsiento}, count=$count, ingreso=$ingreso',
        );
        paxPorDia[dia] += count;
        totalPas += count;
        if (ra.reserva.estado == EstadoReserva.pagada) {
          totalRev += ingreso;
        }
      }
      for (int i = 0; i < 7; i++) {
        data.add(ChartCategoryData(dias[i], paxPorDia[i]));
      }
    } else if (periodo == 'Mes') {
      final meses = [
        'Ene',
        'Feb',
        'Mar',
        'Abr',
        'May',
        'Jun',
        'Jul',
        'Ago',
        'Sep',
        'Oct',
        'Nov',
        'Dic',
      ];
      int mesActual = now.month;
      List<int> paxPorMes = List.filled(mesActual, 0);
      for (var ra in list) {
        final d = ra.reserva.fecha;
        if (d.year != now.year || d.month > mesActual) continue;
        final isPrivado = ra.reserva.turno == TurnoType.privado;
        final count = isPrivado ? 1 : ra.reserva.pax;
        final ingreso = isPrivado
            ? ra.reserva.costoAsiento
            : ra.reserva.costoAsiento * ra.reserva.pax;
        print(
          'Reserva: fecha=${d.toIso8601String()}, turno=${ra.reserva.turno}, pax=${ra.reserva.pax}, costoAsiento=${ra.reserva.costoAsiento}, count=$count, ingreso=$ingreso',
        );
        paxPorMes[d.month - 1] += count;
        totalPas += count;
        if (ra.reserva.estado == EstadoReserva.pagada) {
          totalRev += ingreso;
        }
      }
      for (int i = 0; i < mesActual; i++) {
        data.add(ChartCategoryData(meses[i], paxPorMes[i]));
      }
    } else if (periodo == 'Año') {
      final anos = <int>{};
      for (var ra in list) {
        anos.add(ra.reserva.fecha.year);
      }
      final anosOrdenados = anos.toList()..sort();
      Map<int, int> paxPorAAno = {for (var a in anosOrdenados) a: 0};
      for (var ra in list) {
        final ano = ra.reserva.fecha.year;
        final isPrivado = ra.reserva.turno == TurnoType.privado;
        final count = isPrivado ? 1 : ra.reserva.pax;
        final ingreso = isPrivado
            ? ra.reserva.costoAsiento
            : ra.reserva.costoAsiento * ra.reserva.pax;
        print(
          'Reserva: fecha=${ra.reserva.fecha.toIso8601String()}, turno=${ra.reserva.turno}, pax=${ra.reserva.pax}, costoAsiento=${ra.reserva.costoAsiento}, count=$count, ingreso=$ingreso',
        );
        paxPorAAno[ano] = (paxPorAAno[ano] ?? 0) + count;
        totalPas += count;
        if (ra.reserva.estado == EstadoReserva.pagada) {
          totalRev += ingreso;
        }
      }
      for (final ano in anosOrdenados) {
        data.add(ChartCategoryData(ano.toString(), paxPorAAno[ano]!));
      }
    }
    print('DEBUG calcPasajeros: totalPas=$totalPas, totalRev=$totalRev');
    return PasajerosData(totalPas: totalPas, totalRev: totalRev, data: data);
  }

  /// Obtiene el historial de gastos desde el servicio
  Future<List<Map<String, dynamic>>> obtenerHistorialGastos() async {
    return await metricsService.getExpensesHistory();
  }

  /// Elimina un gasto por ID usando el servicio
  Future<void> eliminarGasto(String id) async {
    await metricsService.deleteExpense(id);
    notifyListeners();
  }

  /// Agrega una meta semanal de pasajeros
  Future<void> agregarMetaSemanalPasajeros({
    required int meta,
    required DateTime fecha,
  }) async {
    await metricsService.addWeeklyPassengerGoal(goal: meta, date: fecha);
    notifyListeners(); // Notifica a los listeners para actualizar la vista
  }

  /// Actualiza una meta semanal de pasajeros existente
  Future<void> actualizarMetaSemanalPasajeros(String id, int nuevaMeta) async {
    await metricsService.updateWeeklyPassengerGoal(id, nuevaMeta);
    notifyListeners();
  }

  /// Obtiene la meta semanal de pasajeros para una semana específica
  Future<Map<String, dynamic>?> obtenerMetaSemanalPasajeros(
    DateTime fecha,
  ) async {
    return await metricsService.getWeeklyPassengerGoal(fecha);
  }

  /// Calcula el total de pasajeros de la semana actual
  int calcularPasajerosSemanaActual(List<ReservaConAgencia> reservas) {
    final now = DateTime.now();
    final primerDiaSemana = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday % 7)); // Domingo
    final ultimoDiaSemana = primerDiaSemana.add(const Duration(days: 6)); // Sábado

    print('DEBUG: Calculando pasajeros para la semana: $primerDiaSemana - $ultimoDiaSemana');

    // Filtra las reservas que están dentro del rango de la semana actual
    final reservasSemanaActual = reservas.where((reserva) {
      final fechaReserva = reserva.reserva.fecha;
      final enRango = fechaReserva.isAfter(primerDiaSemana.subtract(const Duration(seconds: 1))) &&
                      fechaReserva.isBefore(ultimoDiaSemana.add(const Duration(seconds: 1)));
      print('DEBUG: Reserva ${reserva.reserva.id} - Fecha: $fechaReserva - En rango: $enRango');
      return enRango;
    }).toList();

    // Suma los pasajeros de las reservas filtradas
    int totalPasajeros = 0;
    for (var reserva in reservasSemanaActual) {
      final pasajeros = reserva.reserva.pax;
      totalPasajeros += pasajeros;
      print('DEBUG: Reserva ${reserva.reserva.id} - Pasajeros: $pasajeros - Total acumulado: $totalPasajeros');
    }

    print('DEBUG: Total pasajeros esta semana: $totalPasajeros');
    return totalPasajeros;
  }

  /// Obtiene el historial de metas desde el servicio
  Future<List<Map<String, dynamic>>> obtenerHistorialMetas() async {
    return await metricsService.getAllWeeklyPassengerGoals();
  }
}

// / Data model for passengers tab
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
  final int value;
  ChartCategoryData(this.label, this.value);
}

/// Data model for metas history entry with compliance
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
