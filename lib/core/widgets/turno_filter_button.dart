import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:flutter/material.dart';

class TurnoFilterButtons extends StatelessWidget {
  final TurnoType? selectedTurno;
  final ValueChanged<TurnoType?> onTurnoChanged;

  const TurnoFilterButtons({
    super.key,
    required this.selectedTurno,
    required this.onTurnoChanged,
  });

  void _showTurnoSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...TurnoType.values.map((turno) => ListTile(
                  title: Text(turno.label),
                  selected: selectedTurno == turno,
                  onTap: () {
                    Navigator.pop(context);
                    onTurnoChanged(turno);
                  },
                )),
            const Divider(),
            ListTile(
              title: const Text('Quitar filtro'),
              onTap: () {
                Navigator.pop(context);
                onTurnoChanged(null);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.filter_list),
      label: Text(selectedTurno?.label ?? 'Filtrar Turno'),
      onPressed: () => _showTurnoSelector(context),
    );
  }
}
