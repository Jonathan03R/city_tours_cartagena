import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/widgets/debt_summary_by_turno.dart';
import 'package:citytourscartagena/core/widgets/sidebar/agencies_stats_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/debt_overview_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/drawer_header_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/logout_section.dart';
import 'package:citytourscartagena/screens/agencias_view.dart';
import 'package:citytourscartagena/screens/reportes/vista_reportes.dart';
import 'package:citytourscartagena/screens/servicios/servicio_view.dart';
import 'package:citytourscartagena/screens/usuarios/tabar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0; // 0=Reservas,1=Agencias,2=Colaboradores
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

  /// Inicia la precarga de imágenes de agencias globalmente.
  /// Escucha el stream de agencias con reservas y precarga las imágenes
  /// de cada agencia que tenga una URL de imagen válida.
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
  /// Utiliza [precacheImage] para cargar las imágenes en caché.
  /// Si ocurre un error al precargar una imagen, se captura y se imprime en el log.

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
  // final agenciasController = context.watch<AgenciasController>();
    final appUser = authController.appUser;

    /// Verificar permisos del usuario
    final canViewReservas = authController.hasPermission(
      Permission.ver_reservas,
    );
    final canViewAgencias = authController.hasPermission(
      Permission.ver_agencias,
    );
    final canViewUsuarios = authController.hasPermission(
      Permission.ver_pagina_usuarios,
    );
    // final canViewReportes = authController.hasPermission(
    //   Permission.ver_pagina_reportes,
    // );

    /// Si no tiene permisos, redirigir a la pantalla de configuración
    final authRole = context.read<AuthController>();

    /// Verificar si el usuario es de una agencia
    /// Si es así, obtener la agencia asociada
    /// y mostrar las reservas de esa agencia
    final isAgencyUser =
            appUser?.agenciaId != null &&
            (appUser?.roles.contains('agencia') ?? false);
    // Si es usuario de agencia, buscar la agencia asociada
    // Definir las páginas según permisos
    // Si es usuario de agencia, mostrar reservas de esa agencia
    // Si no, mostrar selector de turno o reservas según el turno seleccionado
    // Si no tiene permisos, mostrar un SizedBox vacío
    // Si no hay permisos para ver reservas, agencias o usuarios, mostrar un SizedBox vacío
    final pages = <Widget>[
      if (isAgencyUser) ...[
        const ServiciosView(), // Pestaña de servicios
        const UsuariosScreen(), // Pestaña de colaboradores
      ] else ...[
        if (canViewReservas)
          const ReportesView(),
        if (canViewAgencias) AgenciasView(searchTerm: _searchTerm),
        if (canViewUsuarios) const UsuariosScreen(),
        // if (canViewReportes) const ReportesView(), // Nueva página de estadísticas
      ],
    ];
    // Definir los ítems del bottom bar según permisos

    final navItems = <BottomNavigationBarItem>[
      if (isAgencyUser) ...[
        const BottomNavigationBarItem(
          icon: Icon(Icons.room_service),
          label: 'Servicios',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Colaboradores',
        ),
      ] else ...[
        if (canViewReservas)
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
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
        // if (canViewReportes)
        //   const BottomNavigationBarItem(
        //     icon: Icon(Icons.bar_chart),
        //     label: 'Estadisticas',
        //   ),
      ],
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
        // Provider para reportes
        ChangeNotifierProvider(create: (_) => ReportesController()),
        ChangeNotifierProvider(create: (_) => FiltroFlexibleController()),
        ChangeNotifierProvider(create: (_) => GastosController()),
      ],
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.menu,
              size: 28.sp, // <-- aquí controlas el tamaño
              color: const Color(0xFF06142F),
            ),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          backgroundColor: Colors.white,
          elevation: 2,
          iconTheme: const IconThemeData(color: Color(0xFF06142F)),
          title: !isAgencyUser && _currentIndex == 1
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
              : Text(
                  'CITY TOURS CLIMATIZADO',
                  style: TextStyle(
                    color: Color(0xFF06142F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
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
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (_) => const ConfigEmpresaView(),
                  //   ),
                  // );
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
      child: Consumer<AuthController>(
        builder: (_, auth, __) {
          final usuario = auth.appUser?.usuario ?? 'Invitado';
          final email = auth.user?.email ?? '';
          final authRole = context.watch<AuthController>();
          
          return SafeArea(
            bottom: true,
            top: true,
            child: Column(
              children: [
                // Header profesional del drawer
                DrawerHeaderSection(
                  usuario: usuario,
                  email: email,
                ),
                
                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        
                        // Sección de agencias activas
                        if (authRole.hasPermission(Permission.ver_deuda_agencia))
                          AgenciesStatsSection(
                            isVisible: _currentIndex == 1,
                          ),
                        
                        // Sección de resumen de deudas
                        if (authRole.hasPermission(Permission.ver_deuda_agencia))
                          DebtOverviewSection(
                            isVisible: _currentIndex == 1,
                          ),
                        
                        // Resumen por turno para usuarios de agencia
                        Consumer2<ReservasController, AuthController>(
                          builder: (_, resCtrl, auth, __) {
                            final isAgencyUser = auth.appUser?.agenciaId != null &&
                                (auth.appUser?.roles.contains('agencia') ?? false);

                            if (!isAgencyUser) {
                              return const SizedBox.shrink();
                            }

                            final String agenciaId = auth.appUser!.agenciaId!;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOut,
                              child: AnimatedOpacity(
                                opacity: _currentIndex == 0 ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 400),
                                child: Visibility(
                                  visible: _currentIndex == 0,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                                    child: DebtSummaryByTurno(
                                      stream: resCtrl.getAllReservasConAgenciaStream(),
                                      agenciaId: agenciaId,
                                      visible: true,
                                      title: 'Tu deuda por turno',
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                
                // Botón de logout profesional
                LogoutSection(
                  onLogout: () => auth.logout(),
                ),
                
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