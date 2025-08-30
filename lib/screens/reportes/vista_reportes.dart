import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/controller/metas_controller.dart';
import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/finanzas/finanzas_service.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/screens/metas/metas_screen.dart';
import 'package:citytourscartagena/screens/reportes/gastos_screen.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/filtros_flexibles.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/grafico_comparacion.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/grafico_semanal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5), 
      end: Offset.zero
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
    _filtrosController = FiltroFlexibleController();
    
    // Selección predeterminada: filtro semana y las últimas 4 semanas (actual + 3 anteriores)
    _filtrosController.seleccionarPeriodo(FiltroPeriodo.semana);
    final now = DateTime.now();
    for (int i = 0; i < 4; i++) {
      _filtrosController.agregarSemana(now.subtract(Duration(days: 7 * i)));
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _filtrosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      SliverAppBar(
                        expandedHeight: 120.h,
                        floating: false,
                        pinned: true,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        flexibleSpace: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primaryNightBlue,
                                AppColors.secondaryNightBlue,
                                AppColors.accentBlue,
                              ],
                              stops: [0.0, 0.6, 1.0],
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(32.r),
                              bottomRight: Radius.circular(32.r),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryNightBlue.withOpacity(0.3),
                                blurRadius: 20.r,
                                offset: Offset(0, 8.h),
                              ),
                            ],
                          ),
                          child: FlexibleSpaceBar(
                            title: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Colors.white, Colors.white.withOpacity(0.9)],
                              ).createShader(bounds),
                              child: Text(
                                'Dashboard Financiero',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.primaryNightBlue.withOpacity(0.5),
                                      blurRadius: 8.0,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            centerTitle: true,
                          ),
                        ),
                      ),
                      
                      SliverPadding(
                        padding: EdgeInsets.all(20.w),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildNavigationCards(),
                            SizedBox(height: 32.h),
                            _graficosComparativos(controller, reservas),
                            SizedBox(height: 32.h),
                            _buildWeeklyCharts(controller, reservas),
                            SizedBox(height: 100.h), // Bottom padding
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

  Widget _graficosComparativos(
    ReportesController reportesController,
    List<ReservaConAgencia> reservas,
  ) {
    return ChangeNotifierProvider.value(
      value: _filtrosController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                    gradient: LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.lightBlue],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Análisis Comparativo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ModernFiltrosFlexiblesWidget(controller: _filtrosController),
          SizedBox(height: 20.h),
          Consumer<FiltroFlexibleController>(
            builder: (context, filtrosController, child) {
              // ... existing logic ...
              final turno = filtrosController.turnoSeleccionado;
              final periodo = filtrosController.periodoSeleccionado!;

              final semanas = filtrosController.semanasSeleccionadas;
              final meses = filtrosController.mesesSeleccionados;
              final anios = filtrosController.aniosSeleccionados;

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
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModernGraficoComparacion(
                    datos: datosPasajeros,
                    titulo: "Pasajeros",
                  ),
                  SizedBox(height: 32.h),
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
    return ChangeNotifierProvider.value(
      value: _filtrosController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accentBlue, AppColors.lightBlue],
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
                          _filtrosController.seleccionarSemana(fechaSeleccionada);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Consumer<FiltroFlexibleController>(
            builder: (context, filtrosController, child) {
              final semanaSeleccionada = filtrosController.semanaSeleccionada;

              final pasajerosData = reportesController.calcularPasajerosPorSemana(
                list: reservas,
                inicio: semanaSeleccionada.start,
                fin: semanaSeleccionada.end,
              );
              
              final gananciasData = reportesController.calcularGananciasPorSemana(
                list: reservas,
                inicio: semanaSeleccionada.start,
                fin: semanaSeleccionada.end,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ModernGraficoSemanal(
                    data: pasajerosData,
                    titulo: 'Pasajeros del ${semanaSeleccionada.start.day}/${semanaSeleccionada.start.month} '
                        'al ${semanaSeleccionada.end.day}/${semanaSeleccionada.end.month}',
                  ),
                  SizedBox(height: 32.h),
                  ModernGraficoGananciasSemanal(
                    data: gananciasData,
                    titulo: 'Ganancias del ${semanaSeleccionada.start.day}/${semanaSeleccionada.start.month} '
                        'al ${semanaSeleccionada.end.day}/${semanaSeleccionada.end.month}',
                  ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
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
                      colors: [AppColors.textSecondary.withOpacity(0.1), AppColors.textSecondary.withOpacity(0.05)],
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
    return Row(
      children: [
        Expanded(
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
            child: _buildMetaProgress(),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
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
  }) {
    return Container(
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
          borderRadius: BorderRadius.circular(20.r),
          onTap: onTap,
          child: Container(
            height: 200.h,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(20.r),
            ),
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
                SizedBox(height: 20.h),
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
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaProgress() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final FinanzasService _finanzasService = FinanzasService();
    
    return Consumer<ReportesController>(
      builder: (context, controller, _) {
        return StreamBuilder<List<ReservaConAgencia>>(
          stream: controller.reservasStream,
          builder: (context, reservasSnapshot) {
            final reservas = reservasSnapshot.data ?? [];
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('metas')
                  .where(
                    'startOfWeek',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(
                      DateTime(
                        startOfWeek.year,
                        startOfWeek.month,
                        startOfWeek.day,
                      ),
                    ),
                  )
                  .where(
                    'startOfWeek',
                    isLessThan: Timestamp.fromDate(
                      DateTime(
                        startOfWeek.year,
                        startOfWeek.month,
                        startOfWeek.day + 1,
                      ),
                    ),
                  )
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sin meta definida',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  );
                }

                final metaDoc = snapshot.data!.docs.first;
                final metaPasajeros = metaDoc['goal'] ?? 0;

                final pasajerosActuales = _finanzasService
                    .calcularPasajerosEnRango(reservas, startOfWeek, endOfWeek);

                final progreso = metaPasajeros > 0
                    ? (pasajerosActuales / metaPasajeros).clamp(0.0, 1.0)
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGastosSemanal() {
    final now = DateTime.now();
    final primerDiaSemana = now.subtract(Duration(days: now.weekday % 7));
    final ultimoDiaSemana = primerDiaSemana.add(const Duration(days: 6));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('gastos')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(primerDiaSemana),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(ultimoDiaSemana),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
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

        double totalGastos = 0;
        for (var doc in snapshot.data!.docs) {
          totalGastos += (doc['amount'] ?? doc['amount'] ?? 0).toDouble();
        }

        final formatter = NumberFormat.currency(
          locale: 'es_CO',
          symbol: '\$',
          decimalDigits: 0,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatter.format(totalGastos),
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
                  '${snapshot.data!.docs.length} transacciones',
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
  }
}
