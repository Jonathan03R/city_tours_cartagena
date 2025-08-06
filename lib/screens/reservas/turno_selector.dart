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
        children: [
          ElevatedButton(
            onPressed: () {
              // debugPrint('filtro prueba🕘 Botón pulsado: Turno Mañana');
              onTurnoSelected(TurnoType.manana);
            },
            child: const Text('Turno Mañana'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // debugPrint('filtro prueba🌙 Botón pulsado: Turno Tarde');
              onTurnoSelected(TurnoType.tarde);
            },
            child: const Text('Turno Tarde'),
          ),
        ],
      ),
    );
  }
}
