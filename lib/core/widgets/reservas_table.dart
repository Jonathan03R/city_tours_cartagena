import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/utils/extensions.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = Provider.of<ReservasController>(context, listen: false);
    });
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
    // Construir las columnas dinámicamente
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
      DataColumn(label: Text('Acción')),
      const DataColumn(label: Text('Turno')),
      const DataColumn(label: Text('Número')),
      const DataColumn(label: Text('Hotel')),
      const DataColumn(label: Text('Nombre')),
      if (showFechaColumn) const DataColumn(label: Text('Fecha')),
      const DataColumn(label: Text('Pax')),
      const DataColumn(label: Text('Saldo')),
      const DataColumn(label: Text('Observaciones')),
      const DataColumn(label: Text('Agencia')),
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
            columnSpacing: 12,
            horizontalMargin: 16,
            headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
            columns: columns,
            rows: [
              ...reservasFiltradas.map(
                (reserva) =>
                    _buildDataRow(reserva, showFechaColumn, authController),
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
                  const DataCell(Text('')), // Celda de acción vacía
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
                  const DataCell(Text('')),
                  const DataCell(Text('')),
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
          padding: const EdgeInsets.all(16.0),
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
              const SizedBox(width: 16),
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
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _controller.itemsPerPage,
                items: const [10, 20, 50]
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
  ) {
    var r = ra.reserva;
    final isEditing = _editingReservaId == r.id;
    final isSelected = _controller.isReservaSelected(r.id);

    // --- Detectar si la reserva es "nueva" para el usuario ---
    final fechaRegistro = r.fechaRegistro ?? r.fecha;
    final lastSeen = widget.lastSeenReservas;
    final esNueva = lastSeen != null && fechaRegistro != null
        ? fechaRegistro.isAfter(lastSeen)
        : false;

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
              : const Icon(
                  Icons.check_box_outline_blank,
                  size: 16,
                  color: Colors.grey,
                ),
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
      DataCell(Text(r.turno?.label ?? '')),
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
      // Celda de Observaciones
      DataCell(
        IconButton(
          icon: Icon(
            r.observacion.isNotEmpty ? Icons.note : Icons.note_add,
            color: r.observacion.isNotEmpty ? Colors.blue : Colors.grey,
            size: 20,
          ),
          onPressed:
              authController.hasPermission(Permission.manage_observations)
              ? () => _showObservacionDialog(ra)
              : null,
        ),
      ),
      DataCell(
        isEditing && authController.hasPermission(Permission.change_agency)
            ? _buildAgenciaDropdown(ra)
            : Text(ra.nombreAgencia),
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
