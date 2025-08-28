import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/screens/reportes/historial_gastos_view.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/filtros_flexibles.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/grafica_gastos.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  late FiltroFlexibleController _filtrosController;

  @override
  void initState() {
    super.initState();
    _filtrosController = FiltroFlexibleController();
    // Default: última semana y 3 anteriores
    _filtrosController.seleccionarPeriodo(FiltroPeriodo.semana);
    final now = DateTime.now();
    for (var i = 0; i < 4; i++) {
      _filtrosController.agregarSemana(now.subtract(Duration(days: i * 7)));
    }
  }

  @override
  void dispose() {
    _filtrosController.dispose();
    super.dispose();
  }

  void _mostrarModalAgregarGasto(
    BuildContext context,
    GastosController gastosController,
  ) {
    final TextEditingController montoController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    DateTime fechaSeleccionada = DateTime.now(); // Fecha por defecto: hoy

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar Nuevo Gasto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: montoController,
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Fecha: '),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: fechaSeleccionada,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != fechaSeleccionada) {
                            setState(() {
                              fechaSeleccionada = picked;
                            });
                          }
                        },
                        child: Text(
                          '${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    final double? monto = double.tryParse(montoController.text);
                    final String descripcion = descripcionController.text
                        .trim();
                    if (monto != null && descripcion.isNotEmpty) {
                      await gastosController.agregarGasto(
                        monto: monto,
                        descripcion: descripcion,
                        fecha: fechaSeleccionada,
                      );
                      Navigator.of(context).pop();
                      // Opcional: Mostrar un snackbar de confirmación
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Gasto agregado exitosamente'),
                        ),
                      );
                    } else {
                      // Mostrar error si los campos están vacíos o inválidos
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, completa todos los campos correctamente',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GastosController>(
      builder: (context, rc, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Gastos y Finanzas')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ChangeNotifierProvider.value(
              value: _filtrosController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Filtros (semana/mes/año + turno)
                  FiltrosFlexiblesWidget(controller: _filtrosController),
                  const SizedBox(height: 16),
                  // 2) Datos y gráfico
                  Expanded(
                    child: StreamBuilder<List<ReservaConAgencia>>(
                      stream: rc.reservasStream,
                      builder: (context, snapRes) {
                        if (snapRes.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final reservas = snapRes.data ?? [];
                        return Consumer<FiltroFlexibleController>(
                          builder: (context, fc, _) {
                            if (fc.periodoSeleccionado == null) {
                              return const Center(
                                child: Text('Seleccione un período'),
                              );
                            }
                            // Determinar inicio y fin global
                            late DateTime inicio, fin;
                            switch (fc.periodoSeleccionado!) {
                              case FiltroPeriodo.semana:
                                final semanas = List<DateTimeRange>.from(
                                  fc.semanasSeleccionadas,
                                )..sort((a, b) => a.start.compareTo(b.start));
                                if (semanas.isEmpty) {
                                  return const Center(
                                    child: Text('Agregue al menos una semana'),
                                  );
                                }
                                inicio = semanas.first.start;
                                fin = semanas.last.end;
                                break;
                              case FiltroPeriodo.mes:
                                final meses =
                                    List<DateTime>.from(fc.mesesSeleccionados)
                                      ..sort((a, b) {
                                        if (a.year != b.year)
                                          return a.year.compareTo(b.year);
                                        return a.month.compareTo(b.month);
                                      });
                                if (meses.isEmpty) {
                                  return const Center(
                                    child: Text('Agregue al menos un mes'),
                                  );
                                }
                                inicio = DateTime(
                                  meses.first.year,
                                  meses.first.month,
                                  1,
                                );
                                fin = DateTime(
                                  meses.last.year,
                                  meses.last.month + 1,
                                  1,
                                ).subtract(const Duration(days: 1));
                                break;
                              case FiltroPeriodo.anio:
                                final anios = List<int>.from(
                                  fc.aniosSeleccionados,
                                )..sort();
                                if (anios.isEmpty) {
                                  return const Center(
                                    child: Text('Agregue al menos un año'),
                                  );
                                }
                                inicio = DateTime(anios.first, 1, 1);
                                fin = DateTime(anios.last, 12, 31);
                                break;
                            }
                            // 3) Llamada a agruparFinanzasPorPeriodo
                            return FutureBuilder<List<FinanceCategoryData>>(
                              future: rc.agruparFinanzasPorPeriodo(
                                reservas,
                                inicio,
                                fin,
                                turno: fc.turnoSeleccionado,
                                tipoAgrupacion:
                                    fc.periodoSeleccionado ==
                                        FiltroPeriodo.semana
                                    ? 'semana'
                                    : fc.periodoSeleccionado ==
                                          FiltroPeriodo.mes
                                    ? 'mes'
                                    : 'año',
                              ),
                              builder: (context, snapFin) {
                                if (snapFin.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (snapFin.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapFin.error}'),
                                  );
                                }

                                final finanzas = snapFin.data ?? [];

                                if (finanzas.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No hay datos para este periodo.',
                                    ),
                                  );
                                }

                                // 🔹 Aquí calculas los totales usando tu método
                                return FutureBuilder<Map<String, double>>(
                                  future: rc.calcularTotales(finanzas),
                                  builder: (context, snapTotales) {
                                    if (!snapTotales.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    final totales = snapTotales.data!;

                                    final periodoLabel =
                                        fc.periodoSeleccionado ==
                                            FiltroPeriodo.semana
                                        ? 'Semana'
                                        : fc.periodoSeleccionado ==
                                              FiltroPeriodo.mes
                                        ? 'Mes'
                                        : 'Año';

                                    return Column(
                                      children: [
                                        // 🔹 Widget para mostrar totales
                                        Card(
                                          elevation: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "Totales $periodoLabel",
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        const Text("Ingresos"),
                                                        Text(
                                                          "\$${totales["ganancias"]!.toStringAsFixed(2)}",
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        const Text("Gastos"),
                                                        Text(
                                                          "\$${totales["gastos"]!.toStringAsFixed(2)}",
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        const Text("Utilidad"),
                                                        Text(
                                                          "\$${totales["utilidad"]!.toStringAsFixed(2)}",
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        const Text("Margen"),
                                                        Text(
                                                          "${totales["margen"]!.toStringAsFixed(1)}%",
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // 🔹 Tu gráfica de finanzas
                                        Expanded(
                                          child: GraficaFinanzasSimple(
                                            data: finanzas,
                                            titulo:
                                                'Finanzas por $periodoLabel',
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
                      },
                    ),
                  ),

                  // Botones para agregar gasto y navegar al historial
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final gastosController =
                              Provider.of<GastosController>(
                                context,
                                listen: false,
                              );
                          _mostrarModalAgregarGasto(context, gastosController);
                        },
                        child: const Text('Agregar Gasto'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistorialGastosView(),
                            ),
                          );
                        },
                        child: const Text('Ver Historial'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
