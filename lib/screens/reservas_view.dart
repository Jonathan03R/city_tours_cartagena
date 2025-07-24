import 'dart:io';

import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart' hide AgenciaConReservas; // Mantener si es intencional
import 'package:citytourscartagena/core/mvvc/agencias_controller.dart'; // Importar AgenciasController para _editarAgencia
import 'package:citytourscartagena/core/mvvc/configuracion_controller.dart';
// import 'package:citytourscartagena/core/services/configuracion_service.dart'; // Ya no es necesario importar directamente
// import 'package:citytourscartagena/core/services/firestore_service.dart'; // Ya no es necesario importar directamente
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/add_reserva_form.dart';
import 'package:citytourscartagena/core/widgets/crear_agencia_form.dart';
import 'package:citytourscartagena/core/widgets/table_only_view_screen.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../core/mvvc/reservas_controller.dart';
import '../core/widgets/add_reserva_pro_form.dart';
import '../core/widgets/date_filter_buttons.dart';
import '../core/widgets/reserva_card_item.dart';
import '../core/widgets/reserva_details.dart';
import '../core/widgets/reservas_table.dart';

class ReservasView extends StatefulWidget {
  final AgenciaConReservas? agencia;
  const ReservasView({super.key, this.agencia});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  // Eliminamos el estado local de reservas y filtros, ahora lo gestiona ReservasController
  // List<ReservaConAgencia> _currentReservas = [];
  // Stream<List<ReservaConAgencia>>? _reservasStream;
  // DateFilterType _selectedFilter = DateFilterType.today;
  // DateTime? _customDate;
  // Configuracion? _configuracion; // ConfiguracionController ya lo provee

