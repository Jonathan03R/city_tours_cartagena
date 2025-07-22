import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:flutter/material.dart';

import '../mvvc/reservas_controller.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class ReservasTable extends StatefulWidget {
  final List<ReservaConAgencia> reservas;
  final VoidCallback onUpdate;

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
      widget.onUpdate();

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
      widget.onUpdate();

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

  // Future<void> _exportToExcel() async {
  //   try {
  //   // Pedir permiso
  //   var status = await Permission.manageExternalStorage.request();

  //   if (!status.isGranted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Permiso denegado. No se puede guardar el archivo'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return;
  //   }

  //     // 2. Crear Excel
  //     final excel = xls.Excel.createExcel();
  //     final sheet = excel['Reservas'];

  //     // Cabeceras
  //     sheet.appendRow([
  //       xls.TextCellValue('HOTEL'),
  //       xls.TextCellValue('CLIENTE'),
  //       xls.TextCellValue('FECHA'),
  //       xls.TextCellValue('PAX'),
  //       xls.TextCellValue('SALDO'),
  //       xls.TextCellValue('AGENCIA'),
  //       xls.TextCellValue('OBSERVACIONES'),
  //       xls.TextCellValue('ESTADO'),
  //     ]);

  //     // Filas
  //     for (var r in widget.reservas) {
  //       sheet.appendRow([
  //         xls.TextCellValue(r.hotel.isEmpty ? 'Sin hotel' : r.hotel),
  //         xls.TextCellValue(r.nombreCliente),
  //         xls.TextCellValue(Formatters.formatDate(r.fecha)),
  //         xls.IntCellValue(r.pax),
  //         xls.DoubleCellValue(r.saldo),
  //         xls.TextCellValue(r.nombreAgencia),
  //         xls.TextCellValue(
  //           r.observacion.isEmpty ? 'Sin observaciones' : r.observacion,
  //         ),
  //         xls.TextCellValue(Formatters.getEstadoText(r.estado)),
  //       ]);
  //     }

  //     // 3. Codificar
  //     final bytes = excel.encode();
  //     if (bytes == null) return;

  //     // 4. Ruta pública en Descargas
  //     final directory = Directory('/storage/emulated/0/Download');
  //     if (!directory.existsSync()) {
  //       directory.createSync(recursive: true);
  //     }

  //     final filePath =
  //         '${directory.path}/reservas_${DateTime.now().millisecondsSinceEpoch}.xlsx';

  //     final file = File(filePath);
  //     await file.writeAsBytes(bytes);

  //     // 5. Confirmación
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Archivo guardado en Descargas')),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Error exportando: $e')));
  //     }
  //   }
  // }

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
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   child: ElevatedButton.icon(
        //     onPressed: _exportToExcel,
        //     icon: const Icon(Icons.download),
        //     label: const Text('Exportar a Excel'),
        //     style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        //   ),
        // ),
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
                    color: MaterialStateProperty.all(Colors.grey.shade200),
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
    final r = ra.reserva;
    final deuda = r.deuda; // = r.costoAsiento * r.pax - r.saldo
    final isEditing = _editingReservaId == r.id;

    return DataRow(
      cells: [
        // ACCIÓN: botón genérico
        DataCell(
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              // tu función aquí
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
        // Nombrew
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
