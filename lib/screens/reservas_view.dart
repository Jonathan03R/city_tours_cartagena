import 'dart:io';

import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/mvvc/configuracion_controller.dart';
import 'package:citytourscartagena/core/services/configuracion_service.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/table_only_view_screen.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/mvvc/reservas_controller.dart';
import '../core/widgets/add_reserva_form.dart';
import '../core/widgets/add_reserva_pro_form.dart';
import '../core/widgets/date_filter_buttons.dart';
import '../core/widgets/reserva_card_item.dart';
import '../core/widgets/reserva_details.dart';
import '../core/widgets/reservas_table.dart';

class ReservasView extends StatefulWidget {
  final String? agenciaId;
  const ReservasView({super.key, this.agenciaId});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  List<ReservaConAgencia> _currentReservas = [];
  Stream<List<ReservaConAgencia>>? _reservasStream;

  DateFilterType _selectedFilter = DateFilterType.today;
  DateTime? _customDate;
  bool _isTableView = true;
  bool _editandoPrecio = false;
  final TextEditingController _precioController = TextEditingController();
  Configuracion? _configuracion;

  @override
  void initState() {
    super.initState();
    ReservasController.printDebugInfo();
    _loadReservas();
    _loadConfiguracion();
  }

  Future<void> _loadConfiguracion() async {
    final config = await ConfiguracionService.getConfiguracion();
    if (config != null) {
      setState(() {
        _configuracion = config;
      });
    }
  }

