import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/mvvc/configuracion_controller.dart';
import 'package:citytourscartagena/core/utils/extensions.dart';
import 'package:citytourscartagena/core/utils/parsers/text_parser.dart';
import 'package:citytourscartagena/core/widgets/agencia_selector.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../mvvc/agencias_controller.dart';
import '../mvvc/reservas_controller.dart';

class AddReservaProForm extends StatefulWidget {
  final TurnoType? turno;
  final VoidCallback onAdd;
  const AddReservaProForm({super.key, required this.onAdd, this.turno});

  @override
  State<AddReservaProForm> createState() => _AddReservaProFormState();
}

class _AddReservaProFormState extends State<AddReservaProForm> {
  final _textController = TextEditingController();
  Map<String, dynamic>? _parsedData;
  bool _showPreview = false;
  bool _isLoading = false;
  bool _agencyError = false;
  String? _selectedAgenciaId;
  bool _turnoError = false;
  TurnoType? _selectedTurno;

  // Instancia de TextParser
  final TextParser _textParser = TextParser();

  @override
  void initState() {
    super.initState();
    _selectedTurno = widget.turno;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // 1) Obtén config y agencia (o null si aún no elegida)
      final config = context.read<ConfiguracionController>().configuracion;
      final agencia = _selectedAgenciaId != null
          ? context.read<AgenciasController>().getAgenciaById(
              _selectedAgenciaId!,
            )
          : null;

      // 2) Llama a la función única
      final precio = obtenerPrecioAsiento(
        turno: _selectedTurno,
        config: config,
        agencia: agencia,
      );

      if (precio > 0) {
      }

      _parseText();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  double obtenerPrecioAsiento({
    TurnoType? turno,
    Configuracion? config,
    Agencia? agencia,
  }) {
    // primero precio de agencia, si lo tiene y es >0
    if (agencia != null) {
      final precioAg = turno == TurnoType.manana
          ? agencia.precioPorAsientoTurnoManana
          : agencia.precioPorAsientoTurnoTarde;
      if (precioAg != null && precioAg > 0) return precioAg;
    }
    // si no, precio global según turno
    if (config != null) {
      return turno == TurnoType.manana
          ? config.precioGeneralAsientoTemprano
          : config.precioGeneralAsientoTarde;
    }
    return 0.0;
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

  EstadoReserva _computeEstado(double costoAsiento) {
    if (_parsedData == null) return EstadoReserva.pendiente;

    final pax = _parsedData!['pax'] as int? ?? 1;
    final saldo = _parsedData!['saldo'] as double? ?? 0.0;

    return saldo == pax * costoAsiento
        ? EstadoReserva.pagada
        : EstadoReserva.pendiente;
  }

  Future<void> _submitReserva() async {
    debugPrint('Submitting reserva with data: $_parsedData');

    if (_selectedAgenciaId == null) {
      // Mostrar mensaje emergente si no hay agencia seleccionada
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Agencia requerida'),
          content: const Text('Por favor selecciona una agencia.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }
    final fechaRaw = _parsedData?['fechaReserva'] as String?;
    final nombreCliente = _parsedData?['nombreCliente'] as String?;
    final telefono = _parsedData?['telefono'] as String?;
    final hotel = _parsedData?['hotel'] as String?; 
    final turno = _selectedTurno;

    if (fechaRaw == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Fecha requerida'),
          content: const Text('Por favor ingresa la fecha de la reserva.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    } else if (nombreCliente == null || nombreCliente.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nombre requerido'),
          content: const Text('Por favor ingresa el nombre del cliente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    } else if (telefono == null || telefono.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Teléfono requerido'),
          content: const Text('Por favor ingresa el teléfono del cliente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    } else if (hotel == null || hotel.isEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Hotel requerido'),
          content: const Text('Por favor ingresa el hotel del cliente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    } else if (turno == null) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Turno requerido'),
          content: const Text('Por favor selecciona un turno.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
      return;
    }

    // Obtener la agencia seleccionada para verificar su precio específico
    // final agenciasController = Provider.of<AgenciasController>(
    //   context,
    //   listen: false,
    // );
    // Obtener agencia seleccionada (si existe)
    final selectedAgencia = _selectedAgenciaId != null
        ? context.read<AgenciasController>().getAgenciaById(_selectedAgenciaId!)
        : null;

    final costoAsiento = obtenerPrecioAsiento(
      turno: _selectedTurno,
      config: context.read<ConfiguracionController>().configuracion,
      agencia: selectedAgencia,
    );
    if (costoAsiento <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: precio por asiento no válido, comunícate con el administrador',
          ),
        ),
      );
      return;
    }

    // Resetear error de agencia y validar que tengamos datos parseados
    if (_agencyError) setState(() => _agencyError = false);
    if (_parsedData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta texto o seleccionar agencia')),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Validar que los campos requeridos estén presentes
    // aqui saldo es  = a _parsedData que es un mapa
    final pax = _parsedData!['pax'] as int? ?? 1;
    final saldo = _parsedData!['saldo'] as double? ?? 0.0;
    // calcular total esperado y determinar estado
    final estado = _computeEstado(costoAsiento);
    // final estado = saldo > 0
    //     ? EstadoReserva.pagada
    //     : EstadoReserva.pendiente;
    // final telefono = (_parsedData!['telefono'] as String?)?.trim() ?? '';

    final newReserva = Reserva(
      id: '',
      nombreCliente: _parsedData!['nombreCliente'] as String,
      hotel: _parsedData!['hotel'] as String? ?? '',
      fecha: _parsedData!['fechaReserva'] != null
          ? DateTime.parse(_parsedData!['fechaReserva'] as String)
          : DateTime.now(),
      pax: pax,
      saldo: saldo,
      observacion: _parsedData!['observacion'] as String? ?? '',
      agenciaId: _selectedAgenciaId!,
      estado: estado,
      costoAsiento: costoAsiento, // Usar el costoAsiento determinado
      telefono: telefono,
      turno: turno,
    );

    try {
      await context.read<ReservasController>().addReserva(newReserva);
      widget.onAdd();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva Pro creada (${estado.name})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creando reserva: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedAgencia = _selectedAgenciaId != null
        ? context.read<AgenciasController>().getAgenciaById(_selectedAgenciaId!)
        : null;

    // Precio global definido en configuración
    // final globalPrecio = context
    //         .watch<ConfiguracionController>()
    //         .configuracion
    //         ?.precioPorAsiento ??
    //     0.0;
    // Obtenemos configuración y agencia
  final config  = context.watch<ConfiguracionController>().configuracion;
     // Usamos la función helper para determinar el precio a mostrar
    final usedPrice = obtenerPrecioAsiento(
    turno:   _selectedTurno,
    config:  config,
    agencia: selectedAgencia,
  );
    // // Calcular precio a mostrar según turno y existencia de precio en agencia
    // double usedPrice;
    // String priceSource;
    // if (widget.turno == TurnoType.manana) {
    //   usedPrice = selectedAgencia?.precioPorAsientoTurnoManana ?? globalPrecio;
    //   priceSource =
    //       (selectedAgencia != null &&
    //           selectedAgencia.precioPorAsientoTurnoManana != null)
    //       ? 'Agencia (mañana)'
    //       : 'Global';
    // } else if (widget.turno == TurnoType.tarde) {
    //   usedPrice = selectedAgencia?.precioPorAsientoTurnoTarde ?? globalPrecio;
    //   priceSource =
    //       (selectedAgencia != null &&
    //           selectedAgencia.precioPorAsientoTurnoTarde != null)
    //       ? 'Agencia (tarde)'
    //       : 'Global';
    // } else {
    //   usedPrice = globalPrecio;
    //   priceSource = 'Global';
    // }

    // Fuente de precio para la etiqueta
  final priceSource = (selectedAgencia != null &&
      ((_selectedTurno == TurnoType.manana && selectedAgencia.precioPorAsientoTurnoManana != null && selectedAgencia.precioPorAsientoTurnoManana! > 0) ||
       (_selectedTurno == TurnoType.tarde  && selectedAgencia.precioPorAsientoTurnoTarde  != null && selectedAgencia.precioPorAsientoTurnoTarde!  > 0)))
    ? 'Agencia'
    : 'Global';

    final priceLabel = 'Precio asiento ($priceSource)';

    final computedEstado = _parsedData != null
        ? _computeEstado(usedPrice)
        : EstadoReserva.pendiente;

    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final double availableHeight =
        MediaQuery.of(context).size.height * 0.9 - keyboardInset;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: availableHeight,
          minHeight: MediaQuery.of(context).size.height * 0.5,
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
                    AgenciaSelector(
                      selectedAgenciaId: _selectedAgenciaId,
                      onAgenciaSelected: (id) {
                        setState(() {
                          _selectedAgenciaId = id;
                          _agencyError = false;
                        });
                      },
                    ),
                    // Mostrar error si no hay agencia seleccionada
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
                    // Selector de turno justo debajo de la agencia
                    const SizedBox(height: 12),
                    const Text(
                      'Turno *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TurnoType>(
                      value: _selectedTurno,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        errorText: _turnoError ? 'Debes seleccionar un turno' : null,
                      ),
                      items: TurnoType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() {
                        _selectedTurno = value;
                        _turnoError = false;
                      }),
                    ),
                    // Mostrar error si no hay turno seleccionado
                    if (_turnoError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          'Debes seleccionar un turno',
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
                                // _buildPreviewItem(
                                //   'Estado',
                                //   _parsedData!['estado']
                                //       .toString()
                                //       .split('.')
                                //       .last,
                                // ),
                                _buildPreviewItem(
                                  'Observación',
                                  _parsedData!['observacion'],
                                ),
                                _buildPreviewItem(
                                  'Teléfono',
                                  _parsedData!['telefono'] as String?,
                                ),
                                _buildPreviewItem(
                                  priceLabel,
                                  usedPrice.toStringAsFixed(2),
                                ),

                                _buildPreviewItem(
                                  'Turno',
                                  _selectedTurno != null
                                      ? _selectedTurno!.label
                                      : 'No seleccionado',
                                ),
                                _buildPreviewItem(
                                  'Estado calculado',
                                  computedEstado.name,
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
