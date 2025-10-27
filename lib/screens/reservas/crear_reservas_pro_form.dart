import 'dart:math' as math;

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/filtros/servicios_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reservas/crear_reserva_dto.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_contacto.dart';
import 'package:citytourscartagena/core/utils/parsers/text_parser.dart';
import 'package:citytourscartagena/core/widgets/agencia_selector.dart';
import 'package:citytourscartagena/core/widgets/error_dialogs.dart';
import 'package:citytourscartagena/core/widgets/selectores/tipos_servicios_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CrearReservasProForm extends StatefulWidget {
  // final VoidCallback onAdd;
  final Agencia? agencia;
  final int? initialServicioId;

  const CrearReservasProForm({super.key, this.agencia, this.initialServicioId});

  @override
  State<CrearReservasProForm> createState() => _CrearReservasProFormState();
}

class _CrearReservasProFormState extends State<CrearReservasProForm> {
  final _textController = TextEditingController();
  final _costoTotalPrivadoController = TextEditingController();
  Map<String, dynamic>? _parsedData;
  bool _showPreview = false;
  bool _isLoading = false;
  bool _agencyError = false;
  int? _selectedAgenciaId;

  /// id de la agencia pasada
  int? _selectedServicioId;

  /// id del tipo de servicio selecionado
  // TipoServicio? _selectedServicio;
  bool _turnoError = false;
  TurnoType? _selectedTurno;
  bool _costoPrivadoError = false;
  // NUEVO: Hora seleccionada para reservas privadas
  TimeOfDay? _selectedTime;
  bool _horaPrivadoError = false;

  // Instancia de TextParser
  final TextParser _textParser = TextParser();

  @override
  void initState() {
    super.initState();
    _selectedServicioId = widget.initialServicioId;
  }

  @override
  void dispose() {
    _textController.dispose();
    _costoTotalPrivadoController.dispose();
    super.dispose();
  }

  EstadoReserva _computeEstado(double? precioServicio) {
    if (_parsedData == null) return EstadoReserva.pendiente;

    final pax = _parsedData!['pax'] as int? ?? 1;
    final saldo = _parsedData!['saldo'] as double? ?? 0.0;

    // Si el precio viene null, asumimos que es precio total del viaje
    if (precioServicio == null) {
      final total = _parsedData!['total']?.toDouble() ?? 0.0;
      return saldo >= total ? EstadoReserva.pagada : EstadoReserva.pendiente;
    }

    // Si existe precioServicio, se multiplica por pax
    final totalReserva = precioServicio * pax;
    return saldo >= totalReserva
        ? EstadoReserva.pagada
        : EstadoReserva.pendiente;
  }

  void _parseText() {
    final text = _textController.text;
    final agenciasController = Provider.of<AgenciasController>(
      context,
      listen: false,
    );
    final allAgencias = agenciasController.getAllAgencias();

    setState(() {
      _parsedData = text.isNotEmpty
          ? _textParser.parseReservaText(text, allAgencias)
          : null;
      _showPreview = _parsedData != null;
    });
  }

