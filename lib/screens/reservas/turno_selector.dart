import 'package:flutter/material.dart';

import '../main_screens.dart';

class TurnoSelectorWidget extends StatelessWidget {
  final ValueChanged<TurnoType> onTurnoSelected;
  const TurnoSelectorWidget({super.key, required this.onTurnoSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => onTurnoSelected(TurnoType.manana),
            child: const Text('Turno Mañana'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => onTurnoSelected(TurnoType.tarde),
            child: const Text('Turno Tarde'),
          ),
        ],
      ),
    );
  }
}