  bool _isTableView = true;
  bool _editandoPrecio = false;
  final TextEditingController _precioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar el filtro del controlador al inicio
    // Usamos addPostFrameCallback para asegurar que el contexto esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reservasController = Provider.of<ReservasController>(context, listen: false);
      reservasController.updateFilter(
        DateFilterType.today, // Filtro inicial por defecto
        agenciaId: widget.agencia?.id, // Si es una vista de agencia específica
      );
    });
  }

  // Eliminamos _loadConfiguracion() y _loadReservas()
  // La lógica de carga y filtrado ahora está en ReservasController

  void _onFilterChanged(DateFilterType filter, DateTime? date) {
    // Delegar el cambio de filtro al controlador
    Provider.of<ReservasController>(context, listen: false).updateFilter(
      filter,
      date: date,
      agenciaId: widget.agencia?.id,
    );
  }

  void _showTableOnlyView() {
    final reservasController = Provider.of<ReservasController>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TableOnlyViewScreen(
          selectedFilter: reservasController.selectedFilter, // Obtener del controlador
          customDate: reservasController.customDate, // Obtener del controlador
          agenciaId: widget.agencia?.id,
          onUpdate: () {
            // Al volver de la vista de tabla, recargar las reservas a través del controlador
            reservasController.updateFilter(
              reservasController.selectedFilter,
              date: reservasController.customDate,
              agenciaId: widget.agencia?.id,
            );
          },
        ),
      ),
    );
  }

  void _editarAgencia() {
    final agencia = widget.agencia!;
    showDialog(
      context: context,
      builder: (_) => CrearAgenciaForm(
        initialNombre: agencia.nombre,
        initialImagenUrl: agencia.imagenUrl, // Pasar la URL actual de la imagen
        initialPrecioPorAsiento: agencia.precioPorAsiento, // NUEVO: Pasar el precio por asiento de la agencia
        onCrear: (nuevoNombre, nuevaImagenFile, nuevoPrecioPorAsiento) async { // MODIFICADO: Recibir nuevoPrecioPorAsiento
          final agenciasController = Provider.of<AgenciasController>(context, listen: false);
          await agenciasController.updateAgencia(
            agencia.id,
            nuevoNombre,
            nuevaImagenFile?.path, // Pasar la ruta del archivo si existe
            agencia.imagenUrl, // Pasar la URL actual para que el controlador decida si subir una nueva
            newPrecioPorAsiento: nuevoPrecioPorAsiento, // NUEVO: Pasar el nuevo precio
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Observar los controladores para que la UI se reconstruya con los cambios
    final reservasController = context.watch<ReservasController>();
    final configuracionController = context.watch<ConfiguracionController>();
    final configuracion = configuracionController.configuracion;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.agencia != null ? 'Reservas de Agencia' : 'Reservas',
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
          if (widget.agencia != null) ...[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _editarAgencia,
              tooltip: 'Editar agencia',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _showTableOnlyView,
            tooltip: 'Ver tabla completa',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Recargar las reservas forzando una actualización del filtro actual
              reservasController.updateFilter(
                reservasController.selectedFilter,
                date: reservasController.customDate,
                agenciaId: widget.agencia?.id,
              );
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            DateFilterButtons(
              selectedFilter: reservasController.selectedFilter, // Obtener del controlador
              customDate: reservasController.customDate, // Obtener del controlador
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
                                _getFilterTitle(reservasController.selectedFilter, reservasController.customDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            _buildRightControls(reservasController.currentReservas, configuracion),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getFilterTitle(reservasController.selectedFilter, reservasController.customDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRightControls(reservasController.currentReservas, configuracion),
                          ],
                        );
                },
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
                final currentReservas = snapshot.data ?? []; // Obtener la lista del snapshot
                if (currentReservas.isEmpty) {
                  // _currentReservas = []; // Ya no es necesario, la lista viene del snapshot
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

                debugPrint('🔄 Reservas cargadas en vista: ${currentReservas.length}');

                return _isTableView
                    ? ReservasTable(
                        reservas: currentReservas, // Pasar la lista del snapshot
                        onUpdate: () {
                          // Al actualizar desde la tabla, recargar las reservas a través del controlador
                          reservasController.updateFilter(
                            reservasController.selectedFilter,
                            date: reservasController.customDate,
                            agenciaId: widget.agencia?.id,
                          );
                        },
                        currentFilter: reservasController.selectedFilter, // Pasar del controlador
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: currentReservas.length,
                        itemBuilder: (ctx, i) {
                          return ReservaCardItem(
                            reserva: currentReservas[i],
                            onTap: () => _showReservaDetails(currentReservas[i]),
                          );
                        },
                      );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: widget.agencia == null
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
              ],
            )
          : null,
    );
  }

  // Este método ahora recibe los parámetros del controlador
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

  void _showReservaDetails(ReservaConAgencia reserva) {
    final reservasController = Provider.of<ReservasController>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          ReservaDetails(reserva: reserva, onUpdate: () {
            // Al actualizar desde los detalles, recargar las reservas a través del controlador
            reservasController.updateFilter(
              reservasController.selectedFilter,
              date: reservasController.customDate,
              agenciaId: widget.agencia?.id,
            );
          }),
    );
  }

  void _showAddReservaForm() {
    final reservasController = Provider.of<ReservasController>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaForm(onAdd: () {
        // Al añadir una reserva, recargar las reservas a través del controlador
        reservasController.updateFilter(
          reservasController.selectedFilter,
          date: reservasController.customDate,
          agenciaId: widget.agencia?.id,
        );
      }),
    );
  }

  void _showAddReservaProForm() {
    final reservasController = Provider.of<ReservasController>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaProForm(onAdd: () {
        // Al añadir una reserva, recargar las reservas a través del controlador
        reservasController.updateFilter(
          reservasController.selectedFilter,
          date: reservasController.customDate,
          agenciaId: widget.agencia?.id,
        );
      }),
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

  // Este método ahora recibe la configuración como parámetro
  void _guardarNuevoPrecio(Configuracion? configuracion) async {
    final input = _precioController.text.trim();
    final nuevoPrecio = double.tryParse(input); // Ojo: aquí deberíamos usar ParserUtils.parseDouble
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
      // Si estamos en la vista de una agencia, actualizamos el precio de la agencia
      if (widget.agencia != null) {
        final agenciasController = Provider.of<AgenciasController>(context, listen: false);
        await agenciasController.updateAgencia(
          widget.agencia!.id,
          widget.agencia!.nombre, // Mantener el nombre actual
          null, // No cambiar la imagen desde aquí
          widget.agencia!.imagenUrl, // Mantener la URL de imagen actual
          newPrecioPorAsiento: nuevoPrecio,
        );
      } else {
        // Si no, actualizamos el precio global de configuración
        await Provider.of<ConfiguracionController>(context, listen: false).actualizarPrecio(
          nuevoPrecio,
        );
      }

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

  // Este método ahora recibe las reservas y la configuración como parámetros
  Widget _buildRightControls(List<ReservaConAgencia> currentReservas, Configuracion? configuracion) {
    // Determinar qué precio mostrar: el de la agencia si existe, o el global
    final double? displayedPrice = widget.agencia?.precioPorAsiento ?? configuracion?.precioPorAsiento;
    final String priceLabel = widget.agencia != null ? 'Costo por asiento (Agencia)' : 'Costo por asiento (Global)';

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
          child: Text(
            '${currentReservas.length} reserva${currentReservas.length != 1 ? 's' : ''}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => _exportToExcel(currentReservas),
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
                      onSubmitted: (_) => _guardarNuevoPrecio(configuracion),
                    ),
                  )
                : Text(
                    '$priceLabel: ${displayedPrice != null ? displayedPrice.toStringAsFixed(2) : '0.00'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            IconButton(
              icon: Icon(_editandoPrecio ? Icons.check : Icons.edit),
              onPressed: () {
                if (_editandoPrecio) {
                  _guardarNuevoPrecio(configuracion);
                } else {
                  setState(() {
                    // Inicializar el controlador con el precio correcto (agencia o global)
                    _precioController.text = (displayedPrice?.toStringAsFixed(2) ?? '0.00');
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
