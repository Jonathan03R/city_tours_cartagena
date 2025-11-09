import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoLaborableBanner extends StatelessWidget {
  final DateTime fecha;
  final int tipoServicioId;

  const NoLaborableBanner({
    super.key,
    required this.fecha,
    required this.tipoServicioId,
  });

  String _formatFecha(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final anio = d.year.toString();
    return '$dia/$mes/$anio';
  }

  @override
  Widget build(BuildContext context) {
    final operadores = context.read<OperadoresController>();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: operadores.obtenerNoLaborablesDelDia(
        fecha: fecha,
        tipoServicioId: tipoServicioId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final rows = snapshot.data ?? const [];

        // Si hay cualquier fila para esa fecha (independiente del servicio), está cerrada
        final cerrada = rows.isNotEmpty;

        // Buscar descripción específica para el servicio seleccionado, si existe
        String? descripcion;
        if (cerrada) {
          final matching = rows.where((r) => r['tipo_servicio_id'] == tipoServicioId).toList();
          if (matching.isNotEmpty) {
            final first = matching.first;
            descripcion = (first['calendarios_descripcion'] as String?)?.trim();
            descripcion ??= (first['descripcion'] as String?)?.trim();
            if (descripcion != null && descripcion.isEmpty) descripcion = null;
          }
        }

        final color = cerrada ? Colors.amber.shade700 : Colors.green.shade600;
        final bg = cerrada ? Colors.amber.shade50 : Colors.green.shade50;
        final icon = cerrada ? Icons.event_busy : Icons.event_available;
        final titulo = cerrada ? 'Agenda cerrada' : 'Agenda abierta';
        final subtitulo = 'Para ${_formatFecha(fecha)}';
        final detalle = cerrada
            ? (descripcion != null
                ? 'Motivo: $descripcion'
                : 'Tip: programa con otro servicio o cambia la fecha.')
            : 'Tip: puedes crear reservas con normalidad.';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detalle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
