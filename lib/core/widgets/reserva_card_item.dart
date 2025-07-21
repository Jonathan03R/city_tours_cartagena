import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../utils/formatters.dart';

class ReservaCardItem extends StatelessWidget {
  final ReservaConAgencia reserva;
  final VoidCallback onTap;

  const ReservaCardItem({
    Key? key,
    required this.reserva,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Text(
                reserva.nombreCliente,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.getEstadoBackgroundColor(reserva.estado),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                Formatters.getEstadoText(reserva.estado),
                style: TextStyle(
                  color: AppColors.getEstadoColor(reserva.estado),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Hotel
            if (reserva.hotel.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.hotel, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reserva.hotel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            // Fecha y PAX
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  Formatters.formatDate(reserva.fecha),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${reserva.pax} PAX',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Agencia
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    reserva.nombreAgencia,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            // Observación si existe
            if (reserva.observacion.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reserva.observacion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatCurrency(reserva.saldo),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: reserva.saldo > 0 ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${reserva.id.substring(0, 6)}...',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