  void _loadReservas() {
    setState(() {
      switch (_selectedFilter) {
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
          if (_customDate != null) {
            _reservasStream = ReservasController.getReservasByFechaStream(
              _customDate!,
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

  void _onFilterChanged(DateFilterType filter, DateTime? date) {
    setState(() {
      _selectedFilter = filter;
      if (date != null) {
        _customDate = date;
      }
    });
    _loadReservas();
  }

  void _showTableOnlyView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TableOnlyViewScreen(
          selectedFilter: _selectedFilter,
          customDate: _customDate,
          agenciaId: widget.agenciaId,
          onUpdate: _loadReservas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConfiguracionController>();
    final configuracion = controller.configuracion;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.agenciaId != null ? 'Reservas de Agencia' : 'Reservas',
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTableView ? Icons.view_list : Icons.table_chart),
            onPressed: () {
              setState(() {
                _isTableView = !_isTableView;
              });
            },
            tooltip: _isTableView ? 'Vista de lista' : 'Vista de tabla',
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _showTableOnlyView,
            tooltip: 'Ver tabla completa',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservas,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SingleChildScrollView( // Envuelve todo el contenido del body para permitir el scroll vertical
        child: Column(
          children: [
            DateFilterButtons(
              selectedFilter: _selectedFilter,
              customDate: _customDate,
              onFilterChanged: _onFilterChanged,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return isWide
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _getFilterTitle(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            _buildRightControls(),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getFilterTitle(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRightControls(),
                          ],
                        );
                },
              ),
            ),
            StreamBuilder<List<ReservaConAgencia>>(
              stream: _reservasStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  _currentReservas = [];
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_chart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay reservas para mostrar',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                _currentReservas = snapshot.data!;
                debugPrint('🔄 Reservas cargadas en vista: ${_currentReservas.length}');

                return _isTableView
                    ? ReservasTable(
                        reservas: _currentReservas,
                        onUpdate: _loadReservas,
                        currentFilter: _selectedFilter, // Pasa el filtro actual
                      )
                    : ListView.builder(
                        shrinkWrap: true, // Importante para ListView dentro de SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(), // Deshabilita el scroll propio del ListView
                        padding: const EdgeInsets.all(16),
                        itemCount: _currentReservas.length,
                        itemBuilder: (ctx, i) {
                          return ReservaCardItem(
                            reserva: _currentReservas[i],
                            onTap: () => _showReservaDetails(_currentReservas[i]),
                          );
                        },
                      );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: widget.agenciaId == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: _showAddReservaProForm,
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('registro rapido'),
                  heroTag: "pro_button",
                ),
                const SizedBox(height: 16),
                // FloatingActionButton(
                //   onPressed: _showAddReservaForm,
                //   backgroundColor: Colors.blue.shade600,
                //   heroTag: "normal_button",
                //   child: const Icon(Icons.add, color: Colors.white),
                // ),
              ],
            )
          : null,
    );
  }

  String _getFilterTitle() {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    String formatearFecha(DateTime fecha) {
      return '${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}';
    }

    switch (_selectedFilter) {
      case DateFilterType.all:
        return 'Todas las reservas';
      case DateFilterType.lastWeek:
        return 'Reservas de la última semana';
      case DateFilterType.today:
        return formatearFecha(DateTime.now());
      case DateFilterType.tomorrow:
        return formatearFecha(DateTime.now().add(const Duration(days: 1)));
      case DateFilterType.custom:
        return _customDate != null
            ? formatearFecha(_customDate!)
            : 'Fecha personalizada';
    }
  }

  void _showReservaDetails(ReservaConAgencia reserva) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          ReservaDetails(reserva: reserva, onUpdate: _loadReservas),
    );
  }

  void _showAddReservaForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaForm(onAdd: _loadReservas),
    );
  }

  void _showAddReservaProForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaProForm(onAdd: _loadReservas),
    );
  }

  Future<void> _exportToExcel(List<ReservaConAgencia> reservas) async {
    try {
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso denegado. No se puede guardar el archivo'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final excel = xls.Excel.createExcel();
      final sheet = excel['Reservas'];
      sheet.appendRow([
        xls.TextCellValue('HOTEL'),
        xls.TextCellValue('CLIENTE'),
        xls.TextCellValue('FECHA'),
        xls.TextCellValue('PAX'),
        xls.TextCellValue('SALDO'),
        xls.TextCellValue('AGENCIA'),
        xls.TextCellValue('OBSERVACIONES'),
        xls.TextCellValue('ESTADO'),
      ]);
      for (var r in reservas) {
        sheet.appendRow([
          xls.TextCellValue(r.hotel.isEmpty ? 'Sin hotel' : r.hotel),
          xls.TextCellValue(r.nombreCliente),
          xls.TextCellValue(Formatters.formatDate(r.fecha)),
          xls.IntCellValue(r.pax),
          xls.DoubleCellValue(r.saldo),
          xls.TextCellValue(r.nombreAgencia),
          xls.TextCellValue(
            r.observacion.isEmpty ? 'Sin observaciones' : r.observacion,
          ),
          xls.TextCellValue(Formatters.getEstadoText(r.estado)),
        ]);
      }
      final bytes = excel.encode();
      if (bytes == null) return;
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      final filePath =
          '${directory.path}/reservas_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo guardado en Descargas')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error exportando: $e')));
      }
    }
  }

  void _guardarNuevoPrecio() async {
    final input = _precioController.text.trim();
    final nuevoPrecio = double.tryParse(input);
    if (nuevoPrecio == null || nuevoPrecio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un precio válido (p.ej. 55.50)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      await context.read<ConfiguracionController>().actualizarPrecio(
            nuevoPrecio,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precio actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _editandoPrecio = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando precio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRightControls() {
    final configuracion = context.watch<ConfiguracionController>().configuracion;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          ///aqui muestra el numero de reservas
          child: Text(
            '${_currentReservas.length} reserva${_currentReservas.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Botón para exportar a Excel
        ElevatedButton(
          onPressed: () => _exportToExcel(_currentReservas),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
          ),
          child: const Icon(Icons.file_download, color: Colors.white, size: 24),
        ),
        /// Botón para editar el precio
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _editandoPrecio
                ? SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _precioController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      onSubmitted: (_) => _guardarNuevoPrecio(),
                    ),
                  )
                : Text(
                    'Costo por asiento: ${configuracion != null ? configuracion.precioPorAsiento.toStringAsFixed(2) : '0.00'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            IconButton(
              icon: Icon(_editandoPrecio ? Icons.check : Icons.edit),
              onPressed: () {
                if (_editandoPrecio) {
                  _guardarNuevoPrecio();
                } else {
                  setState(() {
                    _precioController.text =
                        (configuracion?.precioPorAsiento.toStringAsFixed(2) ??
                            '0.00');
                    _editandoPrecio = true;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
