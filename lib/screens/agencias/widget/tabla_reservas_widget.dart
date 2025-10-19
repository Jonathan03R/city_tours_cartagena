import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vibration/vibration.dart';

class TablaReservasWidget extends StatefulWidget {
  final List<ReservaResumen> listaReservas;
  final bool mostrarColumnaFecha;
  final bool mostrarColumnaServicio;
  final bool mostrarColumnaObservaciones;
  final VoidCallback? onToggleStatus; // Callback para alternar estado
  final Future<void> Function(ReservaResumen reserva, String observaciones)? onActualizarObservaciones;
  final Future<double> Function(ReservaResumen reserva)? onProcesarPago;

  const TablaReservasWidget({
    super.key,
    required this.listaReservas,
    this.mostrarColumnaFecha = true,
    this.mostrarColumnaServicio = true,
    this.mostrarColumnaObservaciones = true,
    this.onToggleStatus,
    this.onActualizarObservaciones,
    this.onProcesarPago,
  });

  @override
  State<TablaReservasWidget> createState() => _TablaReservasWidgetState();
}

class _TablaReservasWidgetState extends State<TablaReservasWidget> {
  final Set<int> _selectedRows = {};
  bool _isSelectionMode = false; // Nuevo: Modo de selección múltiple

  // Método para calcular el total de pasajeros
  int _calcularTotalPasajeros() {
    final reservas = _selectedRows.isEmpty ? widget.listaReservas : _selectedRows.map((i) => widget.listaReservas[i]).toList();
    return reservas.fold<int>(
      0,
      (suma, reserva) => suma + reserva.reservaPasajeros,
    );
  }

  // Método para calcular el total de saldos
  double _calcularTotalSaldos() {
    final reservas = _selectedRows.isEmpty ? widget.listaReservas : _selectedRows.map((i) => widget.listaReservas[i]).toList();
    return reservas.fold<double>(
      0.0,
      (suma, reserva) => suma + reserva.saldo,
    );
  }

  // Método para calcular el total de deudas
  double _calcularTotalDeudas() {
    final reservas = _selectedRows.isEmpty ? widget.listaReservas : _selectedRows.map((i) => widget.listaReservas[i]).toList();
    return reservas.where((reserva) => reserva.estadoNombre.toLowerCase() == 'pendiente').fold<double>(
      0.0,
      (suma, reserva) => suma + reserva.deuda,
    );
  }

