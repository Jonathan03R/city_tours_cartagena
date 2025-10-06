import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TablaReservasWidget extends StatefulWidget {
  final List<ReservaResumen> listaReservas;
  final bool mostrarColumnaFecha;
  final bool mostrarColumnaObservaciones;

  const TablaReservasWidget({
    super.key,
    required this.listaReservas,
    this.mostrarColumnaFecha = true,
    this.mostrarColumnaObservaciones = true,
  });

  @override
  State<TablaReservasWidget> createState() => _TablaReservasWidgetState();
}

class _TablaReservasWidgetState extends State<TablaReservasWidget> {
  final Set<int> _selectedRows = {};

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

  // Método para formatear moneda
  String _formatearMoneda(double cantidad) {
    return '\$${cantidad.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // Método para formatear fecha
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
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
      const DataColumn(
        label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Contactos', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
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
        label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Saldo', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const DataColumn(
        label: Text('Deuda', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      if (widget.mostrarColumnaObservaciones)
        const DataColumn(
          label: Text(
            'Observaciones',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
    ];

    return Column(
      children: [
        // Tabla principal
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                showCheckboxColumn: true,
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
      DataCell(
        Text(
          reserva.reservaCodigo.toString(),
          style: const TextStyle(fontWeight: FontWeight.w500),
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
        Text(reserva.tipoServicioDescripcion, overflow: TextOverflow.ellipsis),
      ),
      DataCell(
        Text(reserva.reservaPuntoEncuentro, overflow: TextOverflow.ellipsis),
      ),
      DataCell(
        Text(reserva.reservaRepresentante, overflow: TextOverflow.ellipsis),
      ),
      if (widget.mostrarColumnaFecha)
        DataCell(Text(_formatearFecha(reserva.reservaFecha))),
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
      DataCell(Text(reserva.agenciaNombre, overflow: TextOverflow.ellipsis)),
      DataCell(Text(reserva.numeroTickete ?? 'N/A')),
      DataCell(Text(reserva.numeroHabitacion ?? 'N/A')),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _obtenerColorEstado(reserva.colorPrefijo).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _obtenerColorEstado(reserva.colorPrefijo),
              width: 1,
            ),
          ),
          child: Text(
            reserva.estadoNombre,
            style: TextStyle(
              color: _obtenerColorEstado(reserva.colorPrefijo),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      DataCell(
        Text(
          _formatearMoneda(reserva.saldo),
          style: TextStyle(
            color: reserva.saldo > 0 ? Colors.green.shade700 : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      DataCell(
        Text(
          _formatearMoneda(reserva.deuda),
          style: TextStyle(
            color: reserva.deuda > 0
                ? Colors.red.shade700
                : Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      if (widget.mostrarColumnaObservaciones)
        DataCell(
          reserva.observaciones != null && reserva.observaciones!.isNotEmpty
              ? Tooltip(
                  message: reserva.observaciones!,
                  child: const Icon(Icons.note, color: Colors.blue, size: 20),
                )
              : const Icon(Icons.note_outlined, color: Colors.grey, size: 20),
        ),
    ];

    return DataRow(
      selected: _selectedRows.contains(index),
      onSelectChanged: (selected) {
        setState(() {
          if (selected ?? false) {
            _selectedRows.add(index);
          } else {
            _selectedRows.remove(index);
          }
        });
      },
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
      const DataCell(Text('')), // Código
      const DataCell(Text('')), // Contactos
      const DataCell(Text('')), // Servicio
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
      ),
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
      ),
      const DataCell(Text('')), // Agencia
      const DataCell(Text('')), // Ticket
      const DataCell(Text('')), // Habitación
      const DataCell(Text('')), // Estado
      DataCell(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _formatearMoneda(totalSaldos),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
        ),
      ),
      DataCell(
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _formatearMoneda(totalDeudas),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ),
      ),
      if (widget.mostrarColumnaObservaciones)
        const DataCell(Text('')), // Observaciones
    ];

    return DataRow(
      color: WidgetStateProperty.all(Colors.grey.shade100),
      cells: celdasTotales,
    );
  }
}
