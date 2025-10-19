import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:citytourscartagena/core/utils/colors.dart';

class EditarReservaScreen extends StatefulWidget {
  final ReservaResumen reserva;

  const EditarReservaScreen({super.key, required this.reserva});

  @override
  State<EditarReservaScreen> createState() => _EditarReservaScreenState();
}

class _EditarReservaScreenState extends State<EditarReservaScreen> {
  AgenciaSupabase? _selectedAgencia;
  List<AgenciaSupabase> _agencias = [];
  bool _loading = true;

  // Nuevos campos
  DateTime? _selectedFecha;
  final TextEditingController _ticketController = TextEditingController();
  final TextEditingController _habitacionController = TextEditingController();
  final TextEditingController _puntoEncuentroController = TextEditingController();

  // Para el diálogo de agencia
  AgenciaSupabase? _tempSelectedAgencia;
  final TextEditingController _searchController = TextEditingController();

  // Valores originales para detectar cambios
  AgenciaSupabase? _originalAgencia;
  DateTime? _originalFecha;
  String _originalTicket = '';
  String _originalHabitacion = '';
  String _originalPuntoEncuentro = '';

  @override
  void initState() {
    super.initState();
    _cargarAgencias();
    // Inicializar con valores actuales
    _selectedFecha = widget.reserva.reservaFecha;
    _ticketController.text = widget.reserva.numeroTickete ?? '';
    _habitacionController.text = widget.reserva.numeroHabitacion ?? '';
    _puntoEncuentroController.text = widget.reserva.reservaPuntoEncuentro;
  }

  Future<void> _cargarAgencias() async {
    final controller = Provider.of<ControladorDeltaReservas>(context, listen: false);
    try {
      _agencias = await controller.agenciasService.obtenerAgenciasDeOperador(operadorCod: 1); // Ajusta operador
      _selectedAgencia = _agencias.firstWhere((a) => a.nombre == widget.reserva.agenciaNombre);
      // Inicializar valores originales
      _originalAgencia = _selectedAgencia;
      _originalFecha = _selectedFecha;
      _originalTicket = _ticketController.text;
      _originalHabitacion = _habitacionController.text;
      _originalPuntoEncuentro = _puntoEncuentroController.text;
    } catch (e) {
      // Manejar error
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFecha ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedFecha = picked);
    }
  }

  void _mostrarDialogoSeleccionAgencia() {
    _tempSelectedAgencia = _selectedAgencia;
    _searchController.clear();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.business,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              const Text(
                'Seleccionar Agencia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar agencia',
                    hintText: 'Escribe para filtrar...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _agencias
                      .where((agencia) => agencia.nombre.toLowerCase().contains(_searchController.text.toLowerCase()))
                      .isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron agencias',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _agencias
                              .where((agencia) => agencia.nombre.toLowerCase().contains(_searchController.text.toLowerCase()))
                              .length,
                          itemBuilder: (context, index) {
                            final agencia = _agencias
                                .where((agencia) => agencia.nombre.toLowerCase().contains(_searchController.text.toLowerCase()))
                                .elementAt(index);
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: RadioListTile<AgenciaSupabase>(
                                title: Text(
                                  agencia.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                value: agencia,
                                groupValue: _tempSelectedAgencia,
                                onChanged: (value) => setState(() => _tempSelectedAgencia = value),
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _tempSelectedAgencia != null
                  ? () {
                      // Actualizar el estado del widget principal
                      this.setState(() => _selectedAgencia = _tempSelectedAgencia);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Seleccionar',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Reserva'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la sección
                    Text(
                      'Información de la Reserva',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Card para agrupar los campos
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Campo Agencia con botón de selección
                            InkWell(
                              onTap: _mostrarDialogoSeleccionAgencia,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Agencia',
                                  labelStyle: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedAgencia?.nombre ?? 'Seleccionar agencia',
                                        style: TextStyle(
                                          color: _selectedAgencia != null ? Colors.black87 : Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Campo Fecha
                            InkWell(
                              onTap: _seleccionarFecha,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Fecha de Reserva',
                                  labelStyle: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.primary.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  _selectedFecha != null
                                      ? _selectedFecha!.toLocal().toString().split(' ')[0]
                                      : 'Seleccionar fecha',
                                  style: TextStyle(
                                    color: _selectedFecha != null ? Colors.black87 : Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Campo Ticket
                            TextField(
                              controller: _ticketController,
                              decoration: InputDecoration(
                                labelText: 'Número de Ticket',
                                labelStyle: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.confirmation_number,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Campo Habitación
                            TextField(
                              controller: _habitacionController,
                              decoration: InputDecoration(
                                labelText: 'Número de Habitación',
                                labelStyle: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.hotel,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Campo Punto de Encuentro
                            TextField(
                              controller: _puntoEncuentroController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Punto de Encuentro',
                                labelStyle: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.location_on,
                                  color: AppColors.primary.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _guardar,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar Cambios'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _guardar() async {
    if (_selectedAgencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona una agencia'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // Verificar si algo cambió
    bool algoCambio = _selectedAgencia != _originalAgencia ||
                      _selectedFecha != _originalFecha ||
                      _ticketController.text != _originalTicket ||
                      _habitacionController.text != _originalHabitacion ||
                      _puntoEncuentroController.text != _originalPuntoEncuentro;

    if (!algoCambio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No hay cambios para guardar'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // Diálogo de confirmación mejorado
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.save,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmar Cambios',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres guardar los cambios en la reserva?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Guardar',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final controller = Provider.of<ControladorDeltaReservas>(context, listen: false);
    try {
      await controller.actualizarReserva(
        reservaId: widget.reserva.reservaCodigo,
        agenciaCodigo: _selectedAgencia?.codigo,
        reservaFecha: _selectedFecha?.toIso8601String(),
        numeroTickete: _ticketController.text.trim().isEmpty ? null : _ticketController.text.trim(),
        numeroHabitacion: _habitacionController.text.trim().isEmpty ? null : _habitacionController.text.trim(),
        reservaPuntoEncuentro: _puntoEncuentroController.text.trim().isEmpty ? null : _puntoEncuentroController.text.trim(),
        usuarioId: 1,
      );
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Reserva actualizada exitosamente'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}