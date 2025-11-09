import 'package:flutter/material.dart';

/// Banner que muestra si la fecha está cerrada (no laborable) para un tipo de servicio.
/// No hace queries internas: recibe un Future precalculado para evitar doble carga/flicker.
class NoLaborableBanner extends StatelessWidget {
  final DateTime fecha;
  final int tipoServicioId;
  final Future<List<Map<String, dynamic>>> registrosFuture;

  const NoLaborableBanner({
    super.key,
    required this.fecha,
    required this.tipoServicioId,
    required this.registrosFuture,
  });

  String _formatFecha(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final anio = d.year.toString();
    return '$dia/$mes/$anio';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: registrosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Mantener espacio para reducir salto visual (opcional)
          return const SizedBox(height: 0); // sin loader
        }

        final rows = snapshot.data ?? const [];
        final cerrada = rows.isNotEmpty;

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

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Container(
            key: ValueKey(cerrada),
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
          ),
        );
      },
    );
  }
}
