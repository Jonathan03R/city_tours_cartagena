import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:flutter/material.dart';

class FiltroFlexibleController extends ChangeNotifier {
  FiltroPeriodo? periodoSeleccionado;
  TurnoType? turnoSeleccionado;
  DateTime? fechaSeleccionada; 
  final List<DateTimeRange> semanasSeleccionadas;
  final List<DateTime> mesesSeleccionados = [];
  final List<int> aniosSeleccionados = [];

  FiltroFlexibleController()
    : semanasSeleccionadas = _generarSemanasPorDefecto(), 
    fechaSeleccionada = DateTime.now() {
    // debugPrint('Semanas inicializadas: $semanasSeleccionadas');
  }
  static List<DateTimeRange> _generarSemanasPorDefecto([int cantidad = 4]) {
    final semanas = <DateTimeRange>[];
    final now = DateTime.now();
    for (var i = 0; i < cantidad; i++) {
      final fecha = now.subtract(Duration(days: i * 7));
      final lunes = fecha.subtract(Duration(days: fecha.weekday - 1));
      final domingo = lunes.add(const Duration(days: 6));
      semanas.add(DateTimeRange(start: lunes, end: domingo));
    }
    return semanas;
  }

  List<DateTimeRange> get semanasSeleccionadasSorted {
    return List<DateTimeRange>.from(semanasSeleccionadas)..sort(
      (a, b) => a.start.compareTo(b.start),
    ); // Ascendente: más antigua primero
  }

  List<DateTime> get mesesSeleccionadosSorted {
    return List<DateTime>.from(mesesSeleccionados)..sort((a, b) {
      if (a.year != b.year) return a.year.compareTo(b.year);
      return a.month.compareTo(b.month);
    }); // Ascendente: más antiguo primero
  }

  List<int> get aniosSeleccionadosSorted {
    return List<int>.from(aniosSeleccionados)..sort(); // Ascendente
  }

  ///semanaSeleccionada la inicializamos con la fecha de hoy
  DateTimeRange semanaSeleccionada = DateTimeRange(
    start: DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
    end: DateTime.now()
        .subtract(Duration(days: DateTime.now().weekday - 1))
        .add(const Duration(days: 6)),
  );

  DateTimeRange get rangoSeleccionado {
    switch (periodoSeleccionado) {
      case FiltroPeriodo.semana:
        return semanaSeleccionada;

      case FiltroPeriodo.mes:
        if (mesesSeleccionados.isNotEmpty) {
          final ultimoMes = mesesSeleccionados.last;
          final inicio = DateTime(ultimoMes.year, ultimoMes.month, 1);
          final fin = DateTime(ultimoMes.year, ultimoMes.month + 1, 0);
          return DateTimeRange(start: inicio, end: fin);
        }
        break;

      case FiltroPeriodo.anio:
        if (aniosSeleccionados.isNotEmpty) {
          final ultimoAnio = aniosSeleccionados.last;
          final inicio = DateTime(ultimoAnio, 1, 1);
          final fin = DateTime(ultimoAnio, 12, 31);
          return DateTimeRange(start: inicio, end: fin);
        }
        break;

      default:
        break;
    }

    // fallback → si no hay nada seleccionado, usa la semana actual
    return semanaSeleccionada;
  }

  void seleccionarPeriodo(FiltroPeriodo periodo) {
    periodoSeleccionado = periodo;
    notifyListeners();
  }

  void seleccionarTurno(TurnoType? turno) {
    // <- nuevo método
    turnoSeleccionado = turno;
    notifyListeners();
  }

  void agregarSemana(DateTime fecha) {
    // Calcula lunes y domingo de la semana de la fecha seleccionada

    final lunes = fecha.subtract(Duration(days: fecha.weekday - 1));
    final domingo = lunes.add(const Duration(days: 6));
    final nuevoRango = DateTimeRange(start: lunes, end: domingo);

    // Evita duplicados
    if (!semanasSeleccionadas.any(
      (r) => r.start == nuevoRango.start && r.end == nuevoRango.end,
    )) {
      semanasSeleccionadas.add(nuevoRango);
      notifyListeners();
    }
  }

  ///este es solo para una semana una fecha no un array
  void seleccionarSemana(DateTime fecha) {
    // Calcula lunes y domingo de la semana de la fecha seleccionada
    final lunes = fecha.subtract(Duration(days: fecha.weekday - 1));
    final domingo = lunes.add(const Duration(days: 6));
    semanaSeleccionada = DateTimeRange(start: lunes, end: domingo);

    notifyListeners(); // Notifica a los widgets que dependen de este controlador
  }

  void eliminarSemana(DateTimeRange rango) {
    semanasSeleccionadas.removeWhere(
      (r) => r.start == rango.start && r.end == rango.end,
    );
    notifyListeners();
  }

  void agregarMes(DateTime fecha) {
    // Solo guarda año y mes
    final mes = DateTime(fecha.year, fecha.month);
    if (!mesesSeleccionados.any(
      (m) => m.year == mes.year && m.month == mes.month,
    )) {
      mesesSeleccionados.add(mes);
      notifyListeners();
    }
  }

  void eliminarMes(DateTime mes) {
    mesesSeleccionados.removeWhere(
      (m) => m.year == mes.year && m.month == mes.month,
    );
    notifyListeners();
  }

  void agregarAnio(int anio) {
    if (!aniosSeleccionados.contains(anio)) {
      aniosSeleccionados.add(anio);
      notifyListeners();
    }
  }

  void eliminarAnio(int anio) {
    aniosSeleccionados.remove(anio);
    notifyListeners();
  }
}
