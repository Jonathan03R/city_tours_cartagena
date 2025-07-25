import 'dart:async';
import 'dart:io';

import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart'
    hide AgenciaConReservas; // Mantener si es intencional
import 'package:citytourscartagena/core/mvvc/agencias_controller.dart'; // Importar AgenciasController para _editarAgencia
import 'package:citytourscartagena/core/mvvc/configuracion_controller.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/crear_agencia_form.dart';
import 'package:citytourscartagena/core/widgets/table_only_view_screen.dart';
import 'package:citytourscartagena/core/widgets/turno_filter_button.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/mvvc/reservas_controller.dart';
import '../../core/widgets/add_reserva_pro_form.dart';
import '../../core/widgets/date_filter_buttons.dart'; // Importar DateFilterType
import '../../core/widgets/reserva_card_item.dart'; // CORREGIDO: Añadido .dart
import '../../core/widgets/reserva_details.dart';
import '../../core/widgets/reservas_table.dart';

class ReservasView extends StatefulWidget {
  final TurnoType? turno;
  final AgenciaConReservas? agencia;
  final VoidCallback? onBack;
  const ReservasView({super.key, this.turno, this.agencia, this.onBack});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  bool _isTableView = true;
  bool _editandoPrecio = false;
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _precioMananaController = TextEditingController();
  final TextEditingController _precioTardeController = TextEditingController();
  // Mantener agencia local para reflejar cambios inmediatos
  AgenciaConReservas? _currentAgencia;
  StreamSubscription<List<AgenciaConReservas>>? _agenciasSub;

