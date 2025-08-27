import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraficoSemanal extends StatelessWidget {

  final List<ChartCategoryData> data;
  final String titulo;

  const GraficoSemanal({
    super.key,
    required this.data,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              majorGridLines: const MajorGridLines(width: 0),
            ),
            primaryYAxis: NumericAxis(
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              majorGridLines: MajorGridLines(
                width: 1,
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            series: <CartesianSeries>[
              ColumnSeries<ChartCategoryData, String>(
                dataSource: data,
                xValueMapper: (ChartCategoryData data, _) => data.label,
                yValueMapper: (ChartCategoryData data, _) => data.value,
                color: Colors.blueAccent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  textStyle: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            tooltipBehavior: TooltipBehavior(enable: true),
          ),
        ),
      ],
    );
  }
}


class GraficoGananciasSemanal extends StatelessWidget {
  final List<ChartCategoryData> data;
  final String titulo;
  final Color accentColor;

  const GraficoGananciasSemanal({
    super.key,
    required this.data,
    required this.titulo,
    this.accentColor = const Color(0xFFF59E0B), // Amber por defecto
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            primaryYAxis: NumericAxis(
              majorGridLines: MajorGridLines(
                width: 1,
                color: accentColor.withOpacity(0.1),
              ),
              axisLine: const AxisLine(width: 0),
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
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
                    accentColor.withOpacity(0.3),
                    accentColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderColor: accentColor,
                borderWidth: 3,
                splineType: SplineType.cardinal,
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  textStyle: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: const Color(0xFF0A1628),
              textStyle: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}


