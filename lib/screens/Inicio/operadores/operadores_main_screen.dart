import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/controller/filtros/servicios_controller.dart';
import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/operadores/operdadores.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:citytourscartagena/core/services/filtros/servicios/servicios_service.dart';
import 'package:citytourscartagena/core/services/reservas/colores_service.dart';
import 'package:citytourscartagena/core/services/reservas/pagos_service.dart';
import 'package:citytourscartagena/core/services/reservas/reservas_contactos.dart';
import 'package:citytourscartagena/core/services/reservas/reservas_service.supabase.dart';
import 'package:citytourscartagena/core/widgets/sidebar/agencies_stats_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/debt_overview_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/drawer_header_section.dart';
import 'package:citytourscartagena/core/widgets/sidebar/logout_section.dart';
import 'package:citytourscartagena/screens/Inicio/operadores/config_operadores.dart';
import 'package:citytourscartagena/screens/agencias/agencias_secciond.dart';
import 'package:citytourscartagena/screens/reportes/vista_reportes.dart';
import 'package:citytourscartagena/screens/usuarios/tabar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Este widget pertenece al universo operador.
/// Se monta dentro del árbol global (que ya provee Auth, sesión, etc.)
/// y crea sus providers locales persistentes para toda la navegación interna.
class MainOperadorScreen extends StatelessWidget {
  const MainOperadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha los providers globales del main (ya existen)
    final auth = context.read<AuthSupabaseController>();

    // Providers locales del universo operador (persisten durante todo el universo)
    return _OperadorScope(auth: auth, child: const _OperadorNavigator());
  }
}

/// Define los providers locales del universo operador.
/// Este widget se crea una sola vez, no se reconstruye.
class _OperadorScope extends StatelessWidget {
  final AuthSupabaseController auth;
  final Widget child;

  const _OperadorScope({required this.auth, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1️⃣ Primero el OperadoresController
        ChangeNotifierProvider(create: (_) => OperadoresController(auth)),

        // 2️⃣ Luego los que lo dependen
        ChangeNotifierProxyProvider<OperadoresController, ServiciosController>(
          create: (_) => ServiciosController(
            ServiciosService(),
            OperadoresController(auth), // valor inicial dummy
            AgenciasService(),
          ),
          update: (context, operadores, previous) => ServiciosController(
            ServiciosService(),
            operadores,
            AgenciasService(),
          ),
        ),

        ChangeNotifierProxyProvider<
          OperadoresController,
          ControladorDeltaReservas
        >(
          create: (_) => ControladorDeltaReservas(
            ReservasSupabaseService(Supabase.instance.client),
            PagosService(Supabase.instance.client),
            ColoresService(Supabase.instance.client),
            ReservasContactosService(Supabase.instance.client),
            OperadoresController(auth), // dummy inicial
          ),
          update: (context, operadores, previous) => ControladorDeltaReservas(
            ReservasSupabaseService(Supabase.instance.client),
            PagosService(Supabase.instance.client),
            ColoresService(Supabase.instance.client),
            ReservasContactosService(Supabase.instance.client),
            operadores,
          ),
        ),

        // 3️⃣ Los independientes
        ChangeNotifierProvider(create: (_) => ReservasController()),
        ChangeNotifierProvider(create: (_) => AgenciasController()),
        ChangeNotifierProvider(create: (_) => AgenciasControllerSupabase()),
        ChangeNotifierProvider(create: (_) => ConfiguracionController()),
        ChangeNotifierProvider(create: (_) => ReportesController()),
        ChangeNotifierProvider(create: (_) => FiltroFlexibleController()),
        ChangeNotifierProvider(create: (_) => GastosController()),
      ],
      child: child,
    );
  }
}

/// Navigator interno del universo operador.
/// Permite moverse entre pantallas sin perder el contexto de los providers.
class _OperadorNavigator extends StatefulWidget {
  const _OperadorNavigator();

  @override
  State<_OperadorNavigator> createState() => _OperadorNavigatorState();
}

