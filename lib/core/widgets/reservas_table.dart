import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReservasTable extends StatefulWidget {
  final List<ReservaConAgencia> reservas;
  final VoidCallback onUpdate;
  final DateFilterType currentFilter;
  final TurnoType? turno;
  final String? agenciaId;
  final DateTime? lastSeenReservas; // <-- NUEVO
  final String? reservaIdNotificada; // <-- NUEVO
  const ReservasTable({
    super.key,
    required this.reservas,
    required this.onUpdate,
    required this.currentFilter,
    required this.turno,
    required this.agenciaId,
    this.lastSeenReservas,
    this.reservaIdNotificada,
  });
  @override
  State<ReservasTable> createState() => _ReservasTableState();
}

class _ReservasTableState extends State<ReservasTable> {
  String? _editingReservaId;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, EstadoReserva> _estadoValues = {};
  final Map<String, DateTime> _fechaValues = {};
  final Map<String, String> _agenciaValues = {};
  late ReservasController _controller;

  final ScrollController _scrollController = ScrollController();
  // removed unused GlobalKey _dataTableKey
  bool _retryAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToNotificatedReserva();
      });
    });
  }

  @override
  void didUpdateWidget(ReservasTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reservaIdNotificada != widget.reservaIdNotificada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToNotificatedReserva();
        });
      });
    }
  }

  void _scrollToNotificatedReserva() {
    if (widget.reservaIdNotificada == null) return;

    final reservaIndex = widget.reservas.indexWhere(
      (ra) => ra.reserva.id == widget.reservaIdNotificada,
    );

    if (reservaIndex != -1) {
      debugPrint(
        '[v0] Haciendo scroll a reserva notificada en índice: $reservaIndex',
      );

      const double rowHeight = 56.0; // Altura más precisa de cada fila
      const double headerHeight = 48.0; // Altura del header
      final double targetPosition = headerHeight + (rowHeight * reservaIndex);

      // Asegurarse de que el ScrollController esté adjunto antes de usarlo.
      if (_scrollController.hasClients) {
        final double maxScrollExtent =
            _scrollController.position.maxScrollExtent;
        final double finalPosition = targetPosition > maxScrollExtent
            ? maxScrollExtent
            : targetPosition;

        _scrollController.animateTo(
          finalPosition,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutCubic,
        );
      } else {
        debugPrint(
          '[v0] ScrollController no está adjunto aún, reintentando en next frame',
        );
        // Reintentar después de un frame corto
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            final double maxScrollExtent =
                _scrollController.position.maxScrollExtent;
            final double finalPosition = targetPosition > maxScrollExtent
                ? maxScrollExtent
                : targetPosition;
            _scrollController.animateTo(
              finalPosition,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            );
          } else {
            debugPrint(
              '[v0] Reintento: ScrollController aún no adjunto. Omitiendo animación.',
            );
          }
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Reserva de la notificación encontrada y resaltada'),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.fixed,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } else {
      debugPrint(
        '[v0] Reserva notificada no encontrada en la lista actual — intentaremos nuevamente',
      );

      // Intento único de reintento para dar tiempo a que el controlador cargue los datos
      // antes de mostrar el SnackBar de "no encontrada".
      if (!_retryAttempted && mounted) {
        _retryAttempted = true;
        Future.delayed(const Duration(milliseconds: 700), () {
          if (!mounted) return;
          final retryIndex = widget.reservas.indexWhere(
            (ra) => ra.reserva.id == widget.reservaIdNotificada,
          );
          if (retryIndex != -1) {
            // Si ahora aparece, hacer scroll hacia ella
            const double rowHeight = 56.0;
            const double headerHeight = 48.0;
            final double targetPosition =
                headerHeight + (rowHeight * retryIndex);
            if (_scrollController.hasClients) {
              final double maxScrollExtent =
                  _scrollController.position.maxScrollExtent;
              final double finalPosition = targetPosition > maxScrollExtent
                  ? maxScrollExtent
                  : targetPosition;
              _scrollController.animateTo(
                finalPosition,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
              );
            } else {
              debugPrint(
                '[v0] Retry: ScrollController aún no adjunto en retry',
              );
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text('Reserva de la notificación encontrada y resaltada'),
                  ],
                ),
                duration: const Duration(seconds: 4),
                backgroundColor: Colors.orange.shade700,
                behavior: SnackBarBehavior.fixed,
              ),
            );
            return;
          }

          // Si sigue sin aparecer, mostrar mensaje de no encontrada
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.black87, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La reserva notificada no está visible con los filtros actuales',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.amber.shade300,
              behavior: SnackBarBehavior.fixed,
              action: SnackBarAction(
                label: 'Limpiar filtros',
                textColor: Colors.black87,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startEditing(ReservaConAgencia reserva) {
    setState(() {
      _editingReservaId = reserva.id;
      _controllers['${reserva.id}_cliente'] = TextEditingController(
        text: reserva.nombreCliente,
      );
      _controllers['${reserva.id}_telefono'] = TextEditingController(
        text: reserva.telefono,
      );
      _controllers['${reserva.id}_hotel'] = TextEditingController(
        text: reserva.hotel,
      );
      _controllers['${reserva.id}_pax'] = TextEditingController(
        text: reserva.pax.toString(),
      );
      _controllers['${reserva.id}_saldo'] = TextEditingController(
        text: reserva.saldo.toString(),
      );
      _controllers['${reserva.id}_ticket'] = TextEditingController(
        text: reserva.ticket,
      );
      _controllers['${reserva.id}_habitacion'] = TextEditingController(
        text: reserva.habitacion,
      );
      _controllers['${reserva.id}_observacion'] = TextEditingController(
        text: reserva.observacion,
      );
      _estadoValues[reserva.id] = reserva.estado;
      _fechaValues[reserva.id] = reserva.fecha;
      _agenciaValues[reserva.id] = reserva.agencia.id;
    });
  }

  void _cancelEditing() {
    setState(() {
      if (_editingReservaId != null) {
        _controllers.removeWhere((key, value) {
          if (key.startsWith('${_editingReservaId}_')) {
            value.dispose();
            return true;
          }
          return false;
        });
        _estadoValues.remove(_editingReservaId);
        _fechaValues.remove(_editingReservaId);
        _agenciaValues.remove(_editingReservaId);
      }
      _editingReservaId = null;
    });
  }

  Future<void> _saveChanges() async {
    if (_editingReservaId == null) return;
    try {
      final reservaCA = widget.reservas.firstWhere(
        (r) => r.id == _editingReservaId,
      );
      final updatedReserva = reservaCA.reserva.copyWith(
        nombreCliente:
            _controllers['${_editingReservaId}_cliente']?.text ??
            reservaCA.nombreCliente,
        hotel:
            _controllers['${_editingReservaId}_hotel']?.text ?? reservaCA.hotel,
        telefono:
            _controllers['${_editingReservaId}_telefono']?.text ??
            reservaCA.telefono,
        ticket:
            _controllers['${_editingReservaId}_ticket']?.text ??
            reservaCA.ticket,
        habitacion:
            _controllers['${_editingReservaId}_habitacion']?.text ??
            reservaCA.habitacion,
        estado: _estadoValues[_editingReservaId] ?? reservaCA.estado,
        fecha: _fechaValues[_editingReservaId] ?? reservaCA.fecha,
        pax:
            int.tryParse(
              _controllers['${_editingReservaId}_pax']?.text ?? '',
            ) ??
            reservaCA.pax,
        saldo:
            double.tryParse(
              _controllers['${_editingReservaId}_saldo']?.text ?? '',
            ) ??
            reservaCA.saldo,
        agenciaId: _agenciaValues[_editingReservaId] ?? reservaCA.agencia.id,
        observacion:
            _controllers['${_editingReservaId}_observacion']?.text ??
            reservaCA.observacion,
      );
      await _controller.updateReserva(_editingReservaId!, updatedReserva);
      _cancelEditing();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _controller = Provider.of<ReservasController>(context);
    final authController = context.watch<AuthController>();
    final adicionalesActivos = context.read<ConfiguracionController>().adicionales.where((a) => a['activo'] == true).toList();

    final reservasFiltradas = widget.reservas;
    debugPrint(
      'Página recibida: ${widget.reservas.length}, a mostrar: ${reservasFiltradas.length}',
    );
    // Calcular totales normales
    int totalPax = 0;
    double totalSaldo = 0.0;
    double totalDeuda = 0.0;
    final unpaid = reservasFiltradas
        .where((ra) => ra.reserva.estado != EstadoReserva.pagada)
        .toList();
    if (widget.agenciaId != null) {
      totalPax = unpaid.fold<int>(0, (sum, ra) => sum + ra.reserva.pax);
      totalSaldo = unpaid.fold<double>(
        0.0,
        (sum, ra) => sum + ra.reserva.saldo,
      );
      totalDeuda = unpaid.fold<double>(
        0.0,
        (sum, ra) => sum + ra.reserva.deuda,
      );
    } else {
      totalPax = reservasFiltradas.fold<int>(
        0,
        (sum, ra) => sum + ra.reserva.pax,
      );
      totalSaldo = reservasFiltradas.fold<double>(
        0.0,
        (sum, ra) => sum + ra.reserva.saldo,
      );
      totalDeuda = unpaid.fold<double>(
        0.0,
        (sum, ra) => sum + ra.reserva.deuda,
      );
    }
    // Si estamos en modo selección, usar los totales de las seleccionadas
    if (_controller.isSelectionMode && _controller.selectedCount > 0) {
      totalPax = _controller.getSelectedTotalPax();
      totalSaldo = _controller.getSelectedTotalSaldo();
      totalDeuda = _controller.getSelectedTotalDeuda();
    }
    if (reservasFiltradas.isEmpty) {
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
    final showFechaColumn =
        widget.currentFilter == DateFilterType.all ||
        widget.currentFilter == DateFilterType.lastWeek;
    // Determinar si mostrar columna Turno según filtro
    final showTurnoColumn = widget.turno == null;
    // Construir las columnas dinámicamente
    // IMPORTANTE: El orden de columnas debe coincidir con el orden de DataCell en cada fila:
    // Sel, Acción, [Turno], Número, Hotel, Nombre, [Fecha], Pax, Saldo,
    // Observaciones, Agencia, Ticket, N° HB, Estatus, [Deuda], [Editar]
    final List<DataColumn> columns = [
      // Nueva columna de selección
      DataColumn(
        label: _controller.isSelectionMode
            ? Row(
                children: [
                  Checkbox(
                    value:
                        _controller.selectedCount == reservasFiltradas.length,
                    tristate: true,
                    onChanged:
                        authController.hasPermission(Permission.select_reservas)
                        ? (value) {
                            if (value == true) {
                              _controller.selectAllVisible();
                            } else {
                              _controller.clearSelection();
                            }
                          }
                        : null,
                  ),
                  Text('${_controller.selectedCount}'),
                ],
              )
            : const Text('Sel'),
      ),

      const DataColumn(label: Text('Adicionales')),
      DataColumn(label: Text('Acción')),
      if (showTurnoColumn) const DataColumn(label: Text('Turno')),
      // "Número" hace referencia al teléfono del cliente
      const DataColumn(label: Text('Número')),
      const DataColumn(label: Text('Hotel')),
      const DataColumn(label: Text('Nombre')),
      if (widget.turno == TurnoType.privado)
        const DataColumn(label: Text('Hora')),
      if (showFechaColumn) const DataColumn(label: Text('Fecha')),
      const DataColumn(label: Text('Pax')),
      const DataColumn(label: Text('Saldo')),
      const DataColumn(label: Text('Observaciones')),
      const DataColumn(label: Text('Agencia')),
      const DataColumn(label: Text('Ticket')),
      const DataColumn(label: Text('N° HB')),
      const DataColumn(label: Text('Estatus')),
      if (authController.hasPermission(Permission.ver_deuda_reservas))
        const DataColumn(label: Text('Deuda')),
      if (authController.hasPermission(Permission.edit_reserva))
        const DataColumn(label: Text('Editar')),
    ];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            /// columnsSpacing es la separación horizontal entre las columnas
            columnSpacing: 10.h,
            horizontalMargin: 16.h,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: columns,
            rows: [
              ...reservasFiltradas.map(
                (reserva) =>
                    _buildDataRow(reserva, showFechaColumn, authController, adicionalesActivos),
              ),
              // Fila de totales actualizada
              DataRow(
                color: WidgetStateProperty.all(
                  _controller.isSelectionMode && _controller.selectedCount > 0
                      ? Colors
                            .green
                            .shade100 // Verde si hay selecciones
                      : Colors.grey.shade200, // Gris normal
                ),
                cells: [
                  const DataCell(Text('')), // Celda de selección vacía
                  const DataCell(Text('')), // Adicionales
                  const DataCell(Text('')), // Celda de acción vacía
                  if (showTurnoColumn)
                    const DataCell(Text('')), // Celda de turno vacía
                  const DataCell(Text('')), // Celda de número vacía
                  const DataCell(Text('')), // Celda de hotel vacía
                  if (!showFechaColumn)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.all(8),
                        color:
                            _controller.isSelectionMode &&
                                _controller.selectedCount > 0
                            ? Colors.green.shade200
                            : Colors.blue.shade100,
                        alignment: Alignment.center,
                        child: Text(
                          _controller.isSelectionMode &&
                                  _controller.selectedCount > 0
                              ? 'SELECCIONADAS (${_controller.selectedCount})'
                              : 'TOTAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                _controller.isSelectionMode &&
                                    _controller.selectedCount > 0
                                ? Colors.green.shade800
                                : Colors.blue,
                          ),
                        ),
                      ),
                    )
                  else
                    const DataCell(Text('')),
                  if (widget.turno == TurnoType.privado) 
                    const DataCell(Text('')),

                  if (showFechaColumn)
                    DataCell(
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color:
                                  _controller.isSelectionMode &&
                                      _controller.selectedCount > 0
                                  ? Colors.green.shade200
                                  : Colors.blue.shade100,
                              alignment: Alignment.center,
                              child: Text(
                                _controller.isSelectionMode &&
                                        _controller.selectedCount > 0
                                    ? 'SELECCIONADAS (${_controller.selectedCount})'
                                    : 'TOTAL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _controller.isSelectionMode &&
                                          _controller.selectedCount > 0
                                      ? Colors.green.shade800
                                      : const Color(0xFF01060A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Este bloque es total Pax
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color:
                                _controller.isSelectionMode &&
                                    _controller.selectedCount > 0
                                ? Colors.green.shade200
                                : Colors.blue.shade100,
                            alignment: Alignment.center,
                            child: Text(
                              '$totalPax',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _controller.isSelectionMode &&
                                        _controller.selectedCount > 0
                                    ? Colors.green.shade800
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color:
                                _controller.isSelectionMode &&
                                    _controller.selectedCount > 0
                                ? Colors.green.shade200
                                : Colors.blue.shade100,
                            alignment: Alignment.center,
                            child: Text(
                              Formatters.formatCurrency(totalSaldo),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _controller.isSelectionMode &&
                                        _controller.selectedCount > 0
                                    ? Colors.green.shade800
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // A partir de aquí, columnas después de "Saldo":
                  const DataCell(Text('')), // Observaciones
                  const DataCell(Text('')), // Agencia
                  const DataCell(Text('')), // Ticket
                  const DataCell(Text('')), // N° HB
                  const DataCell(Text('')), // Estatus
                  if (authController.hasPermission(
                    Permission.ver_deuda_reservas,
                  ))
                    DataCell(
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              color:
                                  _controller.isSelectionMode &&
                                      _controller.selectedCount > 0
                                  ? Colors.green.shade200
                                  : Colors.blue.shade100,
                              alignment: Alignment.center,
                              child: Text(
                                Formatters.formatCurrency(totalDeuda),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _controller.isSelectionMode &&
                                          _controller.selectedCount > 0
                                      ? Colors.green.shade800
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (authController.hasPermission(Permission.edit_reserva))
                    const DataCell(Text('')),
                ],
              ),
            ],
          ),
        ),

        // --- Botones de paginación ---
        Padding(
          padding: EdgeInsets.all(16.0.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed:
                    _controller.canGoPrevious && !_controller.isFetchingPage
                    ? _controller.previousPage
                    : null,
                child: _controller.isFetchingPage && _controller.canGoPrevious
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Anterior'),
              ),
              const SizedBox(width: 16),
              Text(
                'Página ${_controller.currentPage}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 16.w),
              ElevatedButton(
                onPressed: _controller.canGoNext && !_controller.isFetchingPage
                    ? _controller.nextPage
                    : null,
                child: _controller.isFetchingPage && _controller.canGoNext
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Siguiente'),
              ),
            ],
          ),
        ),
        // --- Selector de elementos por página ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Elementos por página:'),
              SizedBox(width: 8.w),
              DropdownButton<int>(
                value: _controller.itemsPerPage,
                items: const [20, 50, 100]
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      ),
                    )
                    .toList(),
                onChanged: (newValue) {
                  if (newValue != null) _controller.setItemsPerPage(newValue);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(
    ReservaConAgencia ra,
    bool showFechaColumn,
    AuthController authController, // Pasa el AuthController directamente
    List<Map<String, dynamic>> adicionalesActivos,
  ) {
    var r = ra.reserva;
    final isEditing = _editingReservaId == r.id;
    final isSelected = _controller.isReservaSelected(r.id);

    // --- Detectar si la reserva es "nueva" para el usuario ---
    final fechaRegistro = r.fechaRegistro ?? r.fecha;
    final lastSeen = widget.lastSeenReservas;
    final esNueva = lastSeen != null ? fechaRegistro.isAfter(lastSeen) : false;

    // --- Detectar si la reserva es la notificada ---
    final esNotificada =
        widget.reservaIdNotificada != null &&
        widget.reservaIdNotificada == r.id;
    debugPrint('Resaltando reserva: ${widget.reservaIdNotificada}');
    final List<DataCell> cells = [
      // Celda de selección
      DataCell(
        GestureDetector(
          onTap: authController.hasPermission(Permission.select_reservas)
              ? () {
                  if (!_controller.isSelectionMode) {
                    _controller.startSelectionWith(r.id);
                  } else {
                    _controller.toggleReservaSelection(r.id);
                  }
                }
              : null,
          child: _controller.isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged:
                      authController.hasPermission(Permission.select_reservas)
                      ? (value) {
                          _controller.toggleReservaSelection(r.id);
                        }
                      : null,
                )
              : Icon(
                  Icons.check_box_outline_blank,
                  size: 16.sp,
                  color: Colors.grey,
                ),
        ),
      ),
      // Adicionales
      DataCell(
        Row(
          children: r.adicionalesIds.map((id) {
            final adicional = adicionalesActivos.firstWhere((a) => a['id'] == id, orElse: () => <String, dynamic>{});
            if (adicional.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.blue.shade200,
                  child: Text(
                    adicional['icono'] ?? '➕',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        ),
      ),
      // Celda de acción (WhatsApp)
      DataCell(
        IconButton(
          icon: Icon(
            Icons.message,
            color: r.whatsappContactado ? Colors.green : Colors.redAccent,
          ),
          tooltip: 'Chatear por WhatsApp',
          onPressed: authController.hasPermission(Permission.contact_whatsapp)
              ? () async {
                  final telefono = r.telefono
                      .replaceAll('+', '')
                      .replaceAll(' ', '');
                  final uriApp = Uri.parse('whatsapp://send?phone=$telefono');
                  final uriWeb = Uri.parse('https://wa.me/$telefono');

                  if (r.whatsappContactado) {
                    await FirebaseFirestore.instance
                        .collection('reservas')
                        .doc(r.id)
                        .update({'whatsappContactado': false});
                    return;
                  }

                  if (await canLaunchUrl(uriApp)) {
                    await FirebaseFirestore.instance
                        .collection('reservas')
                        .doc(r.id)
                        .update({'whatsappContactado': true});
                    await launchUrl(
                      uriApp,
                      mode: LaunchMode.externalApplication,
                    );
                    return;
                  }

                  if (await canLaunchUrl(uriWeb)) {
                    await FirebaseFirestore.instance
                        .collection('reservas')
                        .doc(r.id)
                        .update({'whatsappContactado': true});
                    await launchUrl(
                      uriWeb,
                      mode: LaunchMode.externalApplication,
                    );
                    return;
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo abrir WhatsApp'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              : null,
        ),
      ),
      // Resto de celdas existentes...
      if (widget.turno == null) DataCell(Text(r.turno?.label ?? '')),
      DataCell(
        isEditing && authController.hasPermission(Permission.edit_reserva)
            ? TextField(
                controller: _controllers['${r.id}_telefono'],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            : Text(
                r.telefono.isNotEmpty ? r.telefono : 'Sin teléfono',
                style: TextStyle(
                  color: r.telefono.isEmpty ? Colors.grey : Colors.black,
                ),
              ),
      ),
      DataCell(
        isEditing && authController.hasPermission(Permission.edit_reserva)
            ? TextField(
                controller: _controllers['${r.id}_hotel'],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            : Text(r.hotel),
      ),
      DataCell(
        isEditing && authController.hasPermission(Permission.edit_reserva)
            ? TextField(
                controller: _controllers['${r.id}_cliente'],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            : Text(r.nombreCliente),
      ),
    ];

    if (widget.turno == TurnoType.privado) {
      cells.add(
        DataCell(Text(r.hora != null ? r.hora!.format(context) : 'Sin hora')),
      );
    }
    // Añadir la celda de Fecha condicionalmente
    //
    if (showFechaColumn) {
      cells.add(
        DataCell(
          isEditing && authController.hasPermission(Permission.edit_reserva)
              ? GestureDetector(
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: _fechaValues[r.id] ?? r.fecha,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (selectedDate != null) {
                      setState(() {
                        _fechaValues[r.id] = selectedDate;
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: TextEditingController(
                        text: Formatters.formatDate(
                          _fechaValues[r.id] ?? r.fecha,
                        ),
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                )
              : Text(Formatters.formatDate(r.fecha)),
        ),
      );
    }
    cells.addAll([
      DataCell(
        isEditing && authController.hasPermission(Permission.edit_reserva)
            ? TextField(
                controller: _controllers['${r.id}_pax'],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            : Text('${r.pax}'),
      ),
      DataCell(
        isEditing && authController.hasPermission(Permission.edit_reserva)
            ? TextField(
                controller: _controllers['${r.id}_saldo'],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            : Text(Formatters.formatCurrency(r.saldo)),
      ),

      // A PARTIR DE AQUÍ, RESPETAR EL ORDEN DE LAS COLUMNAS DESPUÉS DE "Saldo":
      // Observaciones, Agencia, Ticket, N° HB, Estatus, [Deuda], [Editar]

      // Observaciones (botón para ver/editar)
      DataCell(
        IconButton(
          icon: Icon(
            r.observacion.isNotEmpty ? Icons.note : Icons.note_add,
            color: r.observacion.isNotEmpty ? Colors.blue : Colors.grey,
            size: 20,
          ),
          onPressed: () => _showObservacionDialog(ra),
        ),
      ),

      

      // Agencia (texto o dropdown si se está editando y hay permiso)
      DataCell(
        isEditing && authController.hasPermission(Permission.change_agency)
            ? _buildAgenciaDropdown(ra)
            : Text(ra.nombreAgencia),
      ),

      // Ticket (texto o campo editable)
      DataCell(
        isEditing && authController.hasPermission(Permission.edit_reserva)
            ? TextField(
                controller: _controllers['${r.id}_ticket'],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            : Text(r.ticket ?? ''),
      ),

      // N° Habitación (texto o campo editable)
      DataCell(
        isEditing && authController.hasPermission(Permission.edit_reserva)
            ? TextField(
                controller: _controllers['${r.id}_habitacion'],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            : Text(r.habitacion ?? ''),
      ),
      // Celda de Estatus Reserva (A-E)
      // Celda de Estatus Reserva siempre editable si tiene permiso
      DataCell(
        DropdownButton<String>(
          // Valor por defecto siempre válido
          value: ['A', 'B', 'C', 'D', 'E'].contains(r.estatusReserva)
              ? r.estatusReserva!
              : 'A',
          items: [
            'A',
            'B',
            'C',
            'D',
            'E',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (newValue) async {
            if (newValue != null) {
              final updated = ra.reserva.copyWith(estatusReserva: newValue);
              await _controller.updateReserva(r.id, updated);
            }
          },
          underline: const SizedBox.shrink(),
          isDense: true,
        ),
      ),
      if (authController.hasPermission(Permission.ver_deuda_reservas))
        DataCell(
          GestureDetector(
            onTap: authController.hasPermission(Permission.toggle_paid_status)
                ? () async {
                    if (ra.reserva.estado == EstadoReserva.pagada) {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Marcar como pendiente'),
                          content: const Text(
                            '¿Deseas cambiar el estado a pendiente?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sí'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        final updated = ra.reserva.copyWith(
                          estado: EstadoReserva.pendiente,
                        );
                        await _controller.updateReserva(ra.id, updated);
                      }
                    } else {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Marcar como pagada'),
                          content: const Text(
                            '¿Deseas marcar esta reserva como pagada?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Sí'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        final updated = ra.reserva.copyWith(
                          estado: EstadoReserva.pagada,
                        );
                        await _controller.updateReserva(ra.id, updated);
                      }
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ra.reserva.estado == EstadoReserva.pagada
                      ? Colors.green
                      : (ra.reserva.deuda > 0
                            ? Colors.red
                            : Colors.transparent),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: ra.reserva.estado == EstadoReserva.pagada
                  ? const Text(
                      'Pagado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    )
                  : Text(
                      Formatters.formatCurrency(ra.reserva.deuda),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ra.reserva.deuda > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
            ),
          ),
        ),
      if (authController.hasPermission(Permission.edit_reserva))
        DataCell(
          isEditing
              ? Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: _saveChanges,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _cancelEditing,
                    ),
                  ],
                )
              : Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _startEditing(ra),
                    ),
                    if (authController.hasPermission(Permission.delete_reserva))
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(ra),
                      ),
                  ],
                ),
        ),
    ]);

    Color? rowColor;
    if (isSelected) {
      rowColor = Colors.blue.shade100;
    } else if (esNotificada) {
      rowColor =
          Colors.orange.shade200; // Color especial para la reserva notificada
    } else if (esNueva) {
      rowColor = Colors.yellow.shade100; // Color para nuevas reservas
    } else {
      // Colorear fila según estatusReserva: A (sin color), B (rojo), C (azul), D (verde), E (gris)
      switch (r.estatusReserva) {
        case 'B':
          rowColor = Colors.red.shade100;
          break;
        case 'C':
          rowColor = Colors.blue.shade100;
          break;
        case 'D':
          rowColor = Colors.green.shade100;
          break;
        case 'E':
          rowColor = Colors.grey.shade200;
          break;
        default:
          rowColor = null;
      }
    }
    // Aplicar color de fondo si está seleccionada o notificada
    return DataRow(
      color: rowColor != null ? WidgetStateProperty.all(rowColor) : null,
      cells: cells,
    );
  }

  Widget _buildAgenciaDropdown(ReservaConAgencia reserva) {
    final agencias = _controller.getAllAgencias();
    return DropdownButtonFormField<String>(
      value: _agenciaValues[reserva.id],
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(8),
      ),
      items: agencias.map((agencia) {
        return DropdownMenuItem<String>(
          value: agencia.id,
          child: Text(
            agencia.nombre,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _agenciaValues[reserva.id] = value;
          });
        }
      },
    );
  }

  void _showObservacionDialog(ReservaConAgencia ra) {
    final controller = TextEditingController(text: ra.reserva.observacion);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar Observaciones'),
          content: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Observaciones',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final updated = ra.reserva.copyWith(
                  observacion: controller.text,
                );
                await _controller.updateReserva(ra.id, updated);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(ReservaConAgencia reserva) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Reserva'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la reserva de ${reserva.nombreCliente}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              try {
                await _controller.deleteReserva(reserva.id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Reserva eliminada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error eliminando reserva: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
