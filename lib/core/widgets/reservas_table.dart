import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/mvvc/reservas_controller.dart';
import 'package:citytourscartagena/core/utils/extensions.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart'; // Importar DateFilterType
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importar Provider
import 'package:url_launcher/url_launcher.dart';

import 'reserva_details.dart'; // Importar ReservaDetails

class ReservasTable extends StatefulWidget {
  // final
  final List<ReservaConAgencia> reservas;
  final VoidCallback onUpdate;
  final DateFilterType currentFilter;
  final TurnoType? turno;

  final String? agenciaId;

  const ReservasTable({
    super.key,
    required this.reservas,
    required this.onUpdate,
    required this.currentFilter, // Requerir el filtro actual
    required this.turno,
    required this.agenciaId,
  });

  @override
  State<ReservasTable> createState() => _ReservasTableState();
}

class _ReservasTableState extends State<ReservasTable> {
  String? _editingReservaId;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, EstadoReserva> _estadoValues = {};
  final Map<String, DateTime> _fechaValues = {}; // Para la fecha de la reserva
  final Map<String, String> _agenciaValues = {};

  late ReservasController _controller; // Declarar como late

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador aquí, asegurándose de que el contexto esté disponible
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

  /// Inicia la edición de una reserva
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
      _fechaValues[reserva.id] = reserva.fecha; // Usar reserva.fecha
      _agenciaValues[reserva.id] = reserva.agencia.id; // Usar agencia.id
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

  /// Guarda los cambios realizados en la reserva editada
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
        fecha:
            _fechaValues[_editingReservaId] ??
            reservaCA.fecha, // CORREGIDO: Usar 'fecha'
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
        agenciaId:
            _agenciaValues[_editingReservaId] ??
            reservaCA.agencia.id, // Usar agencia.id
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

