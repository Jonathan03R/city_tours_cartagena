import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/widgets/moder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ModernGraficoSemanal extends StatelessWidget {
  final List<ChartCategoryData> data;
  final String titulo;

  const ModernGraficoSemanal({
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
                Icons.calendar_view_week_outlined,
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
          // Header con estadísticas
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Análisis semanal de rendimiento',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 14.sp,
                      color: AppColors.accentBlue,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${data.length}S',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
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
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                majorGridLines: MajorGridLines(width: 0),
                axisLine: AxisLine(color: Colors.transparent),
                majorTickLines: MajorTickLines(color: Colors.transparent),
              ),
              primaryYAxis: NumericAxis(
                labelStyle: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                majorGridLines: MajorGridLines(
                  width: 1.w,
                  color: AppColors.textLight.withOpacity(0.2),
                  dashArray: [5, 5],
                ),
                axisLine: AxisLine(color: Colors.transparent),
                majorTickLines: MajorTickLines(color: Colors.transparent),
              ),
              series: <CartesianSeries>[
                ColumnSeries<ChartCategoryData, String>(
                  dataSource: data,
                  xValueMapper: (ChartCategoryData data, _) => data.label,
                  yValueMapper: (ChartCategoryData data, _) => data.value,
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
                      fontSize: 10.sp,
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

class ModernGraficoGananciasSemanal extends StatelessWidget {
  final List<ChartCategoryData> data;
  final String titulo;
  final Color accentColor;

  const ModernGraficoGananciasSemanal({
    super.key,
    required this.data,
    required this.titulo,
    this.accentColor = AppColors.warning,
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
          // Header elegante
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Evolución de ganancias semanales',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.trending_up,
                  size: 20.sp,
                  color: accentColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          Container(
            height: 300.h,
            child: SfCartesianChart(
              backgroundColor: Colors.transparent,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                majorGridLines: MajorGridLines(width: 0),
                axisLine: AxisLine(width: 0),
                labelStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
                majorTickLines: MajorTickLines(color: Colors.transparent),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: MajorGridLines(
                  width: 1.w,
                  color: accentColor.withOpacity(0.1),
                  dashArray: [5, 5],
                ),
                axisLine: AxisLine(width: 0),
                labelStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
                majorTickLines: MajorTickLines(color: Colors.transparent),
              ),
              series: <CartesianSeries<ChartCategoryData, String>>[
                SplineAreaSeries<ChartCategoryData, String>(
                  dataSource: data,
                  xValueMapper: (ChartCategoryData data, _) => data.label,
                  yValueMapper: (ChartCategoryData data, _) => data.value,
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.4),
                      accentColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: accentColor,
                  borderWidth: 3.w,
                  splineType: SplineType.cardinal,
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    color: accentColor,
                    borderColor: Colors.white,
                    borderWidth: 3.w,
                    height: 10.h,
                    width: 10.w,
                  ),
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    textStyle: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
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
