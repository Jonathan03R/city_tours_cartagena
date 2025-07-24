import 'package:citytourscartagena/screens/agencias_view.dart';
import 'package:citytourscartagena/screens/colaboradores_view.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:citytourscartagena/screens/reservas/turno_selector.dart';
import 'package:flutter/material.dart';

enum TurnoType { manana, tarde }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // 0=Reservas,1=Agencias,2=Colaboradores
  TurnoType? _turnoSeleccionado; // turno elegido

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Siempre existe el slot 0
          _currentIndex == 0
              ? (_turnoSeleccionado == null
                    ? TurnoSelectorWidget(
                        onTurnoSelected: (turno) => setState(() {
                          _turnoSeleccionado = turno;
                        }),
                      )
                    : ReservasView(
                        turno: _turnoSeleccionado,
                        onBack: () => setState(() {
                          _turnoSeleccionado = null;
                        }),
                      ))
              : const SizedBox.shrink(),
          // Slot 1
          const AgenciasView(),
          // Slot 2
          const ColaboradoresView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Al pulsar “Reservas” (0) no abrimos dialog, simplemente actualizamos
          setState(() {
            _currentIndex = index;
            // si retrocedes a Reservas y ya había turno, se muestra ReservasView
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Reservas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Agencias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Colaboradores',
          ),
        ],
      ),
    );
  }
}
