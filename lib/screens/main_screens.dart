import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart'
    hide AgenciaConReservas;
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/screens/agencias_view.dart';
import 'package:citytourscartagena/screens/config_empresa_view.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:citytourscartagena/screens/reservas/turno_selector.dart';
import 'package:citytourscartagena/screens/usuarios/tabar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  // Controlador para el search de agencias
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGlobalImagePreloading(context);
    });
  }

  @override
  void dispose() {
    _agenciasPreloadSubscription?.cancel();
    _searchController.dispose();
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
    // Obtener el AuthController para verificar los roles
    final authController = context.watch<AuthController>();
    final canViewReservas = authController.hasPermission(
      Permission.ver_reservas,
    );
    final canViewAgencias = authController.hasPermission(
      Permission.ver_agencias,
    );
    final canViewUsuarios = authController.hasPermission(
      Permission.ver_pagina_usuarios,
    );

    final authRole = context.read<AuthController>();

    // Definir las páginas según permisos
    final pages = <Widget>[
      if (canViewReservas)
        (_currentIndex == 0
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
            : const SizedBox.shrink()),
      if (canViewAgencias) AgenciasView(searchTerm: _searchTerm),
      if (canViewUsuarios) const UsuariosScreen(),
    ];
    // Definir los ítems del bottom bar según permisos
    final navItems = <BottomNavigationBarItem>[
      if (canViewReservas)
        const BottomNavigationBarItem(
          icon: Icon(Icons.event),
          label: 'Reservas',
        ),
      if (canViewAgencias)
        const BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'Agencias',
        ),
      if (canViewUsuarios)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Colaboradores',
        ),
    ];
    // Asegurar que currentIndex esté dentro de los límites de navItems
    final int maxIndex = navItems.length - 1;
    // Si no hay ítems, maxIndex será -1; forzamos a 0 para no pasarle un upper < lower a clamp()
    final int safeMaxIndex = maxIndex >= 0 ? maxIndex : 0;
    final int displayIndex = _currentIndex.clamp(0, safeMaxIndex);
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
          iconTheme: const IconThemeData(color: Color(0xFF06142F)),
          title: _currentIndex == 1
              ? Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar agencia...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey.shade500,
                                size: 20,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchTerm = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                )
              : const Text(
                  'CITY TOURS CLIMATIZADO',
                  style: TextStyle(
                    color: Color(0xFF06142F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
          centerTitle: true,
          actions: [
            if (_currentIndex == 1)
              Consumer<AgenciasController>(
                builder: (_, agCtrl, __) {
                  return StreamBuilder<List<AgenciaConReservas>>(
                    stream: agCtrl.agenciasConReservasStream,
                    builder: (_, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06142F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            if (authRole.hasPermission(Permission.edit_configuracion))
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
          width: MediaQuery.of(context).size.width * 4 / 5,
          child: Drawer(
            child: Consumer<AuthController>(
              builder: (_, auth, __) {
                final usuario = auth.appUser?.usuario ?? 'Invitado';
                final email = auth.user?.email ?? '';
                return SafeArea(
                  bottom:
                      true, // protege de los botones de navegación inferiores
                  top:
                      true, // puedes cambiar a true si deseas también protección superior
                  child: Column(
                    children: [
                      Container(
                        color: const Color(0xFF06142F),
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
                      // Sección de Agencias (solo visible si NO es colaborador)
                      if (authRole.hasPermission(Permission.ver_deuda_agencia))
                        Consumer<AgenciasController>(
                          builder: (_, agCtrl, __) {
                            return StreamBuilder<List<AgenciaConReservas>>(
                              stream: agCtrl.agenciasConReservasStream,
                              builder: (_, snapshot) {
                                final count = snapshot.data?.length ?? 0;
                                return Visibility(
                                  visible:
                                      _currentIndex ==
                                      1, // Esto controla la visibilidad en el drawer
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
                      // Sección de Reservas (solo visible si NO es colaborador)
                      if (authRole.hasPermission(Permission.ver_deuda_agencia))
                        Consumer<ReservasController>(
                          builder: (_, resCtrl, __) {
                            return StreamBuilder<List<ReservaConAgencia>>(
                              stream: resCtrl.getAllReservasConAgenciaStream(),
                              builder: (_, snap) {
                                if (!snap.hasData)
                                  return const SizedBox.shrink();
                                final all = snap.data!;
                                final unpaid = all
                                    .where(
                                      (ra) =>
                                          ra.reserva.estado !=
                                          EstadoReserva.pagada,
                                    )
                                    .toList();
                                final totalDebt = unpaid.fold<double>(
                                  0.0,
                                  (sum, ra) => sum + ra.reserva.deuda,
                                );
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
                                final filteredAgencies = agencyDebtMap.entries
                                    .where((e) => e.value != 0)
                                    .map(
                                      (e) =>
                                          MapEntry(agencyById[e.key]!, e.value),
                                    )
                                    .toList();
                                return Visibility(
                                  visible:
                                      _currentIndex ==
                                      1, // Esto controla la visibilidad en el drawer
                                  child: ListTile(
                                    title: Text(
                                      'Deuda total: \$${Formatters.formatCurrency(totalDebt)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: filteredAgencies.isEmpty
                                        ? null
                                        : SizedBox(
                                            height: 400
                                                .h, // Altura fija más pequeña
                                            child: SingleChildScrollView(
                                              primary:
                                                  false, // Evita conflictos con PrimaryScrollController
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: filteredAgencies.map((
                                                  entry,
                                                ) {
                                                  final Agencia agencia =
                                                      entry.key;
                                                  final double deuda =
                                                      entry.value;
                                                  final badgeColor = deuda > 0
                                                      ? Colors.red
                                                      : Colors.green;
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 2,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: badgeColor.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 10,
                                                          backgroundImage:
                                                              agencia.imagenUrl !=
                                                                  null
                                                              ? NetworkImage(
                                                                  agencia
                                                                      .imagenUrl!,
                                                                )
                                                              : null,
                                                          backgroundColor:
                                                              badgeColor
                                                                  .shade700,
                                                          child:
                                                              agencia.imagenUrl ==
                                                                  null
                                                              ? Text(
                                                                  agencia
                                                                      .nombre[0]
                                                                      .toUpperCase(),
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                )
                                                              : null,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            '${agencia.nombre}: \$${Formatters.formatCurrency(deuda)}',
                                                            style: TextStyle(
                                                              color: badgeColor
                                                                  .shade700,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 10,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      const Spacer(),
                      const Spacer(),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Color(0xFFF41720),
                        ),
                        title: const Text(
                          'Cerrar sesión',
                          style: TextStyle(
                            color: Color(0xFF06142F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => auth.logout(),
                      ),
                      const Spacer(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        body: IndexedStack(index: displayIndex, children: pages),
        bottomNavigationBar: navItems.length >= 2
            ? BottomNavigationBar(
                currentIndex: displayIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                    // Limpiar búsqueda al cambiar de pestaña
                    if (canViewAgencias &&
                        index != pages.indexWhere((p) => p is AgenciasView)) {
                      _searchController.clear();
                      _searchTerm = '';
                    }
                  });
                },
                items: navItems,
              )
            : null,
      ),
    );
  }
}