  @override
  void initState() {
    super.initState();

    // inicializar agencia local
    _currentAgencia = widget.agencia;

    // Suscribirse para recibir actualizaciones de AgenciasController en tiempo real
    final agenciasCtrl = context.read<AgenciasController>();


    _agenciasSub = agenciasCtrl.agenciasConReservasStream.listen((lista) {
      if (widget.agencia != null) {
        final updated = lista.firstWhereOrNull(
          (ar) => ar.agencia.id == widget.agencia!.agencia.id,
        );
      if (updated != null && mounted) {
          setState(() {
            _currentAgencia = updated;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = Provider.of<ReservasController>(context, listen: false);
      ctrl.updateFilter(
        DateFilterType.today,
        agenciaId: widget.agencia?.id,
        turno: widget.turno,
      );
    });
  }

  /// Método para manejar cambios en los filtros
  void _onFilterChanged(
    DateFilterType filter,
    DateTime? date, {
    TurnoType? turno,
  }) {
    final ctrl = Provider.of<ReservasController>(context, listen: false);
    ctrl.updateFilter(
      filter,
      date: date,
      agenciaId: widget.agencia?.id,
      // si me llegan turno==null, uso el que ya está en el controlador
      turno: turno ?? ctrl.turnoFilter,
    );
  }

  /// Método para mostrar el formulario de reserva rápida
  void _showTableOnlyView() {
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TableOnlyViewScreen(
          turno: widget.turno,
          selectedFilter:
              reservasController.selectedFilter, // Obtener del controlador
          customDate: reservasController.customDate, // Obtener del controlador
          agenciaId: widget.agencia?.id,
          onUpdate: () {
            // Al volver de la vista de tabla, recargar las reservas a través del controlador
            reservasController.updateFilter(
              reservasController.selectedFilter,
              date: reservasController.customDate,
              agenciaId: widget.agencia?.id,
              turno: widget.turno,
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
        initialImagenUrl: agencia.imagenUrl,
        initialPrecioPorAsientoTurnoManana: agencia.precioPorAsientoTurnoManana,
        initialPrecioPorAsientoTurnoTarde: agencia.precioPorAsientoTurnoTarde,
        onCrear:
            (
              nuevoNombre,
              nuevaImagenFile,
              nuevoPrecioManana,
              nuevoPrecioTarde,
            ) async {
              final agenciasController = Provider.of<AgenciasController>(
                context,
                listen: false,
              );
              await agenciasController.updateAgencia(
                agencia.id,
                nuevoNombre,
                nuevaImagenFile?.path,
                agencia.imagenUrl,
                newPrecioPorAsientoTurnoManana: nuevoPrecioManana,
                newPrecioPorAsientoTurnoTarde: nuevoPrecioTarde,
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
        leading: widget.onBack != null && widget.agencia == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        automaticallyImplyLeading: widget.onBack == null,
        title: widget.agencia != null
            ? Text(
                'Reservas de ${widget.agencia!.nombre}', // Solo el nombre en el AppBar
                overflow: TextOverflow.ellipsis,
              )
            : const Text('Reservas'),
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
                turno: reservasController
                    .turnoFilter, // Usar el turno actual del controlador
              );
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TurnoFilterButtons(
              selectedTurno: reservasController.turnoFilter,
              onTurnoChanged: (nuevoTurno) {
                reservasController.updateFilter(
                  reservasController.selectedFilter,
                  date: reservasController.customDate,
                  agenciaId: widget.agencia?.id,
                  turno: nuevoTurno,
                );
              },
            ),
            // Nuevo widget de botones de filtro compactos
            CompactDateFilterButtons(
              selectedFilter: reservasController.selectedFilter,
              customDate: reservasController.customDate,
              selectedTurno: reservasController
                  .turnoFilter, // Pasar el turno actual del controlador
              onFilterChanged: _onFilterChanged,
            ),
            // NUEVO: Encabezado de agencia si aplica
            if (widget.agencia != null) _buildAgencyHeader(widget.agencia!),
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
                                _getFilterTitle(
                                  reservasController.selectedFilter,
                                  reservasController.customDate,
                                  reservasController
                                      .turnoFilter, // Pasar el turno al título
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            _buildRightControls(
                              reservasController.currentReservas,
                              configuracion,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRightControls(
                              reservasController.currentReservas,
                              configuracion,
                            ),
                            Text(
                              _getFilterTitle(
                                reservasController.selectedFilter,
                                reservasController.customDate,
                                reservasController
                                    .turnoFilter, // Pasar el turno al título
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                },
              ),
            ),
            StreamBuilder<List<ReservaConAgencia>>(
              stream: reservasController
                  .filteredReservasStream, // Usar el stream del controlador
              builder: (context, snapshot) {
                // if (reservasController.isFetchingPage &&
                //     snapshot.data == null) {
                //   return const Center(child: CircularProgressIndicator());
                // }
                if (reservasController.isFetchingPage) {
                  // Mientras esté cargando, siempre muestro el spinner
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final currentReservas =
                    snapshot.data ?? []; // Obtener la lista del snapshot

                if (currentReservas.isEmpty &&
                    !reservasController.isFetchingPage) {
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

                // debugPrint(
                //   '🔄 Reservas cargadas en vista: ${currentReservas.length}',
                // );

                return Column(
                  children: [
                    _isTableView
                        ? ReservasTable(
                            turno: reservasController
                                .turnoFilter, // Pasar el turno si aplica
                            reservas:
                                currentReservas, // Pasar la lista paginada
                            onUpdate: () {
                              // Al actualizar desde la tabla, recargar las reservas a través del controlador
                              reservasController.updateFilter(
                                reservasController.selectedFilter,
                                date: reservasController.customDate,
                                agenciaId: widget.agencia?.id,
                                turno: reservasController
                                    .turnoFilter, // Usar el turno actual del controlador
                              );
                            },
                            currentFilter: reservasController
                                .selectedFilter, // Pasar del controlador
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: currentReservas.length,
                            itemBuilder: (ctx, i) {
                              return ReservaCardItem(
                                reserva: currentReservas[i],
                                onTap: () =>
                                    _showReservaDetails(currentReservas[i]),
                              );
                            },
                          ),
                    // Controles de paginación
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botón Anterior
                          ElevatedButton(
                            onPressed:
                                reservasController.canGoPrevious &&
                                    !reservasController.isFetchingPage
                                ? reservasController.previousPage
                                : null,
                            child:
                                reservasController.isFetchingPage &&
                                    reservasController.canGoPrevious
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Anterior'),
                          ),
                          const SizedBox(width: 16),
                          // Indicador de página actual
                          Text(
                            'Página ${reservasController.currentPage}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Botón Siguiente
                          ElevatedButton(
                            onPressed:
                                reservasController.canGoNext &&
                                    !reservasController.isFetchingPage
                                ? reservasController.nextPage
                                : null,
                            child:
                                reservasController.isFetchingPage &&
                                    reservasController.canGoNext
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Siguiente'),
                          ),
                        ],
                      ),
                    ),
                    // Selector de elementos por página
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Elementos por página:'),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: reservasController.itemsPerPage,
                            items: const [10, 20, 50].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                reservasController.setItemsPerPage(newValue);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
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

  // NUEVO: Widget para mostrar la información de la agencia
  Widget _buildAgencyHeader(AgenciaConReservas agencia) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (agencia.imagenUrl != null && agencia.imagenUrl!.isNotEmpty)
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(agencia.imagenUrl!),
              backgroundColor: Colors.grey.shade200,
            )
          else
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.shade100,
              child: Icon(
                Icons.business,
                size: 50,
                color: Colors.green.shade600,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agencia.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${agencia.totalReservas} reserva${agencia.totalReservas != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Este método ahora recibe los parámetros del controlador
  String _getFilterTitle(
    DateFilterType selectedFilter,
    DateTime? customDate,
    TurnoType? selectedTurno,
  ) {
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

    String dateText;
    switch (selectedFilter) {
      case DateFilterType.all:
        dateText = 'Todas las reservas';
        break;
      case DateFilterType.lastWeek:
        dateText = 'Reservas de la última semana';
        break;
      case DateFilterType.today:
        dateText = formatearFecha(DateTime.now());
        break;
      case DateFilterType.yesterday:
        dateText = formatearFecha(
          DateTime.now().subtract(const Duration(days: 1)),
        );
        break;
      case DateFilterType.tomorrow:
        dateText = formatearFecha(DateTime.now().add(const Duration(days: 1)));
        break;
      case DateFilterType.custom:
        dateText = customDate != null
            ? formatearFecha(customDate)
            : 'Fecha personalizada';
        break;
    }

    String turnoText = '';
    if (selectedTurno != null) {
      turnoText = selectedTurno == TurnoType.manana ? ' (Mañana)' : ' (Tarde)';
    }
    return '$dateText$turnoText';
  }

  void _showReservaDetails(ReservaConAgencia reserva) {
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReservaDetails(
        reserva: reserva,
        onUpdate: () {
          // Al actualizar desde los detalles, recargar las reservas a través del controlador
          reservasController.updateFilter(
            reservasController.selectedFilter,
            date: reservasController.customDate,
            agenciaId: widget.agencia?.id,
            turno: reservasController
                .turnoFilter, // Usar el turno actual del controlador
          );
        },
      ),
    );
  }

  void _showAddReservaProForm() {
    // Usar el controlador de reservas para manejar la lógica de añadir reservas
    // Esto asegura que la lógica de negocio esté centralizada y evita duplicación de código
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );

    /// showModalBottomSheet es una función que muestra un modal en la parte inferior de la pantalla
    /// context es el contexto actual de la aplicación
    /// isScrollControlled permite que el modal ocupe todo el espacio disponible
    /// builder es una función que construye el contenido del modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      /// AddReservaProForm es un widget que muestra el formulario de reserva rápida
      /// onAdd es una función que se llama cuando se añade una nueva reserva
      builder: (context) => AddReservaProForm(
        turno: widget.turno!,
        onAdd: () {
          // Al añadir una reserva, recargar las reservas a través del controlador
          reservasController.updateFilter(
            reservasController.selectedFilter,
            date: reservasController.customDate,
            agenciaId: widget.agencia?.id,
            turno: reservasController
                .turnoFilter, // Usar el turno actual del controlador
          );
        },
      ),
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
    // Si se edita precios de agencia
    if (widget.agencia != null) {
      final agenciasController = Provider.of<AgenciasController>(
        context,
        listen: false,
      );
      final mText = _precioMananaController.text.trim();
      final tText = _precioTardeController.text.trim();
      final double? manana = mText.isEmpty ? null : double.tryParse(mText);
      final double? tarde = tText.isEmpty ? null : double.tryParse(tText);
      // validar solo si hay texto, de lo contrario dejamos null para heredar global
      if ((mText.isNotEmpty && (manana == null || manana <= 0)) ||
          (tText.isNotEmpty && (tarde == null || tarde <= 0))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ingresa precios válidos o deja vacío para usar global',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      try {
        await agenciasController.updateAgencia(
          widget.agencia!.id,
          widget.agencia!.nombre,
          null,
          widget.agencia!.imagenUrl,
          newPrecioPorAsientoTurnoManana: manana,
          newPrecioPorAsientoTurnoTarde: tarde,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Precio de agencia actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        // actualizar agencia local para refrescar UI
        setState(() {
          final old = _currentAgencia ?? widget.agencia!;
          final updatedAg = old.agencia.copyWith(
            precioPorAsientoTurnoManana: manana,
            precioPorAsientoTurnoTarde: tarde,
          );
          _currentAgencia = AgenciaConReservas(
            agencia: updatedAg,
            totalReservas: old.totalReservas,
          );
          _editandoPrecio = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando precio de agencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Si no hay agencia, actualizamos precio global
    final input = _precioController.text.trim();
    final nuevoPrecio = double.tryParse(input);
    if (nuevoPrecio == null || nuevoPrecio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor ingresa un precio global válido (p.ej. 55.50)',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      await Provider.of<ConfiguracionController>(
        context,
        listen: false,
      ).actualizarPrecio(nuevoPrecio);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Precio global actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _editandoPrecio = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando precio global: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Este método ahora recibe las reservas y la configuración como parámetros
  Widget _buildRightControls(
    List<ReservaConAgencia> currentReservas,
    Configuracion? configuracion,
  ) {
    // final ag = widget.agencia?.agencia;
    final ac = _currentAgencia ?? widget.agencia;
    final ag = ac?.agencia;
    // obtener el turno filtrado (null = ambos)
    final turnoFilter = Provider.of<ReservasController>(
      context,
      listen: false,
    ).turnoFilter;
    // para agencia, decidir qué turno mostrar
    final showManana =
        ag != null && (turnoFilter == null || turnoFilter == TurnoType.manana);
    final showTarde =
        ag != null && (turnoFilter == null || turnoFilter == TurnoType.tarde);
    // precio global único
    final double? globalPrice = configuracion?.precioPorAsiento;

    return Container(
      // ... decoración ...
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------
          // Reservas y botón export
          // -----------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ... información de reservas ...
              ElevatedButton.icon(
                onPressed: () => _exportToExcel(currentReservas),
                icon: const Icon(Icons.file_download, size: 20),
                label: const Text("Exportar"),
                // ... estilo ...
              ),
            ],
          ),
          const SizedBox(height: 12),

          // -----------------------
          // Precio editable según contexto
          // -----------------------
          if (ag != null) ...[
            // mostrar precio Mañana / Tarde según turnoFilter
            if (showManana)
              Text(
                'Costo por asiento (Mañana): ${(ag.precioPorAsientoTurnoManana ?? globalPrice)?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (showTarde)
              Text(
                'Costo por asiento (Tarde): ${(ag.precioPorAsientoTurnoTarde ?? globalPrice)?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

            // campos de edición según turnoFilter
            if (_editandoPrecio) ...[
              if (showManana) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _precioMananaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo precio mañana',
                    hintText: 'vacío = usar global',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (showTarde) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _precioTardeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nuevo precio tarde',
                    hintText: 'vacío = usar global',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
            Align(
              alignment: Alignment.centerRight,
              child: _editandoPrecio
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade600),
                          tooltip: 'Cancelar',
                          onPressed: () {
                            setState(() {
                              _editandoPrecio = false;
                              _precioMananaController.clear();
                              _precioTardeController.clear();
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.grey.shade800),
                          tooltip: 'Guardar',
                          onPressed: () => _guardarNuevoPrecio(configuracion),
                        ),
                      ],
                    )
                  : IconButton(
                      icon: Icon(Icons.edit, color: Colors.grey.shade800),
                      tooltip: 'Editar precios',
                      onPressed: () {
                        setState(() {
                          _precioMananaController.text =
                              ag.precioPorAsientoTurnoManana != null
                              ? ag.precioPorAsientoTurnoManana!.toStringAsFixed(
                                  2,
                                )
                              : '';
                          _precioTardeController.text =
                              ag.precioPorAsientoTurnoTarde != null
                              ? ag.precioPorAsientoTurnoTarde!.toStringAsFixed(
                                  2,
                                )
                              : '';
                          _editandoPrecio = true;
                        });
                      },
                    ),
            ),
          ] else ...[
            // precio global único
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.attach_money, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: _editandoPrecio
                      ? TextField(
                          controller: _precioController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) =>
                              _guardarNuevoPrecio(configuracion),
                        )
                      : Text(
                          'Costo por asiento (Global): ${globalPrice?.toStringAsFixed(2) ?? '0.00'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                IconButton(
                  icon: Icon(
                    _editandoPrecio ? Icons.check : Icons.edit,
                    color: Colors.grey.shade800,
                  ),
                  onPressed: () {
                    if (_editandoPrecio) {
                      _guardarNuevoPrecio(configuracion);
                    } else {
                      setState(() {
                        _precioController.text =
                            globalPrice?.toStringAsFixed(2) ?? '0.00';
                        _editandoPrecio = true;
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Nuevo enum para las opciones de filtro adicionales
enum MoreFilterOption { yesterday, tomorrow, lastWeek }

// Nuevo widget para los botones de filtro compactos
class CompactDateFilterButtons extends StatelessWidget {
  final DateFilterType selectedFilter;
  final DateTime? customDate;
  final TurnoType? selectedTurno;
  final Function(DateFilterType, DateTime?, {TurnoType? turno}) onFilterChanged;

  const CompactDateFilterButtons({
    super.key,
    required this.selectedFilter,
    this.customDate,
    this.selectedTurno,
    required this.onFilterChanged,
  });

  String _getButtonText(DateFilterType filter, DateTime? date) {
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
      return '${fecha.day} de ${meses[fecha.month - 1]}';
    }

    switch (filter) {
      case DateFilterType.all:
        return 'Todas';
      case DateFilterType.today:
        return 'Hoy';
      case DateFilterType.yesterday:
        return 'Ayer';
      case DateFilterType.tomorrow:
        return 'Mañana';
      case DateFilterType.lastWeek:
        return 'Última Semana';
      case DateFilterType.custom:
        return date != null ? formatearFecha(date) : 'Fecha Específica';
    }
  }

  String _getMoreFilterOptionText(MoreFilterOption option) {
    switch (option) {
      case MoreFilterOption.yesterday:
        return 'Ayer';
      case MoreFilterOption.tomorrow:
        return 'Mañana';
      case MoreFilterOption.lastWeek:
        return 'Última Semana';
      // case MoreFilterOption.turnoManana:
      //   return 'Turno Mañana';
      // case MoreFilterOption.turnoTarde:
      //   return 'Turno Tarde';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determinar si el botón "Más filtros" debe estar seleccionado
    final isMoreFiltersSelected =
        // selectedTurno != null ||
        selectedFilter == DateFilterType.yesterday ||
        selectedFilter == DateFilterType.tomorrow ||
        selectedFilter == DateFilterType.lastWeek;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton(
            context,
            DateFilterType.today,
            _getButtonText(DateFilterType.today, null),
            selectedFilter == DateFilterType.today,
            // selectedFilter == DateFilterType.today &&
            // selectedTurno == null, // Solo hoy, sin turno
            onPressed: () =>
                onFilterChanged(DateFilterType.today, null, turno: null),
          ),
          _buildFilterButton(
            context,
            DateFilterType.all,
            _getButtonText(DateFilterType.all, null),
            selectedFilter == DateFilterType.all,
            // selectedFilter == DateFilterType.all &&
            //     selectedTurno == null, // Solo todas, sin turno
            onPressed: () =>
                onFilterChanged(DateFilterType.all, null, turno: null),
          ),
          _buildFilterButton(
            context,
            DateFilterType.custom,
            customDate != null
                ? _getButtonText(DateFilterType.custom, customDate)
                : 'Fecha Específica',
            selectedFilter == DateFilterType.custom,
            // selectedFilter == DateFilterType.custom &&
            //     selectedTurno == null, // Solo fecha específica, sin turno
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: customDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                onFilterChanged(DateFilterType.custom, pickedDate, turno: null);
              }
            },
          ),
          PopupMenuButton<MoreFilterOption>(
            onSelected: (MoreFilterOption item) {
              switch (item) {
                case MoreFilterOption.yesterday:
                  onFilterChanged(
                    DateFilterType.yesterday,
                    null,
                    turno: null,
                  ); // Sobrescribe turno
                  break;
                case MoreFilterOption.tomorrow:
                  onFilterChanged(
                    DateFilterType.tomorrow,
                    null,
                    turno: null,
                  ); // Sobrescribe turno
                  break;
                case MoreFilterOption.lastWeek:
                  onFilterChanged(
                    DateFilterType.lastWeek,
                    null,
                    turno: null,
                  ); // Sobrescribe turno
                  break;
                // case MoreFilterOption.turnoManana:
                //   // Aplica turno al filtro de fecha actual
                //   onFilterChanged(
                //     selectedFilter,
                //     customDate,
                //     turno: TurnoType.manana,
                //   );
                //   break;
                // case MoreFilterOption.turnoTarde:
                //   // Aplica turno al filtro de fecha actual
                //   onFilterChanged(
                //     selectedFilter,
                //     customDate,
                //     turno: TurnoType.tarde,
                //   );
                //   break;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<MoreFilterOption>>[
                  PopupMenuItem<MoreFilterOption>(
                    value: MoreFilterOption.yesterday,
                    child: Text(
                      _getMoreFilterOptionText(MoreFilterOption.yesterday),
                    ),
                  ),
                  PopupMenuItem<MoreFilterOption>(
                    value: MoreFilterOption.tomorrow,
                    child: Text(
                      _getMoreFilterOptionText(MoreFilterOption.tomorrow),
                    ),
                  ),
                  PopupMenuItem<MoreFilterOption>(
                    value: MoreFilterOption.lastWeek,
                    child: Text(
                      _getMoreFilterOptionText(MoreFilterOption.lastWeek),
                    ),
                  ),
                  // const PopupMenuDivider(),
                  // PopupMenuItem<MoreFilterOption>(
                  //   value: MoreFilterOption.turnoManana,
                  //   child: Text(
                  //     _getMoreFilterOptionText(MoreFilterOption.turnoManana),
                  //   ),
                  // ),
                  // PopupMenuItem<MoreFilterOption>(
                  //   value: MoreFilterOption.turnoTarde,
                  //   child: Text(
                  //     _getMoreFilterOptionText(MoreFilterOption.turnoTarde),
                  //   ),
                  // ),
                ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMoreFiltersSelected
                    ? Colors.blue.shade600
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMoreFiltersSelected
                      ? Colors.blue.shade200
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: isMoreFiltersSelected ? Colors.white : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Más filtros',
                    style: TextStyle(
                      color: isMoreFiltersSelected ? Colors.white : Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    DateFilterType filterType,
    String text,
    bool isSelected, {
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Colors.blue.shade600
                : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: isSelected ? 4 : 1,
            minimumSize: const Size(0, 40), // Altura mínima para botones
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
