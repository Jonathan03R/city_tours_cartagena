import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../mvvc/reservas_controller.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class ReservasTable extends StatefulWidget {
  final List<ReservaConAgencia> reservas;
  final VoidCallback onUpdate; // Se mantiene para forzar recarga si es necesario (ej. después de editar/eliminar)

  const ReservasTable({
    super.key,
    required this.reservas,
    required this.onUpdate,
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
      // Inicializar controladores
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
      // Inicializar valores
      _estadoValues[reserva.id] = reserva.estado;
      _fechaValues[reserva.id] = reserva.fecha;
      _agenciaValues[reserva.id] = reserva.agenciaId;
    });
  }

  void _cancelEditing() {
    setState(() {
      if (_editingReservaId != null) {
        // Limpiar controladores
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
      final reserva = widget.reservas.firstWhere(
        (r) => r.id == _editingReservaId,
      );
      final updatedReserva = reserva.reserva.copyWith(
        nombreCliente:
            _controllers['${_editingReservaId}_cliente']?.text ??
            reserva.nombreCliente,
        hotel:
            _controllers['${_editingReservaId}_hotel']?.text ?? reserva.hotel,
        telefono:
            _controllers['${_editingReservaId}_telefono']?.text ??
            reserva.telefono,
        estado: _estadoValues[_editingReservaId] ?? reserva.estado,
        fecha: _fechaValues[_editingReservaId] ?? reserva.fecha,
        pax:
            int.tryParse(
              _controllers['${_editingReservaId}_pax']?.text ?? '',
            ) ??
            reserva.pax,
        saldo:
            double.tryParse(
              _controllers['${_editingReservaId}_saldo']?.text ?? '',
            ) ??
            reserva.saldo,
        agenciaId: _agenciaValues[_editingReservaId] ?? reserva.agenciaId,
        observacion:
            _controllers['${_editingReservaId}_observacion']?.text ??
            reserva.observacion,
      );
      await ReservasController.updateReserva(
        _editingReservaId!,
        updatedReserva,
      );
      _cancelEditing();
      widget.onUpdate(); // Llama a onUpdate para que ReservasView recargue el stream
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

  Future<void> _quickChangeStatus(
    ReservaConAgencia reserva,
    EstadoReserva newStatus,
  ) async {
    try {
      final updatedReserva = reserva.reserva.copyWith(estado: newStatus);
      await ReservasController.updateReserva(reserva.id, updatedReserva);
      widget.onUpdate(); // Llama a onUpdate para que ReservasView recargue el stream
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estado cambiado a ${Formatters.getEstadoText(newStatus)}',
            ),
            backgroundColor: AppColors.getEstadoColor(newStatus),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cambiando estado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cálculo de totales
    final totalPax = widget.reservas.fold<int>(
      0,
      (sum, ra) => sum + ra.reserva.pax,
    );
    final totalSaldo = widget.reservas.fold<double>(
      0.0,
      (sum, ra) => sum + ra.reserva.saldo,
    );
    final totalDeuda = widget.reservas.fold<double>(
      0.0,
      (sum, ra) => sum + ra.reserva.deuda,
    );
    if (widget.reservas.isEmpty) {
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width < 800
                  ? 1400
                  : MediaQuery.of(context).size.width,
              child: DataTable(
                columnSpacing: 12,
                horizontalMargin: 16,
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('Acción')),
                  DataColumn(label: Text('Número')),
                  DataColumn(label: Text('Hotel')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Pax')),
                  DataColumn(label: Text('Saldo')),
                  DataColumn(label: Text('Observaciones')),
                  DataColumn(label: Text('Agencia')),
                  DataColumn(label: Text('Deuda')),
                  DataColumn(label: Text('Editar')),
                ],
                rows: [
                  ...widget.reservas.map((reserva) => _buildDataRow(reserva)),
                  // Fila de totales integrada al final de la tabla
                  DataRow(
                    color: WidgetStateProperty.all(Colors.grey.shade200),
                    cells: [
                      const DataCell(Text('')), // Acción
                      const DataCell(Text('')), // Número
                      const DataCell(Text('')), // Hotel
                      const DataCell(Text('')), // Nombre
                      DataCell(
                        Text(
                          '$totalPax',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ), // Total PAX
                      DataCell(
                        Text(
                          Formatters.formatCurrency(totalSaldo),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ), // Total Saldo
                      const DataCell(Text('')), // Observaciones
                      const DataCell(Text('')), // Agencia
                      DataCell(
                        Text(
                          Formatters.formatCurrency(totalDeuda),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ), // Total Deuda
                      const DataCell(Text('')), // Editar
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(ReservaConAgencia ra) {
    var r = ra.reserva;
    final deuda = r.deuda; // = r.costoAsiento * r.pax - r.saldo
    final isEditing = _editingReservaId == r.id;
    // Set<String> chatsAbiertos = {}; // Esta variable no se usa y puede eliminarse

    return DataRow(
      cells: [
        // ACCIÓN: botón de WhatsApp
        DataCell(
          IconButton(
            icon: Icon(
              Icons.message,
              color: r.whatsappContactado ? Colors.green : Colors.black54,
            ),
            tooltip: 'Chatear por WhatsApp',
            onPressed: () async {
              // Si ya estaba en verde (contactado), lo desmarcamos
              if (r.whatsappContactado) {
                await FirebaseFirestore.instance
                    .collection('reservas')
                    .doc(r.id)
                    .update({'whatsappContactado': false});
                // No es necesario setState aquí, el StreamBuilder en ReservasView lo actualizará
                return;
              }

              // Si está gris, marcamos como contactado y abrimos WhatsApp
              final telefono = r.telefono.replaceAll('+', '').replaceAll(' ', '');
              final uri = Uri.parse('https://wa.me/$telefono');

              if (await canLaunchUrl(uri)) {
                // Guardamos en Firebase antes o después de abrir WhatsApp
                await FirebaseFirestore.instance
                    .collection('reservas')
                    .doc(r.id)
                    .update({'whatsappContactado': true});
                // No es necesario setState aquí, el StreamBuilder en ReservasView lo actualizará
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se pudo abrir WhatsApp'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ),
        // NÚMERO
        DataCell(
          isEditing
              ? TextField(controller: _controllers['${r.id}_telefono'])
              : Text(
                  r.telefono.isNotEmpty ? r.telefono : 'Sin teléfono',
                  style: TextStyle(
                    color: r.telefono.isEmpty ? Colors.grey : Colors.black,
                  ),
                ),
        ),
        // HOTEL
        DataCell(
          isEditing
              ? TextField(controller: _controllers['${r.id}_hotel'])
              : Text(r.hotel),
        ),
        // Nombre
        DataCell(
          isEditing
              ? TextField(controller: _controllers['${r.id}_cliente'])
              : Text(r.nombreCliente),
        ),
        // PAX
        DataCell(
          isEditing
              ? TextField(
                  controller: _controllers['${r.id}_pax'],
                  keyboardType: TextInputType.number,
                )
              : Text('${r.pax}'),
        ),
        // SALDO
        DataCell(
          isEditing
              ? TextField(
                  controller: _controllers['${r.id}_saldo'],
                  keyboardType: TextInputType.number,
                )
              : Text(Formatters.formatCurrency(r.saldo)),
        ),
        // OBSERVACIONES
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
        // AGENCIA
        DataCell(
          isEditing ? _buildAgenciaDropdown(ra) : Text(ra.nombreAgencia),
        ),
        // DEUDA (no editable; borde rojo si > 0)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: deuda > 0 ? Colors.red : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              Formatters.formatCurrency(deuda),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: deuda > 0 ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ),
        // EDITAR: entra o sale de modo edición
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
      ],
    );
  }

  Widget _buildAgenciaDropdown(ReservaConAgencia reserva) {
    final agencias = ReservasController.getAllAgencias();
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
                await ReservasController.updateReserva(ra.id, updated);
                widget.onUpdate();
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
              // Cierro el diálogo usando el mismo context del builder
              Navigator.of(ctx).pop();
              // Capturo el messenger **antes** de entrar al await
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ReservasController.deleteReserva(reserva.id);
                widget.onUpdate();
                // Muestro el SnackBar sin llamar a ScaffoldMessenger.of() dentro del async gap
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
