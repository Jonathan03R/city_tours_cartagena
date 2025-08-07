import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
// Importa tus modelos y controladores reales
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/utils/formatters.dart'; // Asumiendo que tienes esta clase
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:provider/provider.dart'; // Para acceder a los controladores

class AddReservaForm extends StatefulWidget {
  final VoidCallback onAdd;
  final String agenciaId; // El ID de la agencia que se recibe por defecto

  const AddReservaForm({
    super.key,
    required this.onAdd,
    required this.agenciaId,
  });

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
  TurnoType? _selectedTurno; // Selector manual para el turno
  Agencia? _selectedAgencia; // Para almacenar el objeto Agencia cargado
  bool _isLoading = false;
  double _costoAsiento = 0.0; // Precio por asiento calculado

  @override
  void initState() {
    super.initState();
    // Establece un turno por defecto, por ejemplo, mañana
    _selectedTurno = TurnoType.manana;
    // Carga la información de la agencia y calcula el precio inicial
    // Se usa addPostFrameCallback para asegurar que el contexto esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAgenciaAndCalculatePrice();
    });

    // Añadir listeners para recalcular el estado y el costo total
    _paxController.addListener(_recalculateStatusAndTotal);
    _saldoController.addListener(_recalculateStatusAndTotal);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _hotelController.dispose();
    _paxController.removeListener(_recalculateStatusAndTotal);
    _paxController.dispose();
    _saldoController.removeListener(_recalculateStatusAndTotal);
    _saldoController.dispose();
    _observacionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  // Función auxiliar para obtener el precio del asiento, similar a AddReservaProForm
  double _obtenerPrecioAsiento({
    TurnoType? turno,
    Configuracion? config,
    Agencia? agencia,
  }) {
    // Primero, verifica el precio específico de la agencia para el turno
    if (agencia != null) {
      final precioAg = turno == TurnoType.manana
          ? agencia.precioPorAsientoTurnoManana
          : agencia.precioPorAsientoTurnoTarde;
      if (precioAg != null && precioAg > 0) return precioAg;
    }
    // Si no hay precio específico de agencia o es 0, usa el precio global
    if (config != null) {
      return turno == TurnoType.manana
          ? config.precioGeneralAsientoTemprano
          : config.precioGeneralAsientoTarde;
    }
    return 0.0; // Valor por defecto si no se puede determinar el precio
  }

  // Carga la agencia y calcula el precio inicial
  Future<void> _loadAgenciaAndCalculatePrice() async {
    if (!mounted) return; // Asegura que el widget sigue montado
    final agenciasController = context.read<AgenciasController>();
    final configController = context.read<ConfiguracionController>();

    final agencia = agenciasController.getAgenciaById(widget.agenciaId);
    final config = configController.configuracion;

    setState(() {
      _selectedAgencia = agencia;
      _costoAsiento = _obtenerPrecioAsiento(
        turno: _selectedTurno,
        config: config,
        agencia: _selectedAgencia,
      );
    });
    _recalculateStatusAndTotal(); // Recalcula el estado y el total después de cargar la agencia
  }

  // Función para recalcular el estado y el costo total
  void _recalculateStatusAndTotal() {
    if (!mounted) return;

    // Recalcula el costo del asiento por si ha cambiado la configuración o el turno
    final currentCostoAsiento = _obtenerPrecioAsiento(
      turno: _selectedTurno,
      config: context.read<ConfiguracionController>().configuracion,
      agencia: _selectedAgencia,
    );

    setState(() {
      _costoAsiento = currentCostoAsiento; // Actualiza el costo del asiento
    });
  }

  // Función auxiliar para determinar el estado de la reserva
  EstadoReserva _computeEstado(double costoAsiento, int pax, double saldo) {
    final double costoTotal = costoAsiento * pax;
    final double diferencia = costoTotal - saldo;

    if (diferencia <= 0) {
      return EstadoReserva.pagada;
    } else {
      return EstadoReserva.pendiente;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedAgencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo cargar la información de la agencia.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTurno == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un turno.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final int pax = int.tryParse(_paxController.text) ?? 1;
      final double saldo = double.tryParse(_saldoController.text) ?? 0.0;

      // Recalcula el costo del asiento justo antes de enviar, por si hubo cambios
      final currentCostoAsiento = _obtenerPrecioAsiento(
        turno: _selectedTurno,
        config: context.read<ConfiguracionController>().configuracion,
        agencia: _selectedAgencia,
      );

      if (currentCostoAsiento <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: precio por asiento no válido, comunícate con el administrador',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Calcula el estado basado en la nueva lógica
      final estado = _computeEstado(currentCostoAsiento, pax, saldo);

      final newReserva = Reserva(
        id: '', // Se asignará en Firebase o en tu backend
        nombreCliente: _nombreController.text.trim(),
        hotel: _hotelController.text.trim(),
        pax: pax,
        saldo: saldo,
        observacion: _observacionController.text.trim(),
        fecha: _selectedDate,
        agenciaId: widget.agenciaId, // Usa el agenciaId que se pasó al widget
        estado: estado, // Usa el estado calculado
        costoAsiento: currentCostoAsiento,
        telefono: _telefonoController.text.trim(),
        turno: _selectedTurno,
      );

      final reservasController = context.read<ReservasController>();
      await reservasController.addReserva(newReserva);

      widget.onAdd(); // Llama al callback de éxito
      if (mounted) {
        Navigator.of(context).pop(); // Cierra el formulario
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva agregada exitosamente (${estado.name})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error agregando reserva: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa los cambios en la configuración para recalcular el precio si es necesario
    final config = context.watch<ConfiguracionController>().configuracion;
    _costoAsiento = _obtenerPrecioAsiento(
      turno: _selectedTurno,
      config: config,
      agencia: _selectedAgencia,
    );

    // Calcula el estado actual para mostrarlo en la UI (no editable)
    final int currentPax = int.tryParse(_paxController.text) ?? 1;
    final double currentSaldo = double.tryParse(_saldoController.text) ?? 0.0;
    final EstadoReserva currentComputedEstado =
        _computeEstado(_costoAsiento, currentPax, currentSaldo);

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
            // Muestra la información de la agencia (no editable)
            _buildAgenciaInfo(context),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Cliente *', _nombreController, Icons.person,
                        required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Hotel', _hotelController, Icons.hotel),
                    const SizedBox(height: 16),
                    // Muestra el estado calculado, no un selector
                    _buildCalculatedEstadoInfo(currentComputedEstado),
                    const SizedBox(height: 16),
                    _buildTurnoSelector(), // Selector para el turno
                    const SizedBox(height: 16),
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildTextField('PAX *', _paxController, Icons.people,
                        keyboardType: TextInputType.number, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Saldo *', _saldoController, Icons.attach_money,
                        keyboardType: TextInputType.number, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Teléfono', _telefonoController, Icons.phone,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField('Observaciones', _observacionController, Icons.note,
                        maxLines: 3),
                    const SizedBox(height: 16),
                    // Muestra el precio por asiento calculado
                    _buildPriceInfo(),
                    const SizedBox(height: 16),
                    _buildTotalCostInfo(currentPax, currentSaldo), // Nuevo: Muestra el costo total y la diferencia
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
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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

  // Widget para construir campos de texto
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

  // Nuevo Widget para mostrar el estado calculado (no editable)
  Widget _buildCalculatedEstadoInfo(EstadoReserva estado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info, size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Estado Calculado', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: estado == EstadoReserva.pagada ? Colors.green.shade50 : Colors.orange.shade50,
          ),
          child: Text(
            Formatters.getEstadoText(estado),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: estado == EstadoReserva.pagada ? Colors.green.shade800 : Colors.orange.shade800,
            ),
          ),
        ),
      ],
    );
  }

  // Widget para seleccionar el turno
  Widget _buildTurnoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Turno *', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TurnoType>(
          value: _selectedTurno,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: TurnoType.values.map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(t.label), // Asumiendo que TurnoType tiene un getter 'label'
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTurno = value;
              // Recalcula el precio y el estado cuando el turno cambia
              _recalculateStatusAndTotal();
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Debes seleccionar un turno';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Widget para seleccionar la fecha
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Fecha *', style: TextStyle(fontWeight: FontWeight.bold)),
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
                Text(DateFormat('dd-MM-yyyy').format(_selectedDate)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget para mostrar la información de la agencia (no editable)
  Widget _buildAgenciaInfo(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.business, size: 16, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Text(
          'Agencia: ${_selectedAgencia?.nombre ?? 'Cargando...'} (ID: ${widget.agenciaId})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Widget para mostrar el precio por asiento calculado
  Widget _buildPriceInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            'Precio por asiento: \$${_costoAsiento.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Nuevo Widget para mostrar el costo total y la diferencia
  Widget _buildTotalCostInfo(int pax, double saldo) {
    final double costoTotal = _costoAsiento * pax;
    final double diferencia = costoTotal - saldo;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Costo Total: \$${costoTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                diferencia > 0 ? Icons.warning : Icons.check_circle,
                size: 20,
                color: diferencia > 0 ? Colors.orange.shade700 : Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                diferencia > 0
                    ? 'Pendiente: \$${diferencia.toStringAsFixed(2)}'
                    : 'Pagado: \$${(-diferencia).toStringAsFixed(2)} (sobrante)'
                        .replaceAll('\$-', '\$'), // Elimina el signo negativo si es sobrante
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: diferencia > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}