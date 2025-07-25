import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:flutter/material.dart';

class TurnoFilterButtons extends StatelessWidget {
  final TurnoType? selectedTurno;
  final ValueChanged<TurnoType?> onTurnoChanged;

  const TurnoFilterButtons({
    super.key,
    required this.selectedTurno,
    required this.onTurnoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: Text('Mañana'),
          selected: selectedTurno == TurnoType.manana,
          onSelected: (_) => onTurnoChanged(
              selectedTurno == TurnoType.manana ? null : TurnoType.manana),
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: Text('Tarde'),
          selected: selectedTurno == TurnoType.tarde,
          onSelected: (_) => onTurnoChanged(
              selectedTurno == TurnoType.tarde ? null : TurnoType.tarde),
        ),
      ],
    );
  }
}