  Future<void> _submitReserva() async {
    try {
      setState(() => _isLoading = true);

      // 1️⃣ Obtener dependencias
      final reservasCtrl = context.read<ControladorDeltaReservas>();
      final operadoresCtrl = context.read<OperadoresController>();

      // 2️⃣ Obtener operador actual
      final operador = await operadoresCtrl.obtenerOperador();
      if (operador == null) {
        await ErrorDialogs.showErrorDialog(
          context,
          'No se encontró el operador.',
        );
        return;
      }

      // 3️⃣ Armar el DTO con los datos del formulario
      final dto = CrearReservaDto(
        reservaFecha: _parsedData?['fechaReserva'] != null
            ? DateTime.parse(_parsedData!['fechaReserva'])
            : DateTime.now(),
        numeroHabitacion: _parsedData?['habitacion'] as String?,
        puntoEncuentro: _parsedData?['puntoEncuentro'] as String?,
        observaciones: _parsedData?['observacion'] as String?,
        pasajeros: _parsedData?['pax'] ?? 1,
        tipoServicioCodigo: _parsedData?['tipoServicioCodigo'] ?? 0,
        agenciaCodigo: _selectedAgenciaId!,
        operadorCodigo: operador.id,
        creadoPor: operador.id,
        representante: _parsedData?['nombreCliente'],
        numeroTickete: _parsedData?['ticket'],
        pagoMonto: _parsedData?['saldo']?.toDouble() ?? 0.0,
        reservaTotal: _parsedData?['total']?.toDouble(),
        colorCodigo: 1,
      );

      // 4️⃣ (Opcional) Agregar contacto si lo tienes en la vista
      final contacto = ReservaContacto(
        tipoContactoCodigo: 1, // teléfono por defecto
        contacto: _parsedData?['telefono'] ?? '',
      );

      // 5️⃣ Llamar al controlador
      await reservasCtrl.crearReservaCompleta(dto: dto, contactos: [contacto]);

      // 6️⃣ Mostrar confirmación y cerrar
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creando reserva: $e');
      await ErrorDialogs.showErrorDialog(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double? _precioServicio;
    double precioPorAsiento;

    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final double minHeight = MediaQuery.of(context).size.height * 0.5;
    final double availableHeight =
        MediaQuery.of(context).size.height * 0.9 - keyboardInset;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: math.max(availableHeight, minHeight),
          minHeight: minHeight,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agregar reserva Pro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agencia *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.agencia != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.business,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Agencia: ${widget.agencia!.nombre} (ID: ${widget.agencia!.id})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      AgenciaSelector(
                        selectedAgenciaId: _selectedAgenciaId,
                        onAgenciaSelected: (id) {
                          setState(() {
                            _selectedAgenciaId = id;
                            _agencyError = false;
                          });
                        },
                      ),
                      if (_agencyError)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            'Debes seleccionar una agencia',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Servicio *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TipoServicioSelector(
                      selectedTipoServicioId: _selectedServicioId,
                      onSelected: (servicio) async {
                        _selectedServicioId = servicio?.codigo;

                        if (servicio != null && _selectedAgenciaId != null) {
                          final reservasCtrl = context
                              .read<ServiciosController>();
                          final precio = await reservasCtrl
                              .obtenerPrecioPorServicio(
                                tipoServicioCodigo: servicio.codigo,
                                agenciaCodigo: _selectedAgenciaId!,
                              );

                          if (mounted) {
                            setState(() => _precioServicio = precio);
                          }
                        } else {
                          setState(() => _precioServicio = null);
                        }
                      },
                    ),

                    // Campo de costo total privado SOLO si es privado
                    if (_precioServicio == null) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _costoTotalPrivadoController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Costo total del servicio *',
                          border: const OutlineInputBorder(),
                          errorText: _costoPrivadoError
                              ? 'Ingresa un valor mayor a 0'
                              : null,
                          prefixIcon: const Icon(Icons.attach_money),
                        ),
                        onChanged: (_) {
                          setState(() => _costoPrivadoError = false);
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Campo Hora para privado
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedTime != null
                                ? 'Hora seleccionada: ${_selectedTime!.format(context)}'
                                : 'Seleccione una hora',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime ?? TimeOfDay.now(),
                              useRootNavigator: true,
                              initialEntryMode: TimePickerEntryMode.dial,
                              builder: (BuildContext ctx, Widget? child) {
                                final mq = MediaQuery.of(ctx).copyWith(
                                  viewInsets: EdgeInsets.zero,
                                  alwaysUse24HourFormat: true,
                                );
                                return MediaQuery(
                                  data: mq,
                                  child: child ?? const SizedBox.shrink(),
                                );
                              },
                            );
                            if (time != null) {
                              setState(() {
                                _selectedTime = time;
                                _horaPrivadoError = false;
                              });
                            }
                          },
                          child: const Text('Seleccionar Hora'),
                        ),
                      ],
                    ),
                    if (_horaPrivadoError)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'La hora es obligatoria para servicio privado',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    if (_showPreview && _parsedData != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.preview,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Vista previa de datos detectados:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPreviewItem(
                                  'Cliente',
                                  _parsedData!['nombreCliente'],
                                ),
                                _buildPreviewItem(
                                  'Hotel',
                                  _parsedData!['hotel'],
                                ),
                                _buildPreviewItem(
                                  'Fecha',
                                  _parsedData!['fechaReserva'] != null
                                      ? DateFormat('dd-MM-yyyy').format(
                                          DateTime.parse(
                                            _parsedData!['fechaReserva']
                                                as String,
                                          ).toLocal(),
                                        )
                                      : 'No detectada',
                                ),
                                _buildPreviewItem(
                                  'PAX',
                                  _parsedData!['pax'].toString(),
                                ),
                                _buildPreviewItem(
                                  'Saldo',
                                  _parsedData!['saldo'].toString(),
                                ),
                                _buildPreviewItem(
                                  'Observación',
                                  _parsedData!['observacion'],
                                ),
                                _buildPreviewItem(
                                  'Teléfono',
                                  _parsedData!['telefono'] as String?,
                                ),
                                _buildPreviewItem(
                                  _precioServicio == null
                                      ? 'Precio por viaje'
                                      : 'Precio por asiento',
                                  (_precioServicio ?? 0).toStringAsFixed(2),
                                ),
                                _buildPreviewItem(
                                  'Turno',
                                  _selectedTurno != null
                                      ? _selectedTurno!.label
                                      : 'No seleccionado',
                                ),
                                _buildPreviewItem(
                                  'Estado calculado',
                                  _computeEstado(_precioServicio).name,
                                ),
                                _buildPreviewItem(
                                  'Habitación',
                                  _parsedData!['habitacion'] as String?,
                                ),
                                _buildPreviewItem(
                                  'Ticket',
                                  _parsedData!['ticket'] as String?,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'Texto de la reserva:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      minLines: 3,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Pega aquí los datos de la reserva...',
                        alignLabelWithHint: true,
                      ),
                      onChanged: (_) {
                        final text = _textController.text;
                        final newText = text.replaceAll('*', '');
                        if (newText != text) {
                          final cursorPos =
                              _textController.selection.baseOffset;
                          _textController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset:
                                  (cursorPos - (text.length - newText.length))
                                      .clamp(0, newText.length),
                            ),
                          );
                        }
                        _parseText();
                      },
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Instrucciones del Modo Pro',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pega o escribe los datos de la reserva en formato libre. El sistema detectará automáticamente:\n'
                            '• Nombre/Cliente\n'
                            '• Hotel\n'
                            '• Fecha (dd-mm-yy o yyyy-mm-dd)\n'
                            '• PAX/Personas\n'
                            '• Saldo/Precio\n'
                            '• Observaciones\n'
                            '• Estado (confirmada/pendiente/cancelada)\n',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReserva,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Crear Reserva Pro'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String? value) {
    final displayValue = value?.isEmpty ?? true ? '(vacío)' : value!;
    final isValueEmpty = value?.isEmpty ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 13,
              color: isValueEmpty ? Colors.grey : Colors.black,
              fontStyle: isValueEmpty ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
