import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:flutter/material.dart';

enum FiltroPeriodo { semana, mes, anio }

class FiltroFlexibleController extends ChangeNotifier {
  FiltroPeriodo? periodoSeleccionado;
  TurnoType? turnoSeleccionado;
  final List<DateTimeRange> semanasSeleccionadas = [];
  final List<DateTime> mesesSeleccionados = [];
  final List<int> aniosSeleccionados = [];

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
