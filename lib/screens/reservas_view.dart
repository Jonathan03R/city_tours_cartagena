import 'dart:io';

import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/mvvc/configuracion_controller.dart';
import 'package:citytourscartagena/core/services/configuracion_service.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
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
  List<ReservaConAgencia> _reservas = [];
  DateFilterType _selectedFilter = DateFilterType.today;
  DateTime? _customDate;
  bool _isTableView = true;
  bool _isLoading = true;
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

  Future<void> _loadReservas() async {
    setState(() => _isLoading = true);
    try {
      // 1) Obtengo todas las reservas que cumplen el filtro de fecha
      List<ReservaConAgencia> reservas;
      switch (_selectedFilter) {
        case DateFilterType.all:
          reservas = await ReservasController.getAllReservas();
          break;
        case DateFilterType.today:
          reservas = await ReservasController.getReservasByFecha(
            DateTime.now(),
          );
          break;
        case DateFilterType.tomorrow:
          reservas = await ReservasController.getReservasByFecha(
            DateTime.now().add(const Duration(days: 1)),
          );
          break;
        case DateFilterType.lastWeek:
          reservas = await ReservasController.getReservasLastWeek();
          break;
        case DateFilterType.custom:
          if (_customDate != null) {
            reservas = await ReservasController.getReservasByFecha(
              _customDate!,
            );
          } else {
            reservas = [];
          }
          break;
      }

      // 2) Si vengo con una agencia concreta, aplico el filtro adicional
      if (widget.agenciaId != null) {
        reservas = reservas
            .where((r) => r.agencia.id == widget.agenciaId)
            .toList();
      }

      setState(() {
        _reservas = reservas;
        _isLoading = false;
      });
      debugPrint('🔄 Reservas cargadas en vista: ${_reservas.length}');
    } catch (e) {
      debugPrint('❌ Error cargando reservas: $e');
      setState(() {
        _reservas = [];
        _isLoading = false;
      });
    }
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservas,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de fecha (solo si no es vista de agencia específica)
          // if (widget.agenciaId == null)
          DateFilterButtons(
            selectedFilter: _selectedFilter,
            customDate: _customDate,
            onFilterChanged: _onFilterChanged,
          ),

          // Contador de reservas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth >= 600;
                return isWide
                    // ancho amplio: título y controles en Row
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
                    // ancho estrecho: título arriba, controles abajo
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
          // Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: Text(
          //     _getFilterTitle(),
          //     style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          //   ),
          // ),
          // Vista de contenido
          Expanded(
            child: _isLoading
                // mientras cargas
                ? const Center(child: CircularProgressIndicator())
                // ya cargaste, ahora decides tabla o lista
                : _isTableView
                ? ReservasTable(reservas: _reservas, onUpdate: _loadReservas)
                : _reservas.isEmpty
                ? const Center(child: Text('No hay reservas'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservas.length,
                    itemBuilder: (ctx, i) {
                      return ReservaCardItem(
                        reserva: _reservas[i],
                        onTap: () => _showReservaDetails(_reservas[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.agenciaId == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón Modo Pro
                FloatingActionButton.extended(
                  onPressed: _showAddReservaProForm,
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('registro rapido'),
                  heroTag: "pro_button",
                ),
                const SizedBox(height: 16),
                // Botón normal
                FloatingActionButton(
                  onPressed: _showAddReservaForm,
                  backgroundColor: Colors.blue.shade600,
                  heroTag: "normal_button",
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }

  // String _getFilterTitle() {
  //   switch (_selectedFilter) {
  //     case DateFilterType.all:
  //       return 'Todas las reservas';
  //     case DateFilterType.today:
  //       return 'Reservas de hoy';
  //     case DateFilterType.tomorrow:
  //       return 'Reservas de mañana';
  //     case DateFilterType.lastWeek:
  //       return 'Reservas de la última semana';
  //     case DateFilterType.custom:
  //       return _customDate != null
  //           ? 'Reservas del ${_customDate!.day}/${_customDate!.month}/${_customDate!.year}'
  //           : 'Fecha personalizada';
  //   }
  // }

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
      // Pedir permiso
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

      // 2. Crear Excel
      final excel = xls.Excel.createExcel();
      final sheet = excel['Reservas'];

      // Cabeceras
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

      // Filas
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

      // 3. Codificar
      final bytes = excel.encode();
      if (bytes == null) return;

      // 4. Ruta pública en Descargas
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final filePath =
          '${directory.path}/reservas_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // 5. Confirmación
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
    // configuation extraída con Provider.watch ya en build()
    final configuracion = context
        .watch<ConfiguracionController>()
        .configuracion;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        // contador
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${_reservas.length} reserva${_reservas.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // exportar Excel
        ElevatedButton(
          onPressed: () => _exportToExcel(_reservas),
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
        // costo + edit
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
                    // Aquí metemos el value con dos decimales, no entero:
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
