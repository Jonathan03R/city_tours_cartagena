import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Gráfico sencillo de Ingresos, Gastos y Utilidad Neta por periodo.
/// No muestra margen ni segundo eje.
class GraficaFinanzasSimple extends StatelessWidget {
  final List<FinanceCategoryData> data;
  final String titulo;

  const GraficaFinanzasSimple({
    Key? key,
    required this.data,
    required this.titulo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 350,
          child: SfCartesianChart(
            legend: Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              overflowMode: LegendItemOverflowMode.wrap,
            ),
            primaryXAxis: CategoryAxis(),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: 'COP'),
              numberFormat: NumberFormat.compact(locale: 'es_CO'),
              majorGridLines: const MajorGridLines(color: Colors.grey, width: 0.5),
            ),
            series: <CartesianSeries>[
              ColumnSeries<FinanceCategoryData, String>(
                name: 'Ingresos',
                dataSource: data,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.revenues,
                color: Colors.green,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
              ColumnSeries<FinanceCategoryData, String>(
                name: 'Gastos',
                dataSource: data,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.expenses,
                color: Colors.redAccent,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
              LineSeries<FinanceCategoryData, String>(
                name: 'Utilidad Neta',
                dataSource: data,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.utility,
                color: Colors.blue,
                width: 2,
                markerSettings: const MarkerSettings(isVisible: true),
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ],
            tooltipBehavior: TooltipBehavior(enable: true),
          ),
        ),
      ],
    );
  }
}