import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/moder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Gráfico moderno y profesional de Ingresos, Gastos y Utilidad Neta por periodo.
class ModernGraficaFinanzas extends StatelessWidget {
  final List<FinanceCategoryData> data;
  final String titulo;

  const ModernGraficaFinanzas({
    super.key,
    required this.data,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return ModernCard(
        child: Container(
          height: 300.h,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
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
          // Header del gráfico
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  '${data.length} períodos',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Gráfico
          Container(
            height: 350.h,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBackgroundColor: Colors.transparent,
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                iconHeight: 12.h,
                iconWidth: 12.w,
                padding: 16.h,
              ),
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
                title: AxisTitle(
                  text: 'COP',
                  textStyle: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                numberFormat: NumberFormat.compact(locale: 'es_CO'),
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
                ColumnSeries<FinanceCategoryData, String>(
                  name: 'Ingresos',
                  dataSource: data,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.revenues,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success,
                      AppColors.success.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4.r),
                    topRight: Radius.circular(4.r),
                  ),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ColumnSeries<FinanceCategoryData, String>(
                  name: 'Gastos',
                  dataSource: data,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.expenses,
                  gradient: LinearGradient(
                    colors: [AppColors.error, AppColors.error.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4.r),
                    topRight: Radius.circular(4.r),
                  ),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SplineSeries<FinanceCategoryData, String>(
                  name: 'Utilidad Neta',
                  dataSource: data,
                  xValueMapper: (d, _) => d.label,
                  yValueMapper: (d, _) => d.utility,
                  color: AppColors.accentBlue,
                  width: 3.w,
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
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentBlue,
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
                  fontWeight: FontWeight.w500,
                ),

                // borderRadius: 8.r,
                elevation: 10,
              ),
              onTooltipRender: (TooltipArgs args) {
                final idx = (args.pointIndex ?? 0).toInt();
                final puntos = args.dataPoints;
                if (puntos != null && idx < puntos.length) {
                  final valor = puntos[idx].y;
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
