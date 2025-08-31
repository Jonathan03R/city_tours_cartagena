import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:flutter/material.dart';

class FinanzasService {
  /// Calcula la ganancia total en un rango de fechas (opcionalmente filtrado por turno).
  /// Usa el getter `ganancia` de cada reserva para obtener su ingreso.
  double calcularGananciasEnRango(
    List<ReservaConAgencia> reservas,
    DateTime inicio,
    DateTime fin, {
    TurnoType? turno,
  }) {
    double totalGanancias = 0.0;

    for (var ra in reservas) {
      final fechaOrig = ra.reserva.fecha;
      final fechaNorm = DateTime(
        fechaOrig.year,
        fechaOrig.month,
        fechaOrig.day,
      );
      final dentroRango =
          !fechaNorm.isBefore(inicio) && !fechaNorm.isAfter(fin);
      final turnoCoincide = turno == null || ra.reserva.turno == turno;

      if (dentroRango && turnoCoincide) {
        final ganancia = ra.reserva.ganancia;
        totalGanancias += ganancia;
        
      }
    }

    return totalGanancias;
  }

  int calcularPasajerosEnRango(
    List<ReservaConAgencia> reservas,
    DateTime inicio,
    DateTime fin, {
    TurnoType? turno,
  }) {
    
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
      final incluida =
          !fechaReserva.isBefore(inicioDia) && !fechaReserva.isAfter(finDia);
      final turnoCoincide = turno == null || reserva.reserva.turno == turno;
     
      if (incluida && turnoCoincide) {
        totalPasajeros += reserva.reserva.pax;
        
      }
    }
    return totalPasajeros;
  }

  DateTimeRange obtenerRangoPorFecha(
    DateTime fecha,
    FiltroPeriodo tipoAgrupacion,
  ) {
    if (tipoAgrupacion == FiltroPeriodo.semana) {
      final inicioSemana = fecha.subtract(Duration(days: fecha.weekday - 1));
      final finSemana = inicioSemana.add(const Duration(days: 6));
      return DateTimeRange(start: inicioSemana, end: finSemana);
    } else if (tipoAgrupacion == FiltroPeriodo.mes) {
      final inicioMes = DateTime(fecha.year, fecha.month, 1);
      final finMes = DateTime(
        fecha.year,
        fecha.month + 1,
        1,
      ).subtract(const Duration(days: 1));
      return DateTimeRange(start: inicioMes, end: finMes);
    } else if (tipoAgrupacion == FiltroPeriodo.anio) {
      final inicioAnio = DateTime(fecha.year, 1, 1);
      final finAnio = DateTime(fecha.year, 12, 31);
      return DateTimeRange(start: inicioAnio, end: finAnio);
    } else {
      throw ArgumentError('Tipo de agrupación no soportado: $tipoAgrupacion');
    }
  }
}
