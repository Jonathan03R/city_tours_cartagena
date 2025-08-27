import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class FiltrosFlexiblesWidget extends StatefulWidget {
  final FiltroFlexibleController controller;
  const FiltrosFlexiblesWidget({super.key, required this.controller});

  @override
  State<FiltrosFlexiblesWidget> createState() => _FiltrosFlexiblesWidgetState();
}

class _FiltrosFlexiblesWidgetState extends State<FiltrosFlexiblesWidget> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selección de periodo
        if (c.periodoSeleccionado != null) ...[
          const Text('Turno:'),
          DropdownButton<TurnoType?>(
            value: c.turnoSeleccionado,
            isExpanded: true,
            items: [
              const DropdownMenuItem<TurnoType?>(
                value: null,
                child: Text('Todos'),
              ),
              ...TurnoType.values.map((tt) {
                return DropdownMenuItem<TurnoType?>(
                  value: tt,
                  child: Text(tt.label),
                );
              }).toList(),
            ],
            onChanged: (tt) => setState(() => c.seleccionarTurno(tt)),
          ),
          const SizedBox(height: 16),
        ],
        DropdownButton<FiltroPeriodo>(
          value: c.periodoSeleccionado,
          hint: const Text('Selecciona periodo'),
          items: FiltroPeriodo.values.map((p) {
            return DropdownMenuItem(
              value: p,
              child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
            );
          }).toList(),
          onChanged: (p) {
            setState(() => c.seleccionarPeriodo(p!));
          },
        ),
        const SizedBox(height: 16),
        // Botón para agregar una semana (selecciona una fecha y calcula lunes-domingo)
        if (c.periodoSeleccionado == FiltroPeriodo.semana)
          ElevatedButton(
            onPressed: () async {
              final now = DateTime.now();
              final fecha = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 5),
              );
              if (fecha != null) {
                c.agregarSemana(fecha);
                setState(() {});
              }
            },
            child: const Text('Agregar semana (elige una fecha)'),
          ),
        // Selección según periodo
        if (c.periodoSeleccionado == FiltroPeriodo.semana)
          Builder(
            builder: (_) {
              // Orden cronológico y numeración secuencial (Semana 1, 2, 3...)
              final semanasOrdenadas = List<DateTimeRange>.from(
                c.semanasSeleccionadas,
              )..sort((a, b) => a.start.compareTo(b.start));

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < semanasOrdenadas.length; i++)
                    Chip(
                      label: Text(
                        'Semana ${i + 1} (${semanasOrdenadas[i].start.day} ${_nombreMes(semanasOrdenadas[i].start.month)} - '
                        '${semanasOrdenadas[i].end.day} ${_nombreMes(semanasOrdenadas[i].end.month)} ${semanasOrdenadas[i].end.year})',
                      ),
                      onDeleted: () {
                        c.eliminarSemana(semanasOrdenadas[i]);
                        setState(() {});
                      },
                    ),
                ],
              );
            },
          ),
        if (c.periodoSeleccionado == FiltroPeriodo.mes)
          ElevatedButton(
            onPressed: () async {
              final now = DateTime.now();
              final selected = await showMonthPicker(
                context: context,
                initialDate: DateTime(now.year, now.month),
                firstDate: DateTime(now.year - 5, 1),
                lastDate: DateTime(now.year + 5, 12),
                // locale: Locale('es'), // opcional si quieres localización
              );
              if (selected != null) {
                // selected es un DateTime con el primer día del mes seleccionado
                c.agregarMes(DateTime(selected.year, selected.month, 1));
                setState(() {});
              }
            },
            child: const Text('Selecciona un mes'),
          ),
        if (c.periodoSeleccionado == FiltroPeriodo.anio)
          DropdownButton<int>(
            hint: const Text('Selecciona año'),
            value: null,
            items: List.generate(11, (i) => DateTime.now().year - 5 + i).map((
              anio,
            ) {
              return DropdownMenuItem(
                value: anio,
                child: Text(anio.toString()),
              );
            }).toList(),
            onChanged: (anio) {
              if (anio != null) {
                c.agregarAnio(anio);
                setState(() {});
              }
            },
          ),
        const SizedBox(height: 16),

        if (c.periodoSeleccionado == FiltroPeriodo.mes)
          Builder(
            builder: (_) {
              final mesesOrdenados = List<DateTime>.from(c.mesesSeleccionados)
                ..sort((a, b) {
                  if (a.year != b.year) return a.year.compareTo(b.year);
                  return a.month.compareTo(b.month);
                });

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: mesesOrdenados.map((m) {
                  final label = '${m.month}/${m.year}';
                  return Chip(
                    label: Text(label),
                    onDeleted: () {
                      c.eliminarMes(m);
                      setState(() {});
                    },
                  );
                }).toList(),
              );
            },
          ),
        if (c.periodoSeleccionado == FiltroPeriodo.anio)
          Wrap(
            children: c.aniosSeleccionados.map((a) {
              return Chip(
                label: Text(a.toString()),
                onDeleted: () {
                  c.eliminarAnio(a);
                  setState(() {});
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  String _nombreMes(int mes) {
    const meses = [
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
    return meses[mes - 1];
  }
}
