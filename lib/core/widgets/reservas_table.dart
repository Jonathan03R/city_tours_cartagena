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
                  ? 1400 // Ancho mínimo aumentado para más columnas
                  : MediaQuery.of(context).size.width,
              child: DataTable(
                columnSpacing: 12,
                horizontalMargin: 16,
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(
                    label: Text(
                      'HOTEL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CLIENTE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  // DataColumn(
                  //   label: Text(
                  //     'FECHA',
                  //     style: TextStyle(fontWeight: FontWeight.bold),
                  //   ),
                  // ),
                  DataColumn(
                    label: Text(
                      'PAX',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'SALDO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'AGENCIA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'OBSERVACIONES',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ESTADO',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ACCIONES',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: widget.reservas
                    .map((reserva) => _buildDataRow(reserva))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildDataRow(ReservaConAgencia reserva) {
    final isEditing = _editingReservaId == reserva.id;

    return DataRow(
      cells: [
        // HOTEL
        DataCell(
          isEditing
              ? SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _controllers['${reserva.id}_hotel'],
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                      hintText: 'Hotel...',
                    ),
                  ),
                )
              : Container(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    reserva.hotel.isEmpty ? 'Sin hotel' : reserva.hotel,
                    style: TextStyle(
                      color: reserva.hotel.isEmpty ? Colors.grey : Colors.black,
                      fontStyle: reserva.hotel.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),

        // CLIENTE
        DataCell(
          isEditing
              ? SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _controllers['${reserva.id}_cliente'],
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                )
              : Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    reserva.nombreCliente,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),

        // // FECHA
        // DataCell(
        //   isEditing
        //       ? SizedBox(
        //           width: 120,
        //           child: InkWell(
        //             onTap: () async {
        //               final DateTime? picked = await showDatePicker(
        //                 context: context,
        //                 initialDate: _fechaValues[reserva.id] ?? reserva.fecha,
        //                 firstDate: DateTime(2020),
        //                 lastDate: DateTime(2030),
        //               );
        //               if (picked != null) {
        //                 setState(() {
        //                   _fechaValues[reserva.id] = picked;
        //                 });
        //               }
        //             },
        //             child: Container(
        //               padding: const EdgeInsets.all(8),
        //               decoration: BoxDecoration(
        //                 border: Border.all(color: Colors.grey.shade300),
        //                 borderRadius: BorderRadius.circular(4),
        //               ),
        //               child: Row(
        //                 mainAxisSize: MainAxisSize.min,
        //                 children: [
        //                   const Icon(Icons.calendar_today, size: 16),
        //                   const SizedBox(width: 4),
        //                   Text(
        //                     Formatters.formatDate(
        //                       _fechaValues[reserva.id] ?? reserva.fecha,
        //                     ),
        //                     style: const TextStyle(fontSize: 12),
        //                   ),
        //                 ],
        //               ),
        //             ),
        //           ),
        //         )
        //       : Text(
        //           Formatters.formatDate(reserva.fecha),
        //           style: const TextStyle(fontSize: 13),
        //         ),
        // ),

        // PAX
        DataCell(
          isEditing
              ? SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _controllers['${reserva.id}_pax'],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                )
              : Text('${reserva.pax}', style: const TextStyle(fontSize: 13)),
        ),

        // SALDO
        DataCell(
          isEditing
              ? SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _controllers['${reserva.id}_saldo'],
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                )
              : Text(
                  Formatters.formatCurrency(reserva.saldo),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: reserva.saldo > 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
        ),

        // AGENCIA
        DataCell(
          isEditing
              ? SizedBox(width: 150, child: _buildAgenciaDropdown(reserva))
              : Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    reserva.nombreAgencia,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),

        // OBSERVACIONES
        DataCell(
          isEditing
              ? SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _controllers['${reserva.id}_observacion'],
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(8),
                      hintText: 'Observaciones...',
                    ),
                  ),
                )
              : Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    reserva.observacion.isEmpty
                        ? 'Sin observaciones'
                        : reserva.observacion,
                    style: TextStyle(
                      fontSize: 12,
                      color: reserva.observacion.isEmpty
                          ? Colors.grey
                          : Colors.black,
                      fontStyle: reserva.observacion.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
        ),

        // ESTADO con botones rápidos
        // ESTADO con popup
        DataCell(
          GestureDetector(
            onTapDown: (TapDownDetails details) async {
              final position = details.globalPosition;
              await showMenu(
                context: context,
                position: RelativeRect.fromLTRB(position.dx, position.dy, 0, 0),
                items: [
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: const Text('Confirmada'),
                      onTap: () {
                        Navigator.pop(context);
                        _quickChangeStatus(reserva, EstadoReserva.confirmada);
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.schedule, color: Colors.orange),
                      title: const Text('Pendiente'),
                      onTap: () {
                        Navigator.pop(context);
                        _quickChangeStatus(reserva, EstadoReserva.pendiente);
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: const Icon(Icons.cancel, color: Colors.red),
                      title: const Text('Cancelada'),
                      onTap: () {
                        Navigator.pop(context);
                        _quickChangeStatus(reserva, EstadoReserva.cancelada);
                      },
                    ),
                  ),
                ],
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.getEstadoBackgroundColor(reserva.estado),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                Formatters.getEstadoText(reserva.estado),
                style: TextStyle(
                  color: AppColors.getEstadoColor(reserva.estado),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // ACCIONES
        DataCell(
          isEditing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: _saveChanges,
                      tooltip: 'Guardar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: _cancelEditing,
                      tooltip: 'Cancelar',
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () => _startEditing(reserva),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _showDeleteDialog(reserva),
                      tooltip: 'Eliminar',
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

  void _showDeleteDialog(ReservaConAgencia reserva) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reserva'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la reserva de ${reserva.nombreCliente}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ReservasController.deleteReserva(reserva.id);
                widget.onUpdate();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reserva eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error eliminando reserva: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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
