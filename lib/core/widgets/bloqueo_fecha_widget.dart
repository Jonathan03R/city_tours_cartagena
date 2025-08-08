import 'package:citytourscartagena/core/controller/bloqueo_fecha_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BloqueoFechaWidget extends StatefulWidget {
  final DateTime fecha;
  final String turnoActual; // 'manana', 'tarde', 'ambos'
  final bool puedeEditar;
  const BloqueoFechaWidget({
    super.key,
    required this.fecha,
    required this.turnoActual,
    this.puedeEditar = false,
  });

  @override
  State<BloqueoFechaWidget> createState() => _BloqueoFechaWidgetState();
}

class _BloqueoFechaWidgetState extends State<BloqueoFechaWidget> {
  String _turnoSeleccionado = 'ambos';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BloqueoFechaController>(
      create: (_) {
        final ctrl = BloqueoFechaController();
        ctrl.listenBloqueo(widget.fecha);
        return ctrl;
      },
      child: Consumer<BloqueoFechaController>(
        builder: (context, ctrl, _) {
          final bloqueo = ctrl.bloqueoActual;
          final cargando = ctrl.cargando;
          final error = ctrl.error;
          // Filtrado por turno: solo mostrar bloqueado si el turno bloqueado coincide o es 'ambos'
          bool estaCerrado = false;
          if (bloqueo?.cerrado == true) {
            if (bloqueo!.turno == 'ambos' || bloqueo.turno == widget.turnoActual) {
              estaCerrado = true;
            }
          }
          return Card(
            color: estaCerrado ? Colors.red.shade50 : Colors.green.shade50,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        estaCerrado ? Icons.lock : Icons.lock_open,
                        color: estaCerrado ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        estaCerrado
                            ? 'Cupos bloqueados para este turno'
                            : 'Cupos abiertos para este turno',
                        style: TextStyle(
                          color: estaCerrado ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (widget.puedeEditar && !cargando)
                        estaCerrado
                            ? TextButton.icon(
                                icon: const Icon(Icons.lock_open),
                                label: const Text('Desbloquear'),
                                onPressed: () async {
                                  await ctrl.desbloquear(widget.fecha);
                                },
                              )
                            : TextButton.icon(
                                icon: const Icon(Icons.lock),
                                label: const Text('Bloquear'),
                                onPressed: () async {
                                  final result = await _showBloqueoDialog(context);
                                  final motivo = result?['motivo']?.trim();
                                  final turno = result?['turno'];
                                  if (result != null && motivo != null && motivo.isNotEmpty && turno != null) {
                                    if (!mounted) return;
                                    await ctrl.bloquear(widget.fecha, turno, motivo);
                                  }
                                },
                              ),
                      if (cargando) const SizedBox(width: 16),
                      if (cargando) const CircularProgressIndicator(strokeWidth: 2),
                    ],
                  ),
                  if (estaCerrado && bloqueo?.motivo != null && bloqueo!.motivo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Motivo: ${bloqueo.motivo}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  if (estaCerrado)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Turno cerrado: ${bloqueo?.turno ?? 'ambos'}',
                        style: const TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, String>?> _showBloqueoDialog(BuildContext context) async {
    final motivoController = TextEditingController(text: 'Cupos cerrados por administración');
    String turno = _turnoSeleccionado;
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Bloquear cupos para la fecha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: motivoController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: turno,
                items: const [
                  DropdownMenuItem(value: 'ambos', child: Text('Ambos turnos')),
                  DropdownMenuItem(value: 'manana', child: Text('Solo mañana')),
                  DropdownMenuItem(value: 'tarde', child: Text('Solo tarde')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => turno = val);
                },
                decoration: const InputDecoration(labelText: 'Turno a bloquear'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop({
                'motivo': motivoController.text,
                'turno': turno,
              }),
              child: const Text('Bloquear'),
            ),
          ],
        ),
      ),
    );
  }
}