class _OperadorNavigatorState extends State<_OperadorNavigator> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<List<AgenciaConReservas>>? _agenciasPreloadSubscription;

  int _currentIndex = 0;
  String _searchTerm = '';
  Future<List<AgenciaSupabase>>? _agenciasFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _startGlobalImagePreloading(context),
    );
  }

  @override
  void dispose() {
    _agenciasPreloadSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => _buildMainScaffold(context)),
    );
  }

  Widget _buildMainScaffold(BuildContext context) {
    final operadoresController = context.read<OperadoresController>();
    _agenciasFuture ??= operadoresController.obtenerAgenciasDeOperador();

    final pages = [
      const ReportesView(),
      AgenciasSeccion(
        agenciasFuture: _agenciasFuture!,
        searchTerm: _searchTerm,
      ),
      const UsuariosScreen(),
      ConfigOperadoresScreems(controller: operadoresController),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context),
      drawer: _buildDrawer(context),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final operadoresController = context.watch<OperadoresController>();
    final isSearchMode = _currentIndex == 1;

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.menu, size: 28.sp, color: const Color(0xFF06142F)),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      backgroundColor: Colors.white,
      elevation: 2,
      title: isSearchMode
          ? _buildSearchField()
          : FutureBuilder<Operadores?>(
              future: operadoresController.obtenerOperador(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else if (!snapshot.hasData) {
                  return const Text('Operador no encontrado');
                }
                final operador = snapshot.data!;
                return Text(
                  operador.nombre,
                  style: TextStyle(
                    color: const Color(0xFF06142F),
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                );
              },
            ),
      centerTitle: true,
      actions: [
        if (_currentIndex == 1) _buildAgenciasCount(context),
        IconButton(
          icon: const Icon(Icons.settings, color: Color(0xFF06142F)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConfigOperadoresScreems(
                  controller: context.read<OperadoresController>(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchTerm = value),
        decoration: InputDecoration(
          hintText: 'Buscar agencia...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16.sp),
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
                    setState(() => _searchTerm = '');
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
    );
  }

  Widget _buildAgenciasCount(BuildContext context) {
    return Consumer<AgenciasController>(
      builder: (_, agCtrl, __) => StreamBuilder<List<AgenciaConReservas>>(
        stream: agCtrl.agenciasConReservasStream,
        builder: (_, snapshot) {
          final count = snapshot.data?.length ?? 0;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF06142F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Consumer<AuthSupabaseController>(
        builder: (_, auth, __) {
          final perfil = auth.perfilUsuario;
          final nombre = perfil?.persona != null
              ? '${perfil!.persona!.nombre} ${perfil.persona!.apellido}'
              : 'Invitado';
          final email = perfil?.persona?.email ?? '';

          return SafeArea(
            child: Column(
              children: [
                DrawerHeaderSection(usuario: nombre, email: email),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        AgenciesStatsSection(isVisible: _currentIndex == 1),
                        DebtOverviewSection(isVisible: _currentIndex == 1),
                      ],
                    ),
                  ),
                ),
                LogoutSection(onLogout: () => auth.logout()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF06142F),
      unselectedItemColor: Colors.grey,
      currentIndex: _currentIndex,
      onTap: (i) => setState(() {
        _currentIndex = i;
        if (i != 1) _searchTerm = '';
      }),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Reservas'),
        BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Agencias'),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Colaboradores',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
      ],
    );
  }

  void _startGlobalImagePreloading(BuildContext context) {
    final agenciasController = Provider.of<AgenciasController>(
      context,
      listen: false,
    );
    _agenciasPreloadSubscription = agenciasController.agenciasConReservasStream
        .listen((agencias) => _precacheImages(agencias, context));
  }

  void _precacheImages(
    List<AgenciaConReservas> agencias,
    BuildContext context,
  ) {
    for (var agencia in agencias) {
      if (agencia.imagenUrl != null && agencia.imagenUrl!.isNotEmpty) {
        precacheImage(NetworkImage(agencia.imagenUrl!), context);
      }
    }
  }
}
