import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Muestra deuda total y por turno (mañana, tarde, privado).
/// Si [agenciaId] no es null, filtra solo esa agencia.
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
            // cualquier otro turno cuenta como "privado"
            privado += deuda;
          }
        }

        Widget line(IconData icon, String label, double value, Color color) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                Icon(icon, size: 18.sp, color: color),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                    Text(
                      '\$${Formatters.formatCurrency(value)}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title ?? 'Deuda total: \$${Formatters.formatCurrency(total)}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            line(Icons.wb_sunny_outlined, 'Mañana', manana, Colors.orange),
            line(Icons.schedule, 'Tarde', tarde, Colors.deepOrange),
            line(Icons.lock_outline, 'Privado', privado, Colors.purple),
          ],
        );
      },
    );
  }
}