  void _showReservaDetails(BuildContext context, ReservaConAgencia reserva) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReservaDetails(
        reserva: reserva,
        onUpdate: widget.onUpdate, // Pasar el callback de actualización
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el controlador a través de Provider

    // debugPrint('Agencia ID: ${widget.agenciaId}');
    // debugPrint(
    //   '>>> ReservasTable: recibidos ${widget.reservas.length} items <<<',
    // );
    // // 2) Detalle de cada ReservaConAgencia
    // for (var ra in widget.reservas) {
    //   debugPrint(
    //     '– reserva.id=${ra.reserva.id}, '
    //     'cliente=${ra.reserva.nombreCliente}, '
    //     'hotel=${ra.reserva.hotel}, '
    //     'pax=${ra.reserva.pax}, '
    //     'saldo=${ra.reserva.saldo}, '
    //     'observación=${ra.reserva.observacion}, '
    //     'fecha=${ra.reserva.fecha}, '
    //     'turno=${ra.reserva.turno}, '
    //     'agencia.id=${ra.agencia.id}, '
    //     'agencia.nombre=${ra.agencia.nombre}',
    //   );
    // }

    _controller = Provider.of<ReservasController>(context);

    // final reservasFiltradas = widget.turno != null
    //     ? widget.reservas
    //           .where((rca) => rca.reserva.turno.toString().split('.').last == widget.turno.toString().split('.').last) // Comparar con string
    //           .toList()
    //     : widget.reservas;
    final reservasFiltradas = widget.reservas;
    debugPrint(
      'Página recibida: ${widget.reservas.length}, a mostrar: ${reservasFiltradas.length}',
    );

    // debugPrint('📋filtro prueba Reservas en tabla: ${reservasFiltradas.map((r) => r.reserva.nombreCliente + " " + r.reserva.turno.toString().split('.').last).toList()}');
    // final totalPax = reservasFiltradas.fold<int>(
    //   0,
    //   (sum, ra) => sum + ra.reserva.pax,
    // );

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
    }else {
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

    // Determinar si la columna de fecha debe mostrarse
    final showFechaColumn =
        widget.currentFilter == DateFilterType.all ||
        widget.currentFilter == DateFilterType.lastWeek;

    // Construir las columnas dinámicamente
    final List<DataColumn> columns = [
      const DataColumn(label: Text('Acción')),
      const DataColumn(label: Text('Turno')),
      const DataColumn(label: Text('Número')),
      const DataColumn(label: Text('Hotel')),
      const DataColumn(label: Text('Nombre')),
      if (showFechaColumn)
        const DataColumn(label: Text('Fecha')), // Columna de Fecha condicional
      const DataColumn(label: Text('Pax')),
      const DataColumn(label: Text('Saldo')),
      const DataColumn(label: Text('Observaciones')),
      const DataColumn(label: Text('Agencia')),
      const DataColumn(label: Text('Deuda')),
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
            columns: columns, // Usar las columnas dinámicas
            rows: [
              ...reservasFiltradas.map(
                (reserva) => _buildDataRow(reserva, showFechaColumn),
              ), // Pasar showFechaColumn
              DataRow(
                color: WidgetStateProperty.all(Colors.grey.shade200),
                cells: [
                  const DataCell(Text('')), // Celda de acción vacía
                  const DataCell(Text('')), // Celda de acción vacía
                  const DataCell(Text('')), // Celda de número vacía
                  const DataCell(Text('')), // Celda de hotel vacía
                  if (!showFechaColumn)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.blue.shade100,
                        alignment: Alignment.center,
                        child: const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
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
                              color: Colors.blue.shade100,
                              alignment: Alignment.center,
                              child: const Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF01060A),
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
                            color: Colors.blue.shade100,
                            alignment: Alignment.center,
                            child: Text(
                              '$totalPax',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ///esto es para mostrar el total de saldo
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.blue.shade100,
                            alignment: Alignment.center,
                            child: Text(
                              Formatters.formatCurrency(totalSaldo),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const DataCell(Text('')),
                  const DataCell(Text('')),

                  /// esto es para mostrar el total de deuda
                  DataCell(
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.blue.shade100,
                            alignment: Alignment.center,
                            child: Text(
                              Formatters.formatCurrency(totalDeuda),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const DataCell(Text('')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(ReservaConAgencia ra, bool showFechaColumn) {
    // Recibir showFechaColumn
    var r = ra.reserva;
    final isEditing = _editingReservaId == r.id;

    final List<DataCell> cells = [
      // Celda de acción
      DataCell(
        IconButton(
          icon: Icon(
            Icons.message,
            color: r.whatsappContactado ? Colors.green : Colors.redAccent,
          ),
          tooltip: 'Chatear por WhatsApp',
          onPressed: () async {
            final telefono = r.telefono.replaceAll('+', '').replaceAll(' ', '');
            final uriApp = Uri.parse('whatsapp://send?phone=$telefono');
            final uriWeb = Uri.parse('https://wa.me/$telefono');
            // Si ya estaba marcado, desmárcalo directamente
            if (r.whatsappContactado) {
              await FirebaseFirestore.instance
                  .collection('reservas')
                  .doc(r.id)
                  .update({'whatsappContactado': false});
              // No es necesario setState aquí, el stream de Firestore lo actualizará
              return;
            }
            // 1️⃣ Intentar el esquema nativo
            if (await canLaunchUrl(uriApp)) {
              // Marcamos antes de lanzar para que quede verde inmediatamente
              await FirebaseFirestore.instance
                  .collection('reservas')
                  .doc(r.id)
                  .update({'whatsappContactado': true});
              // No es necesario setState aquí, el stream de Firestore lo actualizará
              await launchUrl(uriApp, mode: LaunchMode.externalApplication);
              return;
            }
            // 2️⃣ Fallback a web
            if (await canLaunchUrl(uriWeb)) {
              await FirebaseFirestore.instance
                  .collection('reservas')
                  .doc(r.id)
                  .update({'whatsappContactado': true});
              // No es necesario setState aquí, el stream de Firestore lo actualizará
              await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
              return;
            }
            // 3️⃣ Ni app ni web disponibles
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se pudo abrir WhatsApp'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
      DataCell(
        Text(r.turno?.label ?? ''), // Mostrar el turno como texto
      ),
      // Celda de número
      DataCell(
        isEditing
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
      // Celda de hotel
      DataCell(
        isEditing
            ? TextField(
                controller: _controllers['${r.id}_hotel'],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
              )
            : Text(r.hotel),
      ),
      // Celda de nombre
      DataCell(
        isEditing
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
    if (showFechaColumn) {
      cells.add(
        DataCell(
          isEditing
              ? GestureDetector(
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          _fechaValues[r.id] ??
                          r.fecha, // CORREGIDO: Usar r.fecha
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
                          _fechaValues[r.id] ??
                              r.fecha, // CORREGIDO: Usar r.fecha
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
              : Text(Formatters.formatDate(r.fecha)), // CORREGIDO: Usar r.fecha
        ),
      );
    }

    cells.addAll([
      // Celda de Pax
      DataCell(
        isEditing
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
      // Celda de Saldo
      DataCell(
        isEditing
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
          onPressed: () => _showObservacionDialog(ra),
        ),
      ),
      // Celda de Agencia
      DataCell(isEditing ? _buildAgenciaDropdown(ra) : Text(ra.nombreAgencia)),
      // Celda de Deuda
      DataCell(
        GestureDetector(
          onTap: () async {
            // Lógica para marcar como PAGADA o PENDIENTE
            if (ra.reserva.estado == EstadoReserva.pagada) {
              // Si ya está pagada, preguntar si queremos volver a pendiente
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Marcar como pendiente'),
                  content: const Text('¿Deseas cambiar el estado a pendiente?'),
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
                  // NO MODIFICAR EL SALDO
                );
                await _controller.updateReserva(ra.id, updated);
              }
            } else {
              // Si no está pagada, preguntar si queremos marcar como pagada
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
                  // saldo: 0.0,
                );
                await _controller.updateReserva(ra.id, updated);
                // No es necesario widget.onUpdate() aquí, el controlador ya lo maneja
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: ra.reserva.estado == EstadoReserva.pagada
                    ? Colors.green
                    : (ra.reserva.deuda > 0 ? Colors.red : Colors.transparent),
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
      // Celda de Editar
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
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(ra),
                  ),
                ],
              ),
      ),
    ]);

    return DataRow(cells: cells);
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
                // No es necesario widget.onUpdate() aquí, el controlador ya lo maneja
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
                // No es necesario widget.onUpdate() aquí, el controlador ya lo maneja
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
