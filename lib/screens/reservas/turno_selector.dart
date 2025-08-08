import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:flutter/material.dart';

class TurnoSelectorWidget extends StatelessWidget {
  final ValueChanged<TurnoType> onTurnoSelected;
  const TurnoSelectorWidget({super.key, required this.onTurnoSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: TurnoType.values.map((turno) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton(
              onPressed: () => onTurnoSelected(turno),
              child: Text(turno.label),
            ),
          );
        }).toList(),
      ),
    );
  }
}
