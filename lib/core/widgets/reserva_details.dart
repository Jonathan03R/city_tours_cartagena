import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:flutter/material.dart';

import '../controller/reservas_controller.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class ReservaDetails extends StatefulWidget {
  final ReservaConAgencia reserva;
  final VoidCallback onUpdate;

  const ReservaDetails({
    Key? key,
    required this.reserva,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<ReservaDetails> createState() => _ReservaDetailsState();
}

class _ReservaDetailsState extends State<ReservaDetails> {
  bool _isEditing = false;
  bool _isLoading = false;
  late TextEditingController _nombreController;
  late TextEditingController _hotelController;
  late TextEditingController _paxController;
  late TextEditingController _saldoController;
  late TextEditingController _observacionController;
  late DateTime _selectedDate;
  late EstadoReserva _selectedEstado;
  late String _selectedAgenciaId;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nombreController = TextEditingController(text: widget.reserva.nombreCliente);
    _hotelController = TextEditingController(text: widget.reserva.hotel);
    _paxController = TextEditingController(text: widget.reserva.pax.toString());
    _saldoController = TextEditingController(text: widget.reserva.saldo.toString());
    _observacionController = TextEditingController(text: widget.reserva.observacion);
    _selectedDate = widget.reserva.fecha;
    _selectedEstado = widget.reserva.estado;
    _selectedAgenciaId = widget.reserva.agenciaId;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _hotelController.dispose();
    _paxController.dispose();
    _saldoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedReserva = widget.reserva.reserva.copyWith(
        nombreCliente: _nombreController.text,
        hotel: _hotelController.text,
        estado: _selectedEstado,
        fecha: _selectedDate,
        pax: int.tryParse(_paxController.text) ?? widget.reserva.pax,
        saldo: double.tryParse(_saldoController.text) ?? widget.reserva.saldo,
        agenciaId: _selectedAgenciaId,
        observacion: _observacionController.text,
      );

      await ReservasController().updateReserva(widget.reserva.id, updatedReserva);
      widget.onUpdate();
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva actualizada exitosamente'),
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
            content: Text('Error actualizando reserva: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalles de la Reserva',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'ID: ${widget.reserva.id}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Estado actual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getEstadoBackgroundColor(widget.reserva.estado),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getEstadoIcon(widget.reserva.estado),
                  color: AppColors.getEstadoColor(widget.reserva.estado),
                ),
                const SizedBox(width: 8),
                Text(
                  'Estado: ${Formatters.getEstadoText(widget.reserva.estado)}',
                  style: TextStyle(
                    color: AppColors.getEstadoColor(widget.reserva.estado),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              child: _isEditing ? _buildEditForm() : _buildDetailsView(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Botones de acción
          SizedBox(
            width: double.infinity,
            child: _isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _isEditing = false;
                              _initializeControllers();
                            });
                          },
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Guardar'),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    child: const Text('Editar Reserva'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem('Cliente', widget.reserva.nombreCliente, Icons.person),
        _buildDetailItem('Hotel', widget.reserva.hotel.isEmpty ? 'No especificado' : widget.reserva.hotel, Icons.hotel),
        _buildDetailItem('Fecha', Formatters.formatDateLong(widget.reserva.fecha), Icons.calendar_today),
        _buildDetailItem('PAX', '${widget.reserva.pax} persona${widget.reserva.pax != 1 ? 's' : ''}', Icons.people),
        _buildDetailItem('Saldo', Formatters.formatCurrency(widget.reserva.saldo), Icons.attach_money),
        _buildDetailItem('Agencia', widget.reserva.nombreAgencia, Icons.business),
        _buildDetailItem('Observaciones', widget.reserva.observacion.isEmpty ? 'Sin observaciones' : widget.reserva.observacion, Icons.note),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Cliente', _nombreController, Icons.person),
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
        const Text('Agencia', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // AgenciaSelector(
        //   selectedAgenciaId: _selectedAgenciaId,
        //   onAgenciaSelected: (agenciaId) {
        //     setState(() {
        //       _selectedAgenciaId = agenciaId;
        //     });
        //   },
        // ),
        const SizedBox(height: 16),
        _buildTextField('Observaciones', _observacionController, Icons.note, maxLines: 3),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
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
              child: Row(
                children: [
                  Icon(
                    _getEstadoIcon(estado),
                    color: AppColors.getEstadoColor(estado),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(Formatters.getEstadoText(estado)),
                ],
              ),
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

  IconData _getEstadoIcon(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.pagada:
        return Icons.check_circle;
      case EstadoReserva.pendiente:
        return Icons.schedule;
      case EstadoReserva.cancelada:
        return Icons.cancel;
    }
  }
}
