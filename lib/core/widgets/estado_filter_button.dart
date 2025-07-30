import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:flutter/material.dart';

class EstadoFilterButtons extends StatelessWidget {
  final EstadoReserva? selectedEstado;
  final ValueChanged<EstadoReserva?> onEstadoChanged;

  const EstadoFilterButtons({
    super.key,
    required this.selectedEstado,
    required this.onEstadoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: Text('Pendientes'),
          selected: selectedEstado == EstadoReserva.pendiente,
          onSelected: (_) => onEstadoChanged(
            selectedEstado == EstadoReserva.pendiente 
              ? null 
              : EstadoReserva.pendiente,
          ),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text('Pagadas'),
          selected: selectedEstado == EstadoReserva.pagada,
          onSelected: (_) => onEstadoChanged(
            selectedEstado == EstadoReserva.pagada 
              ? null 
              : EstadoReserva.pagada,
          ),
        ),
      ],
    );
  }
}