  // Método para obtener color según el prefijo
  Color _obtenerColorEstado(String colorPrefijo) {
    switch (colorPrefijo.toLowerCase()) {
      case 'verde':
        return Colors.green;
      case 'rojo':
        return Colors.red;
      case 'azul':
        return Colors.blue;
      case 'amarillo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedRows.clear(); // Limpiar selección al salir del modo
      }
    });
  }

  void _handleLongPress(int index) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedRows.add(index);
      });
      if (Vibration.hasVibrator() != null) {
        Vibration.vibrate(duration: 50); // Vibrar al activar selección múltiple
      }
    }
  }

  void _handleRowTap(int index) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedRows.contains(index)) {
          _selectedRows.remove(index);
        } else {
          _selectedRows.add(index);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.listaReservas.isEmpty) {
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

    // Construir columnas dinámicamente
    final List<DataColumn> columnas = [
      if (widget.mostrarColumnaServicio)
        const DataColumn(
          label: Text('Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      const DataColumn(
        label: Text('Contactos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text(
          'Punto Encuentro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text(
          'Representante',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      if (widget.mostrarColumnaFecha)
        const DataColumn(
          label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      const DataColumn(
        label: Text('Pasajeros', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      if (widget.mostrarColumnaObservaciones)
        const DataColumn(
          label: Text(
            'Observaciones',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      const DataColumn(
        label: Text('Agencia', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text(
          'Habitación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      const DataColumn(
        label: Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Deuda', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ];

    return Column(
      children: [
        if (_isSelectionMode)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_selectedRows.length} seleccionadas'),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                ),
              ],
            ),
          ),
        // Tabla principal
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                showCheckboxColumn: _isSelectionMode,
                columnSpacing: 12.w,
                horizontalMargin: 16.w,
                headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                headingRowHeight: 56.h,
                dataRowHeight: 48.h,
                columns: columnas,
                rows: [
                  // Filas de datos
                  ...widget.listaReservas.asMap().entries.map(
                    (entry) => _construirFilaDatos(context, entry.value, entry.key),
                  ),
                  // Fila de totales
                  _construirFilaTotales(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Método para construir cada fila de datos
  DataRow _construirFilaDatos(BuildContext context, ReservaResumen reserva, int index) {
    final List<DataCell> celdas = [
      if (widget.mostrarColumnaServicio)
        DataCell(
          GestureDetector(
            onLongPress: () => _handleLongPress(index),
            child: Text(reserva.tipoServicioDescripcion, overflow: TextOverflow.ellipsis),
          ),
        ),
      DataCell(
        InkWell(
          onTap: () => _mostrarSelectorContactos(context, reserva.contactos),
          child: Icon(
            Icons.contact_phone,
            color: reserva.contactos.isNotEmpty ? Colors.green : Colors.grey,
          ),
        ),
      ),
      DataCell(
        Text(reserva.reservaPuntoEncuentro, overflow: TextOverflow.ellipsis),
      ),
      DataCell(
        Text(reserva.reservaRepresentante, overflow: TextOverflow.ellipsis),
      ),
      if (widget.mostrarColumnaFecha)
        DataCell(Text(Formatters.formatDate(reserva.reservaFecha))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            reserva.reservaPasajeros.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      DataCell(
        Text(
          Formatters.formatCurrency(reserva.saldo),
          style: TextStyle(
            color: reserva.saldo > 0 ? Colors.green.shade700 : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      if (widget.mostrarColumnaObservaciones)
        DataCell(
          InkWell(
            onTap: () {
              bool isEditing = false;
              final TextEditingController controller = TextEditingController(text: reserva.observaciones ?? '');
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isEditing ? Icons.edit : Icons.note_alt,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEditing ? 'Editar Observaciones' : 'Observaciones',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (!isEditing)
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      reserva.observaciones?.isNotEmpty == true
                                          ? reserva.observaciones!
                                          : 'No hay observaciones.',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                )
                              else
                                TextField(
                                  controller: controller,
                                  maxLines: 5,
                                  maxLength: 500,
                                  decoration: InputDecoration(
                                    hintText: 'Ingrese observaciones (opcional)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  autofocus: true,
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isEditing)
                                    ElevatedButton.icon(
                                      onPressed: () => setState(() => isEditing = true),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Editar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                      ),
                                    )
                                  else ...[
                                    TextButton(
                                      onPressed: () => setState(() => isEditing = false),
                                      child: const Text('Cancelar Edición'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        setState(() => isEditing = false); // Cambiar a vista mientras guarda
                                        try {
                                          await widget.onActualizarObservaciones?.call(reserva, controller.text.trim());
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Observaciones actualizadas correctamente'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error al actualizar: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          setState(() => isEditing = true); // Volver a edición si falla
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Guardar'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
            child: reserva.observaciones != null && reserva.observaciones!.isNotEmpty
                ? Tooltip(
                    message: reserva.observaciones!,
                    child: const Icon(Icons.note, color: Colors.blue, size: 20),
                  )
                : const Icon(Icons.note_outlined, color: Colors.grey, size: 20),
          ),
        ),
      DataCell(Text(reserva.agenciaNombre, overflow: TextOverflow.ellipsis)),
      DataCell(Text(reserva.numeroTickete ?? 'N/A')),
      DataCell(Text(reserva.numeroHabitacion ?? 'N/A')),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _obtenerColorEstado(reserva.colorPrefijo).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            reserva.colorPrefijo,
            style: TextStyle(
              color: _obtenerColorEstado(reserva.colorPrefijo),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      DataCell(
        GestureDetector(
          onTap: widget.onProcesarPago != null
              ? () async {
                  final isPendiente = reserva.estadoNombre.toLowerCase() == 'pendiente';
                  final accion = isPendiente ? 'pagar' : 'revertir el pago de';
                  final titulo = isPendiente ? 'Confirmar Pago' : 'Confirmar Reversión';
                  final mensaje = '¿Estás seguro de que quieres $accion la reserva ${reserva.reservaCodigo}?';

                  final confirmar = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(titulo),
                        content: Text(mensaje),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPendiente ? Colors.green : Colors.orange,
                            ),
                            child: Text(isPendiente ? 'Pagar' : 'Revertir'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmar == true) {
                    try {
                      final result = await widget.onProcesarPago!(reserva);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Pago procesado: ${result.toStringAsFixed(2)}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al procesar pago: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              : widget.onToggleStatus != null
                  ? () async {
                      // Lógica para alternar estado, similar a ReservasTable
                      // Aquí se puede implementar el toggle usando el callback o lógica directa
                      // Por ahora, placeholder
                      widget.onToggleStatus?.call();
                    }
                  : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: reserva.estadoNombre.toLowerCase() == 'pagada'
                    ? Colors.green
                    : (reserva.deuda > 0 ? Colors.red : Colors.transparent),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: reserva.estadoNombre.toLowerCase() == 'pagada'
                ? const Text(
                    'Pagado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  )
                : Text(
                    Formatters.formatCurrency(reserva.deuda),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: reserva.deuda > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
          ),
        ),
      ),
    ];

    return DataRow(
      selected: _selectedRows.contains(index),
      onSelectChanged: _isSelectionMode
          ? (selected) => _handleRowTap(index)
          : null,
      cells: celdas,
    );
  }

  // Método para mostrar selector de contactos
  void _mostrarSelectorContactos(BuildContext context, List<Map<String, dynamic>> contactos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Contacto'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: contactos.length,
              itemBuilder: (context, index) {
                final contacto = contactos[index];
                final telefono = contacto['contacto'] as String? ?? '';
                final tipo = contacto['tipo_contacto_codigo'] as int? ?? 0;
                final tipoTexto = tipo == 1 ? 'WhatsApp' : 'Otro';
                return ListTile(
                  leading: Icon(
                    tipo == 1 ? Icons.message : Icons.phone,
                    color: tipo == 1 ? Colors.green : Colors.blue,
                  ),
                  title: Text('Teléfono: $telefono'),
                  subtitle: Text('Tipo: $tipoTexto'),
                  onTap: () {
                    // Aquí puedes agregar lógica para abrir WhatsApp o llamar
                    // Por ejemplo: launchUrl(Uri.parse('https://wa.me/$telefono'));
                    Navigator.of(context).pop();
                    // Mostrar un snackbar o algo para confirmar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Seleccionado: $telefono ($tipoTexto)')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Método para construir la fila de totales
  DataRow _construirFilaTotales() {
    final totalPasajeros = _calcularTotalPasajeros();
    final totalSaldos = _calcularTotalSaldos();
    final totalDeudas = _calcularTotalDeudas();

    final List<DataCell> celdasTotales = [
      if (widget.mostrarColumnaServicio) const DataCell(Text('')), // Servicio
      const DataCell(Text('')), // Contactos
      const DataCell(Text('')), // Punto Encuentro
      DataCell(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'TOTALES',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ), // Representante
      if (widget.mostrarColumnaFecha) const DataCell(Text('')), // Fecha
      DataCell(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            totalPasajeros.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ), // Pasajeros
      DataCell(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            Formatters.formatCurrency(totalSaldos),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
        ),
      ), // Saldo
      if (widget.mostrarColumnaObservaciones) const DataCell(Text('')), // Observaciones
      const DataCell(Text('')), // Agencia
      const DataCell(Text('')), // Ticket
      const DataCell(Text('')), // Habitación
      const DataCell(Text('')), // Color
      DataCell(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            Formatters.formatCurrency(totalDeudas),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ),
      ), // Deuda
    ];

    return DataRow(
      color: WidgetStateProperty.all(Colors.grey.shade100),
      cells: celdasTotales,
    );
  }
}
