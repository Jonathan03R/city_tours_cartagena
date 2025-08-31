import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DebtSummaryByTurno extends StatelessWidget {
  const DebtSummaryByTurno({
    super.key,
    required this.stream,
    this.agenciaId,
    this.visible = true,
    this.title,
  });

  final Stream<List<ReservaConAgencia>> stream;
  final String? agenciaId;
  final bool visible;
  final String? title;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return StreamBuilder<List<ReservaConAgencia>>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final all = snap.data!;

        final filtered = all.where((ra) {
          final matchAg = agenciaId == null || ra.agencia.id == agenciaId;
          return matchAg && ra.reserva.estado != EstadoReserva.pagada;
        }).toList();

        double total = 0;
        double manana = 0;
        double tarde = 0;
        double privado = 0;

        for (final ra in filtered) {
          final deuda = ra.reserva.deuda;
          total += deuda;
          final t = ra.reserva.turno;
          if (t == TurnoType.manana) {
            manana += deuda;
          } else if (t == TurnoType.tarde) {
            tarde += deuda;
          } else {
            privado += deuda;
          }
        }

        final turnos = [
          _TurnoData(
            icon: Icons.wb_sunny,
            label: 'Mañana',
            value: manana,
            color: Colors.orange.shade600,
          ),
          _TurnoData(
            icon: Icons.wb_twilight,
            label: 'Tarde',
            value: tarde,
            color: Colors.deepOrange.shade600,
          ),
          _TurnoData(
            icon: Icons.lock,
            label: 'Privado',
            value: privado,
            color: Colors.purple.shade600,
          ),
        ].where((turno) => turno.value != 0).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Text(
                title ?? 'Resumen de Deuda',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF06142F),
                ),
              ),
            ),
            
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.red.shade700,
                    child: Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total: \$${Formatters.formatCurrency(total)}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            
            ...turnos.map((turno) => _HorizontalTurnoItem(turno: turno)),
          ],
        );
      },
    );
  }
}

class _TurnoData {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  _TurnoData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _HorizontalTurnoItem extends StatelessWidget {
  final _TurnoData turno;

  const _HorizontalTurnoItem({required this.turno});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: turno.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: turno.color,
            child: Icon(
              turno.icon,
              color: Colors.white,
              size: 18.r,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${turno.label}: \$${Formatters.formatCurrency(turno.value)}',
              style: TextStyle(
                color: turno.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
