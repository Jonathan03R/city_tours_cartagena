import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart'; // Importar ConfiguracionController
import 'package:citytourscartagena/core/controller/reservas_controller.dart'; // Importar ReservasController
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/screens/agencias_view.dart';
import 'package:citytourscartagena/screens/colaboradores_view.dart'; // Asegúrate de que esta vista exista
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:citytourscartagena/screens/reservas/turno_selector.dart'; // Importar el nuevo TurnoSelectorScreen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum TurnoType { manana, tarde }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 0=Reservas,1=Agencias,2=Colaboradores
  TurnoType? _turnoSeleccionado; // turno elegido
  StreamSubscription<List<AgenciaConReservas>>? _agenciasPreloadSubscription; 
  
  @override
  void initState() {
    super.initState();
    // Asegurarse de que el contexto esté disponible para Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGlobalImagePreloading(context);
    });
  }

  @override
  void dispose() {
    _agenciasPreloadSubscription?.cancel(); // Cancelar la suscripción al cerrar la app
    super.dispose();
  }

  void _startGlobalImagePreloading(BuildContext context) {
    final agenciasController = Provider.of<AgenciasController>(context, listen: false);
    _agenciasPreloadSubscription = agenciasController.agenciasConReservasStream.listen((agencias) {
      _precacheAgencyImages(agencias);
    }, onError: (error) {
      debugPrint('Error en el stream de agencias para precarga global: $error');
    });
  }

  void _precacheAgencyImages(List<AgenciaConReservas> agencias) {
    for (var agencia in agencias) {
      if (agencia.imagenUrl != null && agencia.imagenUrl!.isNotEmpty) {
        try {
          precacheImage(NetworkImage(agencia.imagenUrl!), context);
          // debugPrint('✅ Global precargando imagen de agencia: ${agencia.nombre}');
        } catch (e) {
          debugPrint('❌ Error global precargando imagen de ${agencia.nombre}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReservasController()),
        ChangeNotifierProvider(create: (_) => AgenciasController()),
        ChangeNotifierProvider(create: (_) => ConfiguracionController()),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Siempre existe el slot 0
            _currentIndex == 0
                ? (_turnoSeleccionado == null
                      ? TurnoSelectorWidget( // Usar la nueva pantalla de selección de turno
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
      ),
    );
  }
}
