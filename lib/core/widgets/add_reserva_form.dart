import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/services/configuracion_service.dart';
import 'package:flutter/material.dart';

import '../mvvc/reservas_controller.dart';
import '../utils/formatters.dart';
import 'agencia_selector.dart';

class AddReservaForm extends StatefulWidget {
  final VoidCallback onAdd;

  const AddReservaForm({super.key, required this.onAdd});

  @override
  State<AddReservaForm> createState() => _AddReservaFormState();
}

class _AddReservaFormState extends State<AddReservaForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _hotelController = TextEditingController();
  final _paxController = TextEditingController(text: '1');
  final _saldoController = TextEditingController(text: '0');
  final _observacionController = TextEditingController();
  final _telefonoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  EstadoReserva _selectedEstado = EstadoReserva.pendiente;
  String? _selectedAgenciaId;
  bool _isLoading = false;

  double _precioPorAsiento = 0.0;

  @override
  void dispose() {
    _nombreController.dispose();
    _hotelController.dispose();
    _paxController.dispose();
    _saldoController.dispose();
    _observacionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
/// The initState function in Dart is used to initialize the state of a widget and in this case, it
/// calls the _cargarPrecioPorAsiento function.
  void initState() {
    super.initState();
    _cargarPrecioPorAsiento();
  }

  /// 1) Carga el precio por asiento desde Firestore
  Future<void> _cargarPrecioPorAsiento() async {
    final config = await ConfiguracionService.getConfiguracion();
    if (config != null) {
      setState(() {
        _precioPorAsiento = config.precioPorAsiento;
      });
    }
  }


  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedAgenciaId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final newReserva = Reserva(
          id: '', // Se asignará en Firebase
          nombreCliente: _nombreController.text,
          hotel: _hotelController.text,
          estado: _selectedEstado,
          fecha: _selectedDate,
          pax: int.parse(_paxController.text),
          saldo: double.parse(_saldoController.text),
          agenciaId: _selectedAgenciaId!,
          observacion: _observacionController.text,
          costoAsiento: _precioPorAsiento,
          telefono: _telefonoController.text.trim(), 
        );

        await ReservasController.addReserva(newReserva);
        widget.onAdd();
        
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reserva agregada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error agregando reserva: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (_selectedAgenciaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una agencia'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agregar Nueva Reserva',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Cliente *', _nombreController, Icons.person, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Hotel', _hotelController, Icons.hotel),
                    const SizedBox(height: 16),
                    _buildEstadoSelector(),
                    const SizedBox(height: 16),
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildTextField('PAX', _paxController, Icons.people, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    _buildTextField('Saldo', _saldoController, Icons.attach_money, keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    _buildTextField('Teléfono',_telefonoController,Icons.phone,keyboardType: TextInputType.phone,required: false,),
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text('Agencia *', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AgenciaSelector(
                      selectedAgenciaId: _selectedAgenciaId,
                      onAgenciaSelected: (agenciaId) {
                        setState(() {
                          _selectedAgenciaId = agenciaId;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Observaciones', _observacionController, Icons.note, maxLines: 3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Agregar Reserva'),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es requerido';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildEstadoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info, size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<EstadoReserva>(
          value: _selectedEstado,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: EstadoReserva.values.map((estado) {
            return DropdownMenuItem(
              value: estado,
              child: Text(Formatters.getEstadoText(estado)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedEstado = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(Formatters.formatDate(_selectedDate)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
