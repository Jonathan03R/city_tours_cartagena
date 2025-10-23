import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/controller/metas_controller.dart';
import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/screens/agencias/widget/reserva_refactorizada.dart';
import 'package:citytourscartagena/screens/metas/metas_screen.dart';
import 'package:citytourscartagena/screens/reportes/gastos_screen.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/filtros_flexibles.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/grafico_comparacion.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/grafico_semanal.dart';
import 'package:citytourscartagena/screens/reservas/turno_selector.dart'
    show TurnoSelectorWidget;
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ReportesView extends StatefulWidget {
  const ReportesView({super.key});

  @override
  State<ReportesView> createState() => _ReportesViewState();
}

class _ReportesViewState extends State<ReportesView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late FiltroFlexibleController _filtrosController;
  late FiltroFlexibleController _weeklyFiltrosController;
  bool _gastosLoaded = false;
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
    _filtrosController = FiltroFlexibleController();
    _weeklyFiltrosController = FiltroFlexibleController();

    // Selección predeterminada: filtro semana y las últimas 4 semanas (actual + 3 anteriores)
    _filtrosController.seleccionarPeriodo(FiltroPeriodo.semana);
    _filtrosController.seleccionarTurno(TurnoType.tarde);
    // final now = DateTime.now();
    // for (int i = 0; i < 4; i++) {
    //   _filtrosController.agregarSemana(now.subtract(Duration(days: 7 * i)));
    // }
    _weeklyFiltrosController.seleccionarPeriodo(FiltroPeriodo.semana);
    _weeklyFiltrosController.seleccionarSemana(DateTime.now());
    _weeklyFiltrosController.seleccionarTurno(TurnoType.tarde);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gastosController = Provider.of<GastosController>(
        context,
        listen: false,
      );
      gastosController.cargarTodosLosGastos();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _filtrosController.dispose();
    _weeklyFiltrosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authRole = context.watch<AuthController>();

    return Consumer<ReportesController>(
      builder: (context, controller, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.backgroundGray, AppColors.backgroundWhite],
              stops: [0.0, 1.0],
            ),
          ),
          child: StreamBuilder<List<ReservaConAgencia>>(
            stream: controller.reservasStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final reservas = snapshot.data!;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.all(20.w),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // if (authRole.hasPermission(Permission.ver_cards_navegacion))
                            _buildNavigationCards(),
                            TurnoSelectorWidget(
                              onTurnoSelected: (turno) {
                                // usar addPostFrameCallback para obtener un contexto seguro
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ReservaVista(),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24.h),
                            if (authRole.hasPermission(
                                  Permission.ver_graficos_pasajeros,
                                ) ||
                                authRole.hasPermission(
                                  Permission.ver_graficos_gastos,
                                )) ...[
                              _graficosComparativos(controller, reservas),
                              SizedBox(height: 24.h),
                            ],
                            if (authRole.hasPermission(
                                  Permission.ver_graficos_pasajeros_semanal,
                                ) ||
                                authRole.hasPermission(
                                  Permission.ver_graficos_gastos_semanal,
                                )) ...[
                              _buildWeeklyCharts(controller, reservas),
                              SizedBox(height: 100.h), // Bottom padding
                            ],
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _titulos({
    required String title,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNightBlue.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _graficosComparativos(
    ReportesController reportesController,
    List<ReservaConAgencia> reservas,
  ) {
    final authRole = context.watch<AuthController>();
    return ChangeNotifierProvider.value(
      value: _filtrosController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (authRole.hasPermission(Permission.ver_graficos_pasajeros) ||
          //     authRole.hasPermission(Permission.ver_graficos_gastos))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulos(
                title: 'Análisis Comparativo',
                icon: Icons.analytics_rounded,
                gradient: LinearGradient(
                  colors: [AppColors.accentBlue, AppColors.lightBlue],
                ),
              ),
              SizedBox(height: 16.h),
              ModernFiltrosFlexiblesWidget(controller: _filtrosController),
              SizedBox(height: 20.h),
            ],
          ),
          Consumer<GastosController>(
            builder: (context, gastosController, child) {
              // Cargar gastos una vez si no están cargados
              if (!_gastosLoaded && gastosController.gastos.isEmpty) {
                _gastosLoaded = true;
                gastosController.cargarTodosLosGastos(); // Carga async
              }
              return SizedBox.shrink(); // No renderiza nada, solo para cargar
            },
          ),

          Consumer<FiltroFlexibleController>(
            builder: (context, filtrosController, child) {
              final gastosController = context.watch<GastosController>();
              // ... existing logic ...
              final turno = filtrosController.turnoSeleccionado;
              final periodo = filtrosController.periodoSeleccionado;

              final semanas = filtrosController.semanasSeleccionadasSorted;
              final meses = filtrosController.mesesSeleccionadosSorted;
              final anios = filtrosController.aniosSeleccionadosSorted;

              List<ChartCategoryData> datosPasajeros = [];
              List<ChartCategoryData> datosGanancias = [];

              if (periodo == FiltroPeriodo.semana && semanas.isNotEmpty) {
                datosPasajeros = reportesController.agruparPasajerosPorRangos(
                  reservas,
                  semanas,
                  turno: turno,
                );
                datosGanancias = reportesController.agruparGananciasPorRangos(
                  reservas,
                  semanas,
                  turno: turno,
                  gastos: gastosController.gastos,
                );
              } else if (periodo == FiltroPeriodo.mes && meses.isNotEmpty) {
                final rangos = meses.map((m) {
                  final inicio = DateTime(m.year, m.month, 1);
                  final fin = DateTime(m.year, m.month + 1, 0);
                  return DateTimeRange(start: inicio, end: fin);
                }).toList();

                datosPasajeros = reportesController.agruparPasajerosPorRangos(
                  reservas,
                  rangos,
                  turno: turno,
                );
                datosGanancias = reportesController.agruparGananciasPorRangos(
                  reservas,
                  rangos,
                  turno: turno,
                  gastos: gastosController.gastos,
                );
              } else if (periodo == FiltroPeriodo.anio && anios.isNotEmpty) {
                final rangos = anios.map((y) {
                  final inicio = DateTime(y, 1, 1);
                  final fin = DateTime(y, 12, 31);
                  return DateTimeRange(start: inicio, end: fin);
                }).toList();

                datosPasajeros = reportesController.agruparPasajerosPorRangos(
                  reservas,
                  rangos,
                  turno: turno,
                );
                datosGanancias = reportesController.agruparGananciasPorRangos(
                  reservas,
                  rangos,
                  turno: turno,
                  gastos: gastosController.gastos,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (authRole.hasPermission(
                    Permission.ver_graficos_pasajeros,
                  )) ...[
                    ModernGraficoComparacion(
                      datos: datosPasajeros,
                      titulo: "Pasajeros",
                    ),
                    SizedBox(height: 32.h),
                  ],
                  if (authRole.hasPermission(Permission.ver_graficos_gastos))
                    ModernGraficoComparacionLinea(
                      datos: datosGanancias,
                      titulo: "Ganancias",
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCharts(
    ReportesController reportesController,
    List<ReservaConAgencia> reservas,
  ) {
    final authRole = context.watch<AuthController>();
    return ChangeNotifierProvider.value(
      value: _weeklyFiltrosController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer<FiltroFlexibleController>(
            builder: (context, filtrosController, child) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNightBlue.withOpacity(0.08),
                      blurRadius: 20.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.success, Color(0xFF34D399)],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.calendar_view_week_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Análisis Semanal',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // ComboBox de Turno SOLO para los gráficos semanales
                        Container(
                          width: 120.w,
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: AppColors.textLight.withOpacity(0.3),
                              width: 1.w,
                            ),
                          ),
                          child: DropdownButton<TurnoType?>(
                            value: _weeklyFiltrosController.turnoSeleccionado,
                            isExpanded: true,
                            underline: SizedBox(),
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary,
                            ),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            items: [
                              DropdownMenuItem<TurnoType?>(
                                value: null,
                                child: Text('Todos'),
                              ),
                              ...TurnoType.values.map((tt) {
                                return DropdownMenuItem<TurnoType?>(
                                  value: tt,
                                  child: Text(tt.label),
                                );
                              }).toList(),
                            ],
                            onChanged: (tt) {
                              filtrosController.seleccionarTurno(
                                tt,
                              ); // <--- SIN setState
                            },
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accentBlue,
                                AppColors.lightBlue,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentBlue.withOpacity(0.3),
                                blurRadius: 8.r,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10.r),
                              onTap: () async {
                                final now = DateTime.now();
                                final fechaSeleccionada = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: DateTime(now.year - 5),
                                  lastDate: DateTime(now.year + 5),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: AppColors.primaryNightBlue,
                                          onPrimary: Colors.white,
                                          surface: AppColors.backgroundWhite,
                                          onSurface: AppColors.textPrimary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (fechaSeleccionada != null) {
                                  _weeklyFiltrosController.seleccionarSemana(
                                    fechaSeleccionada,
                                  );
                                }
                              },
                              child:
                                  authRole.hasPermission(
                                    Permission.ver_selector_fecha,
                                  )
                                  ? Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 8.h,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.date_range_rounded,
                                            color: Colors.white,
                                            size: 16.sp,
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Seleccionar',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 20.h),
          Consumer<FiltroFlexibleController>(
            builder: (context, filtrosController, child) {
              final semanaSeleccionada = filtrosController.semanaSeleccionada;
              final turnoSelectoTurno = filtrosController.turnoSeleccionado;

              final pasajerosData = reportesController
                  .calcularPasajerosPorSemana(
                    reservas: reservas,
                    fecha: semanaSeleccionada.start,
                    turno: turnoSelectoTurno,
                  );

              final gananciasData = reportesController
                  .calcularGananciasPorSemana(
                    reservas: reservas,
                    fecha: semanaSeleccionada.start,
                    turno: turnoSelectoTurno,
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 5.h),

                  _titulos(
                    title:
                        'Filtros: ${filtrosController.turnoSeleccionado?.label ?? 'Todos'}',
                    icon: Icons.analytics_rounded,
                    gradient: LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.lightBlue],
                    ),
                  ),
                  // Text(
                  //   'Turno: ${filtrosController.turnoSeleccionado?.label ?? 'Todos'}',
                  //   style: TextStyle(
                  //     color: AppColors.textPrimary,
                  //     fontSize: 16.sp,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                  if (authRole.hasPermission(
                    Permission.ver_graficos_pasajeros_semanal,
                  )) ...[
                    SizedBox(height: 20.h),
                    ModernGraficoSemanal(
                      data: pasajerosData,
                      titulo:
                          'Pasajeros del ${semanaSeleccionada.start.day}/${semanaSeleccionada.start.month} '
                          'al ${semanaSeleccionada.end.day}/${semanaSeleccionada.end.month}',
                    ),
                  ],
                  if (authRole.hasPermission(
                    Permission.ver_graficos_gastos_semanal,
                  )) ...[
                    SizedBox(height: 32.h),
                    ModernGraficoGananciasSemanal(
                      data: gananciasData,
                      titulo:
                          'Ganancias del ${semanaSeleccionada.start.day}/${semanaSeleccionada.start.month} '
                          'al ${semanaSeleccionada.end.day}/${semanaSeleccionada.end.month}',
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.r),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNightBlue.withOpacity(0.1),
                  blurRadius: 32.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 48.w,
                  height: 48.h,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentBlue,
                    ),
                    strokeWidth: 4.w,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Cargando datos financieros...',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Esto puede tomar unos segundos',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40.r),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNightBlue.withOpacity(0.08),
                  blurRadius: 32.r,
                  offset: Offset(0, 8.h),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.textSecondary.withOpacity(0.1),
                        AppColors.textSecondary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 64.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 32.h),
                Text(
                  'No hay datos disponibles',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Los reportes aparecerán cuando tengas reservas registradas en el sistema',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCards() {
    final authRole = context.watch<AuthController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (authRole.hasPermission(Permission.ver_cards_metas))
          Flexible(
            fit: FlexFit.loose,
            child: _buildNavigationCard(
              title: 'Metas Actuales',
              subtitle: 'Progreso de esta semana',
              icon: Icons.flag_rounded,
              gradient: LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => MetasController(),
                      child: const MetasScreen(),
                    ),
                  ),
                );
              },
              child: ChangeNotifierProvider(
                create: (_) => MetasController(),
                child: _buildMetaProgress(),
              ),
              authRole: authRole,
            ),
          ),
        if (authRole.hasPermission(Permission.ver_cards_metas) &&
            authRole.hasPermission(Permission.ver_cards_gastos))
          SizedBox(width: 16.w),
        if (authRole.hasPermission(Permission.ver_cards_gastos))
          Flexible(
            fit: FlexFit.loose,
            child: _buildNavigationCard(
              title: 'Gastos Actuales',
              subtitle: 'En pesos colombianos',
              icon: Icons.receipt_long_rounded,
              gradient: LinearGradient(
                colors: [AppColors.error, Color(0xFFF87171)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider(
                      create: (_) => GastosController(),
                      child: const ModernGastosScreen(),
                    ),
                  ),
                );
              },
              child: _buildGastosSemanal(),
              authRole: authRole,
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    required Widget child,
    required AuthController authRole,
  }) {
    return Container(
      height: 300.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNightBlue.withOpacity(0.1),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            if (authRole.hasPermission(Permission.ver_historial)) {
              onTap(); // Llama al onTap original solo si tiene permiso
            }
          },
          child: Container(
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first.withOpacity(0.3),
                              blurRadius: 8.r,
                              offset: Offset(0, 4.h),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 24.sp),
                      ),
                      if (authRole.hasPermission(Permission.ver_historial))
                        Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppColors.textSecondary,
                            size: 16.sp,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  child, // Sin Expanded ni inner scroll
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaProgress() {
    return Consumer<MetasController>(
      builder: (context, metasController, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _obtenerDatosMetaDiaCompleto(metasController),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Text(
                  'Cargando progreso...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  'Sin meta definida para este día',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            final data = snapshot.data!;
            final principal = data['principal'] as Map<String, dynamic>;
            final secundaria = data['secundaria'] as Map<String, dynamic>;

            Widget buildMetaCard(
              Map<String, dynamic> metaData,
              bool isPrimary,
            ) {
              final metaPasajeros = metaData['meta'] as double?;
              final pasajerosActuales = metaData['pasajeros'] as int;
              final turnoLabel = metaData['turnoLabel'] as String;

              final progreso = metaPasajeros != null && metaPasajeros > 0
                  ? (pasajerosActuales / metaPasajeros).clamp(0.0, 1.0)
                  : 0.0;

              return Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNightBlue.withOpacity(0.1),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPrimary ? 'Meta Principal' : 'Meta Secundaria',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$pasajerosActuales',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '/ $metaPasajeros',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Turno: $turnoLabel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Stack(
                      children: [
                        Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progreso,
                          child: Container(
                            height: 8.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                              ),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${(progreso * 100).toInt()}% completado',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return FlipCard(
              direction:
                  FlipDirection.HORIZONTAL, // Desliza de derecha a izquierda
              front: buildMetaCard(principal, true), // Meta principal
              back: buildMetaCard(secundaria, false), // Meta secundaria
            );
          },
        );
      },
    );
  }

  // Future<Map<String, dynamic>> _obtenerDatosMetaTurnoActual(
  //   MetasController controller,
  // ) async {
  //   final turno = Formatters.getTurnoActual();
  //   final meta = await controller.obtenerMetaSemanaActualTurnoActual();
  //   final pasajeros = await controller
  //       .obtenerSumaPasajerosSemanaActualTurnoActual();
  //   final turnoLabel = turno.label; // Reutiliza la extensión
  //   return {'meta': meta, 'pasajeros': pasajeros, 'turnoLabel': turnoLabel};
  // }

  Future<Map<String, dynamic>> _obtenerDatosMetaDiaCompleto(
    MetasController controller,
  ) async {
    // Determina el turno actual
    final turnoActual = Formatters.getTurnoActual();
    final turnoSecundario = turnoActual == TurnoType.manana
        ? TurnoType.tarde
        : TurnoType.manana;

    // Obtiene meta y pasajeros para ambos turnos
    final metaPrincipal = await controller.obtenerMetaSemanaActual(turnoActual);
    final metaSecundaria = await controller.obtenerMetaSemanaActual(
      turnoSecundario,
    );

    final pasajerosPrincipal = await controller
        .obtenerSumaPasajerosSemanaActualTurno(turnoActual);
    final pasajerosSecundarios = await controller
        .obtenerSumaPasajerosSemanaActualTurno(turnoSecundario);

    return {
      'principal': {
        'meta': metaPrincipal,
        'pasajeros': pasajerosPrincipal,
        'turnoLabel': turnoActual.label,
      },
      'secundaria': {
        'meta': metaSecundaria,
        'pasajeros': pasajerosSecundarios,
        'turnoLabel': turnoSecundario.label,
      },
    };
  }

  Widget _buildGastosSemanal() {
    return Consumer<GastosController>(
      builder: (context, controller, child) {
        return FutureBuilder<double>(
          future: controller.obtenerSumaGastosSemanaActual(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cargando...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final totalGastos = snapshot.data ?? 0.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.formatCurrency(totalGastos),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Esta semana',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Tiempo real',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
