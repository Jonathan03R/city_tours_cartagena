import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/mvvc/reservas_controller.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/core/widgets/reservas_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TableOnlyViewScreen extends StatefulWidget {
  final DateFilterType selectedFilter;
  final DateTime? customDate;
  final String? agenciaId;
  final VoidCallback onUpdate;

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
  Stream<List<ReservaConAgencia>>? _reservasStream;

  @override
  void initState() {
    super.initState();
    _loadReservasStream();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _loadReservasStream() {
    setState(() {
      switch (widget.selectedFilter) {
        case DateFilterType.all:
          _reservasStream = ReservasController.getReservasStream();
          break;
        case DateFilterType.today:
          _reservasStream = ReservasController.getReservasByFechaStream(
            DateTime.now(),
          );
          break;
        case DateFilterType.tomorrow:
          _reservasStream = ReservasController.getReservasByFechaStream(
            DateTime.now().add(const Duration(days: 1)),
          );
          break;
        case DateFilterType.lastWeek:
          _reservasStream = ReservasController.getReservasLastWeekStream();
          break;
        case DateFilterType.custom:
          if (widget.customDate != null) {
            _reservasStream = ReservasController.getReservasByFechaStream(
              widget.customDate!,
            );
          } else {
            _reservasStream = Stream.value([]);
          }
          break;
      }

      if (widget.agenciaId != null) {
        _reservasStream = _reservasStream!.map((list) =>
            list.where((r) => r.agencia.id == widget.agenciaId).toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista de Tabla Completa'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          tooltip: 'Regresar',
        ),
      ),
      body: StreamBuilder<List<ReservaConAgencia>>(
        stream: _reservasStream,
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
            reservas: snapshot.data!,
            onUpdate: widget.onUpdate,
            currentFilter: widget.selectedFilter, // Pasa el filtro actual
          );
        },
      ),
    );
  }
}
