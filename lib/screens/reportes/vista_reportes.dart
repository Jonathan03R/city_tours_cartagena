import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/screens/reportes/historial_gastos_view.dart';
import 'package:citytourscartagena/screens/reportes/historial_metas_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportesView extends StatefulWidget {
  const ReportesView({Key? key}) : super(key: key);

  @override
  State<ReportesView> createState() => _ReportesViewState();
}

class _ReportesViewState extends State<ReportesView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedPeriod = 'Semana';
  final List<String> _periods = ['Semana', 'Mes', 'Año'];

  static const Color _primaryNavy = Color(0xFF0A1628);
  static const Color _accentTeal = Color(0xFF14B8A6);
  static const Color _accentAmber = Color(0xFFF59E0B);
  static const Color _surfaceBlue = Color(0xFF1E3A8A);
  static const Color _lightBlue = Color(0xFF3B82F6);
  static const Color _cardBackground = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportesController>(
      builder: (context, controller, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
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
              final pasajerosData = controller.calcPasajeros(
                list: reservas,
                periodo: _selectedPeriod,
              );
              final gananciasData = controller.calcGanancias(
                list: reservas,
                periodo: _selectedPeriod,
              );

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPeriodSelector(),
                        const SizedBox(height: 24),
                        _buildNavigationCards(),
                        const SizedBox(height: 32),
                        _buildMetricsCards(pasajerosData),
                        const SizedBox(height: 32),
                        _buildPassengersChart(pasajerosData.data),
                        const SizedBox(height: 32),
                        _buildRevenueChart(gananciasData),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [_primaryNavy, _surfaceBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primaryNavy.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsCards(PasajerosData data) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Total Pasajeros',
            value: data.totalPas.toString(),
            icon: Icons.people_rounded,
            gradient: const LinearGradient(
              colors: [_accentTeal, Color(0xFF06B6D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Ganancias Totales',
            value: '\$${_formatCurrency(data.totalRev)}',
            icon: Icons.trending_up_rounded,
            gradient: const LinearGradient(
              colors: [_accentAmber, Color(0xFFEAB308)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengersChart(List<ChartCategoryData> data) {
    return _buildChartContainer(
      title: 'Pasajeros por $_selectedPeriod',
      icon: Icons.people_outline_rounded,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          labelStyle: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 1,
            color: _textSecondary.withOpacity(0.1),
          ),
          axisLine: const AxisLine(width: 0),
          labelStyle: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        series: <CartesianSeries<ChartCategoryData, String>>[
          ColumnSeries<ChartCategoryData, String>(
            dataSource: data,
            xValueMapper: (ChartCategoryData data, _) => data.label,
            yValueMapper: (ChartCategoryData data, _) => data.value,
            gradient: const LinearGradient(
              colors: [_accentTeal, Color(0xFF06B6D4)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            width: 0.7,
            spacing: 0.2,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          color: _primaryNavy,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<ChartCategoryData> data) {
    return _buildChartContainer(
      title: 'Ganancias por $_selectedPeriod',
      icon: Icons.show_chart_rounded,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          labelStyle: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 1,
            color: _textSecondary.withOpacity(0.1),
          ),
          axisLine: const AxisLine(width: 0),
          labelStyle: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        series: <CartesianSeries<ChartCategoryData, String>>[
          SplineAreaSeries<ChartCategoryData, String>(
            dataSource: data,
            xValueMapper: (ChartCategoryData data, _) => data.label,
            yValueMapper: (ChartCategoryData data, _) => data.value,
            gradient: LinearGradient(
              colors: [
                _accentAmber.withOpacity(0.3),
                _accentAmber.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: _accentAmber,
            borderWidth: 3,
            splineType: SplineType.cardinal,
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          color: _primaryNavy,
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildChartContainer({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryNavy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _primaryNavy, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 280, child: child),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryNavy),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando datos financieros...',
            style: TextStyle(color: _textSecondary, fontSize: 16),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay datos disponibles',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Los reportes aparecerán cuando tengas reservas',
            style: TextStyle(color: _textSecondary, fontSize: 14),
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
            title: 'Meta Semanal',
            subtitle: 'Progreso de esta semana',
            icon: Icons.flag_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistorialMetasView()),
              );
            },
            child: _buildMetaProgress(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildNavigationCard(
            title: 'Gastos Semanal',
            subtitle: 'En pesos colombianos',
            icon: Icons.receipt_long_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFF87171)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistorialGastosView()),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 200.h, // Altura igual para ambos cards
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _primaryNavy.withOpacity(0.08),
              blurRadius: 20.r,
              offset: Offset(0, 6.h),
            ),
          ],
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _textSecondary,
                  size: 16.sp,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            // SizedBox(height: 4.h),
            // Text(
            //   subtitle,
            //   style: TextStyle(
            //     color: _textSecondary,
            //     fontSize: 12.sp,
            //     fontWeight: FontWeight.w500,
            //   ),
            // ),
            SizedBox(height: 16.h),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaProgress() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

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
                  print(
                    'DEBUG: No se encontró meta semanal para startOfWeek: ${startOfWeek.toIso8601String()}',
                  );
                  print(
                    'DEBUG: Documentos encontrados: ${snapshot.data?.docs.length ?? 0}',
                  );
                  FirebaseFirestore.instance.collection('metas').get().then((
                    allMetas,
                  ) {
                    for (var doc in allMetas.docs) {
                      final start = (doc['startOfWeek'] as Timestamp).toDate();
                      print(
                        'DEBUG: Meta en Firestore - startOfWeek: ${start.toIso8601String()}',
                      );
                    }
                  });
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sin meta definida',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _textSecondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  );
                }

                final metaDoc = snapshot.data!.docs.first;
                final metaPasajeros = metaDoc['goal'] ?? 0;

                // Calcula los pasajeros actuales de la semana usando el controlador
                final pasajerosActuales = controller.calcularPasajerosEnRango(
                  reservas,
                  startOfWeek,
                  endOfWeek,
                );

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
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '/ $metaPasajeros',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: _textSecondary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progreso,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progreso * 100).toInt()}% completado',
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
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
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cargando...',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
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
            Row(
              children: [
                Text(
                  formatter.format(totalGastos),
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${snapshot.data!.docs.length} transacciones',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Actualizado en tiempo real',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
