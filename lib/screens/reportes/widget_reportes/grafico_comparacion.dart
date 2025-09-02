import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/moder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ModernGraficoComparacion extends StatelessWidget {
  final List<ChartCategoryData> datos;
  final String titulo;

  const ModernGraficoComparacion({
    super.key,
    required this.datos,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return ModernCard(
        child: Container(
          height: 300.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48.sp,
                color: AppColors.textLight,
              ),
              SizedBox(height: 16.h),
              Text(
                'No hay datos para mostrar',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ModernCard(
      hasGradient: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          Container(
            height: 300.h,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBackgroundColor: Colors.transparent,
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                axisLine: AxisLine(color: Colors.transparent),
                majorTickLines: MajorTickLines(color: Colors.transparent),
                majorGridLines: MajorGridLines(color: Colors.transparent),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
                majorGridLines: MajorGridLines(
                  color: AppColors.textLight.withOpacity(0.2),
                  width: 1.w,
                  dashArray: [5, 5],
                ),
                axisLine: AxisLine(color: Colors.transparent),
                majorTickLines: MajorTickLines(color: Colors.transparent),
              ),
              series: <CartesianSeries>[
                ColumnSeries<ChartCategoryData, String>(
                  dataSource: datos,
                  xValueMapper: (ChartCategoryData data, _) => data.label,
                  yValueMapper: (ChartCategoryData data, _) => data.value1,
                  gradient: LinearGradient(
                    colors: [AppColors.accentBlue, AppColors.lightBlue],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.r),
                    topRight: Radius.circular(8.r),
                  ),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: AppColors.primaryNightBlue,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
                // borderRadius: 8.r,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de líneas moderno para comparar series de datos
class ModernGraficoComparacionLinea extends StatelessWidget {
  final List<ChartCategoryData> datos; // Cambiado a List<ChartCategoryData>
  final String titulo;

  const ModernGraficoComparacionLinea({
    super.key,
    required this.datos,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return ModernCard(
        child: Container(
          height: 300.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart_outlined,
                size: 48.sp,
                color: AppColors.textLight,
              ),
              SizedBox(height: 16.h),
              Text(
                'No hay datos para mostrar',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ModernCard(
      hasGradient: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          Container(
            height: 300.h,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBackgroundColor: Colors.transparent,
              primaryXAxis: CategoryAxis(
                labelStyle: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                axisLine: AxisLine(color: Colors.transparent),
                majorTickLines: MajorTickLines(color: Colors.transparent),
                majorGridLines: MajorGridLines(
                  color: AppColors.textLight.withOpacity(0.1),
                  width: 1.w,
                ),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compact(),
                labelStyle: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
                majorGridLines: MajorGridLines(
                  color: AppColors.textLight.withOpacity(0.2),
                  width: 1.w,
                  dashArray: [5, 5],
                ),
                axisLine: AxisLine(color: Colors.transparent),
                majorTickLines: MajorTickLines(color: Colors.transparent),
              ),
              series: <CartesianSeries>[
                // Primera línea (value1)
                SplineAreaSeries<ChartCategoryData, String>(
                  dataSource: datos,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.value1.toDouble(),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withOpacity(0.3),
                      AppColors.warning.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: AppColors.warning,
                  borderWidth: 3.w,
                  splineType: SplineType.cardinal,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    color: AppColors.warning,
                    borderColor: Colors.white,
                    borderWidth: 2.w,
                    height: 12.h,
                    width: 12.w,
                  ),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.sp,
                    ),
                  ),
                  name: 'Ganancias',
                ),
                // Segunda línea (value2) solo si hay datos no cero
                if (datos.any((d) => d.value2 != 0))
                  SplineAreaSeries<ChartCategoryData, String>(
                    dataSource: datos,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.value2.toDouble(), 
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentBlue.withOpacity(0.3),
                        AppColors.accentBlue.withOpacity(0.1),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderColor: AppColors.accentBlue,
                    borderWidth: 3.w,
                    splineType: SplineType.cardinal,
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      color: AppColors.accentBlue,
                      borderColor: Colors.white,
                      borderWidth: 2.w,
                      height: 12.h,
                      width: 12.w,
                    ),
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      textStyle: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 10.sp,
                      ),
                    ),
                    name: 'Gastos',
                  ),
              ],
              tooltipBehavior: TooltipBehavior(
                enable: true,
                color: AppColors.primaryNightBlue,
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
              ),
               onTooltipRender: (TooltipArgs args) {
                final idx = (args.pointIndex ?? 0).toInt();
                final puntos = args.dataPoints;
                if (puntos != null && idx < puntos.length) {
                  final valor = puntos[idx].y.toDouble(); // Cast a double para evitar error de tipo
                  args.text = Formatters.formatCurrency(valor);
                }
              },

            ),
          ),
        ],
      ),
    );
  }
}