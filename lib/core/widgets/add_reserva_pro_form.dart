import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/widgets/agencia_selector.dart';
import 'package:flutter/material.dart';

import '../mvvc/reservas_controller.dart';
import '../utils/text_parser.dart';

class AddReservaProForm extends StatefulWidget {
  final VoidCallback onAdd;

  const AddReservaProForm({super.key, required this.onAdd});

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

  @override
  void initState() {
    super.initState();
    // Cargar ejemplo por defecto
    _textController.text = TextParser.getExampleText();
    _parseText();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _parseText() {
    final text = _textController.text;
    setState(() {
      _parsedData = text.isNotEmpty ? TextParser.parseReservaText(text) : null;
      _showPreview = _parsedData != null;
    });
  }

  Future<void> _submitReserva() async {
    // 2) validación agencia
    if (_selectedAgenciaId == null) {
      setState(() => _agencyError = true);
      return;
    }
    // reset del error para siguientes envíos
    if (_agencyError) setState(() => _agencyError = false);

    if (_parsedData == null || _selectedAgenciaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falta texto o seleccionar agencia')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final saldo = (_parsedData!['saldo'] as double?) ?? 0.0;
    final estado = saldo > 0
        ? EstadoReserva.confirmada
        : EstadoReserva.pendiente;

    final newReserva = Reserva(
      id: '',
      nombreCliente: _parsedData!['nombreCliente'] as String,
      hotel: _parsedData!['hotel'] as String? ?? '',
      fecha: _parsedData!['fecha'] as DateTime? ?? DateTime.now(),
      pax: _parsedData!['pax'] as int? ?? 1,
      saldo: saldo,
      observacion: _parsedData!['observacion'] as String? ?? '',
      agenciaId: _selectedAgenciaId!,
      estado: estado,
    );

    try {
      await ReservasController.addReserva(newReserva);
      widget.onAdd();
      // Usar `pop` para cerrar el modal o la pantalla actual
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reserva Pro creada (${estado.name})'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creando reserva: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el padding del teclado para ajustar la vista
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    // Calcular la altura disponible para el contenido, dejando un margen superior
    // y ajustando por el teclado. Se usa un factor para que no ocupe el 100%
    // y permita ver el fondo si es un modal.
    final double availableHeight = MediaQuery.of(context).size.height * 0.9 - keyboardInset;

    return Padding(
      // Ajustar el padding inferior para evitar que el teclado cubra el contenido
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        // Usar ConstrainedBox para asegurar que el formulario no exceda
        // una altura máxima, pero que también se adapte.
        constraints: BoxConstraints(
          maxHeight: availableHeight,
          minHeight: MediaQuery.of(context).size.height * 0.5, // Altura mínima para pantallas pequeñas
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera y cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agregar reserva Pro',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Aumentar tamaño de fuente
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 24), // Aumentar tamaño del icono
                ),
              ],
            ),
            const SizedBox(height: 20), // Espacio más generoso

            // Contenido scrollable
            Expanded( // Usar Expanded para que el SingleChildScrollView ocupe el espacio restante
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // Efecto de rebote al hacer scroll
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agencia *',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                _buildPreviewItem('Hotel', _parsedData!['hotel']),
                                _buildPreviewItem(
                                  'Fecha',
                                  _parsedData!['fecha']?.toString().split(
                                        ' ',
                                      )[0] ??
                                      'No detectada',
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
                                  'Estado',
                                  _parsedData!['estado']
                                      .toString()
                                      .split('.')
                                      .last,
                                ),
                                _buildPreviewItem(
                                  'Observación',
                                  _parsedData!['observacion'],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Texto de la reserva (altura automática según contenido)
                    const Text(
                      'Texto de la reserva:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      minLines: 3,
                      maxLines: null, // Permite que el campo crezca con el contenido
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Pega aquí los datos de la reserva...',
                        alignLabelWithHint: true, // Alinea el hint text en la parte superior
                      ),
                      onChanged: (_) => _parseText(),
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
                            '• Estado (confirmada/pendiente/cancelada)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Espacio antes de los botones
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
                        padding: const EdgeInsets.symmetric(vertical: 12), // Aumentar padding vertical
                        textStyle: const TextStyle(fontSize: 16), // Aumentar tamaño de fuente
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_parsedData != null && !_isLoading)
                          ? _submitReserva
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12), // Aumentar padding vertical
                        textStyle: const TextStyle(fontSize: 16), // Aumentar tamaño de fuente
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Color blanco para el indicador
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90, // Ajustar el ancho de la etiqueta para pantallas pequeñas
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: TextStyle(
                fontSize: 13,
                color: isValueEmpty ? Colors.grey : Colors.black,
                fontStyle: isValueEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
