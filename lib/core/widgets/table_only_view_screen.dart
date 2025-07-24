import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/mvvc/reservas_controller.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart'; // Necesario para DateFilterType
import 'package:citytourscartagena/core/widgets/reservas_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Importar Provider

class TableOnlyViewScreen extends StatefulWidget {
  // Estos parámetros ya no son estrictamente necesarios si el controlador gestiona el estado
  // pero los mantenemos para la inicialización del controlador al entrar a esta vista.
  final DateFilterType selectedFilter;
  final DateTime? customDate;
  final String? agenciaId;
  final VoidCallback onUpdate; // Este callback ahora debería forzar la actualización del controlador

  const TableOnlyViewScreen({
    super.key,
    required this.selectedFilter,
    this.customDate,
    this.agenciaId,
    required this.onUpdate,
  });

  @override
  State<TableOnlyViewScreen> createState() => _TableOnlyViewScreenState();
}

class _TableOnlyViewScreenState extends State<TableOnlyViewScreen> {
  // Eliminamos el stream local, ahora lo obtenemos del controlador
  // Stream<List<ReservaConAgencia>>? _reservasStream;

  @override
  void initState() {
    super.initState();
    // Al entrar a esta vista, aseguramos que el ReservasController tenga los filtros correctos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reservasController = Provider.of<ReservasController>(context, listen: false);
      reservasController.updateFilter(
        widget.selectedFilter,
        date: widget.customDate,
        agenciaId: widget.agenciaId,
      );
    });

    // Mantener la configuración de orientación para la vista de tabla completa
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Volver a la orientación vertical al salir de esta pantalla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  // Eliminamos _loadReservasStream() ya que el controlador lo gestiona

  // Método para obtener el título de la fecha, similar al de ReservasView
  String _getFilterTitle(DateFilterType selectedFilter, DateTime? customDate) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    String formatearFecha(DateTime fecha) {
      return '${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}';
    }

    switch (selectedFilter) {
      case DateFilterType.all:
        return 'Todas las reservas';
      case DateFilterType.lastWeek:
        return 'Reservas de la última semana';
      case DateFilterType.today:
        return formatearFecha(DateTime.now());
      case DateFilterType.yesterday:  // ← nuevo caso agregado
      return formatearFecha(
        DateTime.now().subtract(const Duration(days: 1))
      );
      case DateFilterType.tomorrow:
        return formatearFecha(DateTime.now().add(const Duration(days: 1)));
      case DateFilterType.custom:
        return customDate != null
            ? formatearFecha(customDate)
            : 'Fecha personalizada';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observar el ReservasController para que la UI se reconstruya con los cambios
    final reservasController = context.watch<ReservasController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Vista de Tabla Completa'), // Mostrar la fecha en el título
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            // Al regresar, llamar al onUpdate para que la vista anterior sepa que debe recargar
            widget.onUpdate();
          },
          tooltip: 'Regresar',
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              child: Text(
                // Obtener los filtros del controlador
                'fecha - ${_getFilterTitle(reservasController.selectedFilter, reservasController.customDate)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<List<ReservaConAgencia>>(
              stream: reservasController.filteredReservasStream, // Usar el stream del controlador
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_chart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay reservas para mostrar en esta vista',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ReservasTable(
                  reservas: snapshot.data!, // Pasar la lista del snapshot
                  onUpdate: () {
                    // Al actualizar desde la tabla, forzar una recarga en el controlador
                    reservasController.updateFilter(
                      reservasController.selectedFilter,
                      date: reservasController.customDate,
                      agenciaId: widget.agenciaId,
                    );
                  },
                  currentFilter: reservasController.selectedFilter, // Pasar del controlador
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
