import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraficoComparacion extends StatelessWidget {
  final List<ChartCategoryData> datos;
  final String titulo;

  const GraficoComparacion({
    super.key,
    required this.datos,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {

    debugPrint('DEBUG: Datos recibidos para el gráfico:');
    for (var dato in datos) {
      debugPrint('Label: ${dato.label}, Value: ${dato.value}');
    }

    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            series: <CartesianSeries>[
              ColumnSeries<ChartCategoryData, String>(
                dataSource: datos,
                xValueMapper: (ChartCategoryData data, _) => data.label,
                yValueMapper: (ChartCategoryData data, _) => data.value,
                color: Colors.blue,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// …existing imports…

/// Gráfico de líneas (spline) para comparar series de datos,
/// ideal para mostrar evolución de ganancias.
class GraficoComparacionLinea extends StatelessWidget {
  final List<ChartCategoryData> datos;
  final String titulo;

  const GraficoComparacionLinea({
    super.key,
    required this.datos,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    if (datos.isEmpty) {
      return const Center(child: Text('No hay datos para mostrar.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: SfCartesianChart(
            // mismo fondo cuadriculado
            plotAreaBackgroundColor: Colors.white,
            plotAreaBorderColor: Colors.grey.withOpacity(0.3),
            plotAreaBorderWidth: 1,
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 1, color: Colors.grey),
            ),
            primaryYAxis: NumericAxis(
              numberFormat: NumberFormat.compact(),
              majorGridLines: const MajorGridLines(width: 1, color: Colors.grey),
              minorGridLines: const MinorGridLines(width: 1, color: Colors.grey),
              minorTicksPerInterval: 1,
            ),
            series: <CartesianSeries>[
              SplineSeries<ChartCategoryData, String>(
                dataSource: datos,
                xValueMapper: (d, _) => d.label,
                yValueMapper: (d, _) => d.value,
                color: Colors.amber,
                width: 2,
                markerSettings: const MarkerSettings(isVisible: true),
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  textStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}