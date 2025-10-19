import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/operadores/operdadores.dart';
import 'package:citytourscartagena/core/services/reservas/reservas_service.supabase.dart';
import 'package:citytourscartagena/core/services/reservas/pagos_service.dart';
import 'package:citytourscartagena/core/widgets/sidebar/agencies_stats_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/debt_overview_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/drawer_header_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/logout_section.dart';
import 'package:citytourscartagena/screens/agencias/agencias_secciond.dart';
import 'package:citytourscartagena/screens/agencias_view.dart';
import 'package:citytourscartagena/screens/config_empresa_view.dart';
import 'package:citytourscartagena/screens/reportes/vista_reportes.dart';
import 'package:citytourscartagena/screens/usuarios/tabar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainOperadorScreen extends StatefulWidget {
  const MainOperadorScreen({super.key});

  @override
  State<MainOperadorScreen> createState() => _MainOperadorScreenState();
}

class _MainOperadorScreenState extends State<MainOperadorScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<AgenciaConReservas>>? _agenciasPreloadSubscription;
  int _currentIndex = 0;
  String _searchTerm = '';
  Future<List<AgenciaSupabase>>? _agenciasFuture;

  @override
  void initState() {
    super.initState();
    // _agenciasFuture = operadoresController.obtenerAgenciasDeOperador();
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

  /// Inicia la precarga de imágenes de agencias globalmente.
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

  /// Precachea las imágenes de las agencias que tengan una URL válida.
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
    // Páginas específicas para usuarios operadores
    //   final pages = <Widget>[
    //     const ReportesView(),
    //     // AgenciasView(searchTerm: _searchTerm),
    //     AgenciasSeccion(
    //   agenciasFuture: agenciasController.obtenerAgenciasDeOperador(),
    // ),
    //     const UsuariosScreen(),
    //   ];

    // Navegación específica para usuarios operadores
    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Reservas'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.business),
        label: 'Agencias',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.people),
        label: 'Colaboradores',
      ),
    ];

    // Asegurar que currentIndex esté dentro de los límites de navItems
    final int maxIndex = navItems.length - 1;
    final int safeMaxIndex = maxIndex >= 0 ? maxIndex : 0;
    final int displayIndex = _currentIndex.clamp(0, safeMaxIndex);

    return MultiProvider(
      providers: [
        // ChangeNotifierProvider(
        //   create: (_) => OperadoresController(
        //     Provider.of<AuthSupabaseController>(context, listen: false),
        //   ),
        // ),
        // usar el context del `create` para leer otros providers
        ChangeNotifierProvider(
          create: (context) => OperadoresController(
            context.read<AuthSupabaseController>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ControladorDeltaReservas(
            servicio: ReservasSupabaseService(Supabase.instance.client),
            pagosService: PagosService(Supabase.instance.client),
          ),
        ),

        ChangeNotifierProvider(create: (_) => ReservasController()),
        ChangeNotifierProvider(create: (_) => AgenciasController()),
        ChangeNotifierProvider(create: (_) => ConfiguracionController()),
        ChangeNotifierProvider(create: (_) => ReportesController()),
        ChangeNotifierProvider(create: (_) => FiltroFlexibleController()),
        ChangeNotifierProvider(create: (_) => GastosController()),
      ],
      builder: (context, _) {
        final operadoresController = Provider.of<OperadoresController>(
          context,
          listen: false,
        );

        _agenciasFuture ??= operadoresController.obtenerAgenciasDeOperador();

        final pages = <Widget>[
          const ReportesView(),
          // AgenciasView(searchTerm: _searchTerm),
          AgenciasSeccion(
            agenciasFuture: _agenciasFuture!,
            searchTerm: _searchTerm,
          ),
          const UsuariosScreen(),
        ];
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(
                Icons.menu,
                size: 28.sp,
                color: const Color(0xFF06142F),
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            backgroundColor: Colors.white,
            elevation: 2,
            iconTheme: const IconThemeData(color: Color(0xFF06142F)),
            title: _currentIndex == 1
                ? Container(
                    height: 40.h,
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
                          fontSize: 16.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                          size: 20.sp,
                        ),
                        suffixIcon: _searchTerm.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey.shade500,
                                  size: 20.sp,
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
                : Consumer<OperadoresController>(
                    builder: (context, controller, child) =>
                        FutureBuilder<Operadores?>(
                          future: controller.obtenerOperador(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return const Text('Error al cargar');
                            } else if (!snapshot.hasData ||
                                snapshot.data == null) {
                              return const Text('Operador no encontrado');
                            } else {
                              final operador = snapshot.data!;
                              return Text(
                                operador.nombre,
                                style: TextStyle(
                                  color: const Color(0xFF06142F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  letterSpacing: 1.0,
                                ),
                              );
                            }
                          },
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
              elevation: 16,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade50,
                      Colors.grey.shade100,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
                child: Consumer<AuthSupabaseController>(
                  builder: (_, auth, __) {
                    final perfil = auth.perfilUsuario;
                    final nombre = perfil?.persona != null
                        ? '${perfil!.persona!.nombre} ${perfil.persona!.apellido}'
                        : 'Invitado';

                    final email = perfil?.persona?.email ?? '';

                    return SafeArea(
                      bottom: true,
                      top: true,
                      child: Column(
                        children: [
                          // Header profesional del drawer
                          DrawerHeaderSection(usuario: nombre, email: email),

                          // Contenido scrolleable específico para operadores
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),

                                  // Sección de agencias activas
                                  AgenciesStatsSection(
                                    isVisible: _currentIndex == 1,
                                  ),
                                  DebtOverviewSection(
                                    isVisible: _currentIndex == 1,
                                  ),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),

                          // Botón de logout profesional
                          LogoutSection(onLogout: () => auth.logout()),

                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          body: IndexedStack(index: displayIndex, children: pages),
          bottomNavigationBar: navItems.length >= 2
              ? BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.white,
                  selectedItemColor: const Color(0xFF06142F),
                  unselectedItemColor: Colors.grey,
                  currentIndex: displayIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                      // Limpiar búsqueda al cambiar de pestaña
                      if (index != pages.indexWhere((p) => p is AgenciasView)) {
                        _searchController.clear();
                        _searchTerm = '';
                      }
                    });
                  },
                  items: navItems,
                )
              : null,
        );
      },
    );
  }
}
