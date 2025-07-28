import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart'; // Importar ConfiguracionController
import 'package:citytourscartagena/core/controller/reservas_controller.dart'; // Importar ReservasController
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart'
    hide AgenciaConReservas;
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/screens/agencias_view.dart';
import 'package:citytourscartagena/screens/colaboradores_view.dart'; // Asegúrate de que esta vista exista
import 'package:citytourscartagena/screens/config_empresa_view.dart';  // Nueva pantalla de configuración
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    _agenciasPreloadSubscription
        ?.cancel(); // Cancelar la suscripción al cerrar la app
    super.dispose();
  }

  void _startGlobalImagePreloading(BuildContext context) {
    final agenciasController = Provider.of<AgenciasController>(
      context,
      listen: false,
    );
    _agenciasPreloadSubscription = agenciasController.agenciasConReservasStream
        .listen(
          (agencias) {
            _precacheAgencyImages(agencias);
          },
          onError: (error) {
            debugPrint(
              'Error en el stream de agencias para precarga global: $error',
            );
          },
        );
  }

  void _precacheAgencyImages(List<AgenciaConReservas> agencias) {
    for (var agencia in agencias) {
      if (agencia.imagenUrl != null && agencia.imagenUrl!.isNotEmpty) {
        try {
          precacheImage(NetworkImage(agencia.imagenUrl!), context);
          // debugPrint('✅ Global precargando imagen de agencia: ${agencia.nombre}');
        } catch (e) {
          debugPrint(
            '❌ Error global precargando imagen de ${agencia.nombre}: $e',
          );
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
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          iconTheme: const IconThemeData(
            color: Color(0xFF06142F),
          ), // azul oscuro
          title: const Text(
            'CITY TOURS CLIMATIZADO',
            style: TextStyle(
              color: Color(0xFF06142F),
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.0,
            ),
          ),
          centerTitle: true,
          actions: [  // Icono de configuración
            IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFF06142F)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConfigEmpresaView(),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: SizedBox(
          width: MediaQuery.of(context).size.width * 4/5,
          child: Drawer(
            child: Consumer<AuthController>(
            builder: (_, auth, __) {
              final usuario = auth.appUser?.usuario ?? 'Invitado';
              final email = auth.user?.email ?? '';
              return Column(
                children: [
                  Container(
                    color: const Color(0xFF06142F), // color de fondo completo
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: const AssetImage(
                            'assets/images/logo.png',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          usuario,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<AgenciasController>(
                    builder: (_, agCtrl, __) {
                      return StreamBuilder<List<AgenciaConReservas>>(
                        stream: agCtrl.agenciasConReservasStream,
                        builder: (_, snapshot) {
                          final count = snapshot.data?.length ?? 0;
                          return Visibility(
                            visible: _currentIndex == 1,
                            child: ListTile(
                              leading: const Icon(Icons.business),
                              title: Text(
                                '$count agencia${count != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Consumer<ReservasController>(
                    builder: (_, resCtrl, __) {
                      return StreamBuilder<List<ReservaConAgencia>>(
                        stream: resCtrl
                            .getAllReservasConAgenciaStream(), // <-- STREAM de todas
                        builder: (_, snap) {
                          if (!snap.hasData) return const SizedBox.shrink();
                          final all = snap.data!;
                          // sólo las pendientes
                          final unpaid = all
                              .where(
                                (ra) =>
                                    ra.reserva.estado != EstadoReserva.pagada,
                              )
                              .toList();
                          // suma total de deuda
                          final totalDebt = unpaid.fold<double>(
                            0.0,
                            (sum, ra) => sum + ra.reserva.deuda,
                          );
                          // Agrupar deuda por agencia
                          final Map<String, double> agencyDebtMap = {};
                          final Map<String, Agencia> agencyById = {};
                          for (var ra in unpaid) {
                            agencyById[ra.agencia.id] = ra.agencia;
                            agencyDebtMap.update(
                              ra.agencia.id,
                              (prev) => prev + ra.reserva.deuda,
                              ifAbsent: () => ra.reserva.deuda,
                            );
                          }
                          // Filtrar agencias con deuda y crear lista de tuplas
                          final filteredAgencies = agencyDebtMap.entries
                              .where((e) => e.value != 0)
                              .map((e) => MapEntry(agencyById[e.key]!, e.value))
                              .toList();

                          return Visibility(
                            visible: _currentIndex == 1,
                            child: ListTile(
                              // leading: const Icon(
                              //   Icons.account_balance_wallet,
                              //   color: Colors.red,
                              // ),
                              title: Text(
                                'Deuda total: \$${Formatters.formatCurrency(totalDebt)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: filteredAgencies.isEmpty
                                  ? null
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: filteredAgencies.map((entry) {
                                        final Agencia agencia = entry.key;
                                        final double deuda = entry.value;
                                        final badgeColor = deuda > 0 ? Colors.red : Colors.green;
                                        return Container(
                                          margin: const EdgeInsets.symmetric(vertical: 2),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeColor.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 10,
                                                backgroundImage: agencia.imagenUrl != null
                                                    ? NetworkImage(agencia.imagenUrl!)
                                                    : null,
                                                backgroundColor: badgeColor.shade700,
                                                child: agencia.imagenUrl == null
                                                    ? Text(
                                                        agencia.nombre[0].toUpperCase(),
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${agencia.nombre}: \$${Formatters.formatCurrency(deuda)}',
                                                style: TextStyle(
                                                  color: badgeColor.shade700,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Spacer(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Color(0xFFF41720)),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Color(0xFF06142F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => auth.logout(),
                  ),
                ],
              );
            },
          ),
        ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Siempre existe el slot 0
            _currentIndex == 0
                ? (_turnoSeleccionado == null
                      ? TurnoSelectorWidget(
                          // Usar la nueva pantalla de selección de turno
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
