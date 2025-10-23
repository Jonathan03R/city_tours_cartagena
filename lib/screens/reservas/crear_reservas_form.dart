import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/controller/filtros/servicios_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/models/reservas/crear_reserva_dto.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_contacto.dart';
import 'package:citytourscartagena/core/models/operadores/tipo_contacto.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrearReservasForm extends StatefulWidget {
  const CrearReservasForm({super.key});

  @override
  State<CrearReservasForm> createState() => _CrearReservasFormState();
}

class _CrearReservasFormState extends State<CrearReservasForm> {
  final _formKey = GlobalKey<FormState>();
  final _fechaController = TextEditingController();
  final _habitacionController = TextEditingController();
  final _puntoEncuentroController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _pasajerosController = TextEditingController(text: '1');
  final _representanteController = TextEditingController();
  final _numeroTicketeController = TextEditingController();
  final _pagoMontoController = TextEditingController();
  final _reservaTotalController = TextEditingController();
  final _horaController = TextEditingController();

  DateTime? _selectedFecha;
  TimeOfDay? _selectedHora;
  int? _selectedTipoServicio;
  int? _selectedAgencia;

  final List<ReservaContacto> _contactos = [];

  late Future<List<TipoContacto>> _tiposContactoFuture;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final operadoresController = context.read<OperadoresController>();
    _tiposContactoFuture = operadoresController.obtenerTiposContactosActivos();
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _horaController.dispose();
    _habitacionController.dispose();
    _puntoEncuentroController.dispose();
    _observacionesController.dispose();
    _pasajerosController.dispose();
    _representanteController.dispose();
    _numeroTicketeController.dispose();
    _pagoMontoController.dispose();
    _reservaTotalController.dispose();
    super.dispose();
  }

  Future<void> _selectFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedFecha = picked;
        _fechaController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectHora(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedHora ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedHora = picked;
        _horaController.text = picked.format(context);
      });
    }
  }

  void _agregarContacto() {
    final TextEditingController contactoController = TextEditingController();
    int? selectedTipo;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Contacto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<List<TipoContacto>>(
              future: _tiposContactoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No hay tipos de contacto disponibles');
                } else {
                  final tiposContacto = snapshot.data!;
                  return DropdownButtonFormField<int>(
                    value: selectedTipo,
                    items: tiposContacto.map((tipo) => DropdownMenuItem<int>(
                      value: tipo.id,
                      child: Text(tipo.descripcion),
                    )).toList(),
                    onChanged: (value) => selectedTipo = value,
                    decoration: const InputDecoration(labelText: 'Tipo de Contacto'),
                  );
                }
              },
            ),
            TextField(
              controller: contactoController,
              decoration: const InputDecoration(labelText: 'Contacto'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedTipo != null && contactoController.text.isNotEmpty) {
                setState(() {
                  _contactos.add(ReservaContacto(
                    tipoContactoCodigo: selectedTipo!,
                    contacto: contactoController.text,
                  ));
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _removerContacto(int index) {
    setState(() {
      _contactos.removeAt(index);
    });
  }

  Future<void> _crearReserva() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha')),
      );
      return;
    }

    if (_selectedTipoServicio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de servicio')),
      );
      return;
    }

    if (_selectedAgencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una agencia')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authController = context.read<AuthSupabaseController>();
      final operadorController = context.read<OperadoresController>();
      final reservasController = context.read<ControladorDeltaReservas>();

      final operador = await operadorController.obtenerOperador();
      if (operador == null) throw Exception('No se pudo obtener el operador');

      final DateTime reservaFechaHora = DateTime(
        _selectedFecha!.year,
        _selectedFecha!.month,
        _selectedFecha!.day,
        _selectedHora?.hour ?? 0,
        _selectedHora?.minute ?? 0,
      );

      final dto = CrearReservaDto(
        reservaFecha: reservaFechaHora,
        numeroHabitacion: _habitacionController.text.isEmpty ? null : _habitacionController.text,
        puntoEncuentro: _puntoEncuentroController.text.isEmpty ? null : _puntoEncuentroController.text,
        observaciones: _observacionesController.text.isEmpty ? null : _observacionesController.text,
        pasajeros: int.parse(_pasajerosController.text),
        tipoServicioCodigo: _selectedTipoServicio!,
        agenciaCodigo: _selectedAgencia!,
        operadorCodigo: operador.id,
        creadoPor: authController.perfilUsuario!.usuario.codigo,
        representante: _representanteController.text.isEmpty ? null : _representanteController.text,
        numeroTickete: _numeroTicketeController.text.isEmpty ? null : _numeroTicketeController.text,
        pagoMonto: double.parse(_pagoMontoController.text),
        reservaTotal: _reservaTotalController.text.isEmpty ? null : double.parse(_reservaTotalController.text),
        colorCodigo: 1,
      );

      final reservaId = await reservasController.crearReservaCompleta(
        dto: dto,
        contactos: _contactos,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reserva creada exitosamente: $reservaId')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creando reserva: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Reserva'),
        backgroundColor: AppColors.getPrimaryColor(isDark),
        foregroundColor: AppColors.getTextColor(isDark),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(isDark),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Información Básica', isDark),
                Card(
                  elevation: 8,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shadowColor: isDark ? Colors.black54 : Colors.grey[300],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                          // Agencia con búsqueda
                          () {
                            final operadoresController = context.watch<OperadoresController>();
                            return DropdownButtonFormField<int>(
                              value: _selectedAgencia,
                              items: operadoresController.agencias.map((agencia) => DropdownMenuItem<int>(
                                value: agencia.codigo,
                                child: Text(agencia.nombre),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedAgencia = value),
                              decoration: InputDecoration(
                                labelText: 'Agencia',
                                labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                                prefixIcon: Icon(Icons.business, color: AppColors.getAccentColor(isDark)),
                              ),
                              validator: (value) => value == null ? 'Selecciona agencia' : null,
                            );
                          }(),
                          const SizedBox(height: 16),
                          // Cliente (Representante)
                          TextFormField(
                            controller: _representanteController,
                            decoration: InputDecoration(
                              labelText: 'Cliente',
                              labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                              prefixIcon: Icon(Icons.person, color: AppColors.getAccentColor(isDark)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Hotel (Punto de Encuentro)
                          TextFormField(
                            controller: _puntoEncuentroController,
                            decoration: InputDecoration(
                              labelText: 'Hotel',
                              labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                              prefixIcon: Icon(Icons.hotel, color: AppColors.getAccentColor(isDark)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Número de Habitación y Número de Ticket en fila
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _habitacionController,
                                  decoration: InputDecoration(
                                    labelText: 'Habitación',
                                    labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                                    prefixIcon: Icon(Icons.room, color: AppColors.getAccentColor(isDark)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _numeroTicketeController,
                                  decoration: InputDecoration(
                                    labelText: 'Ticket',
                                    labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                                    prefixIcon: Icon(Icons.confirmation_number, color: AppColors.getAccentColor(isDark)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _observacionesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Observaciones',
                              labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                              prefixIcon: Icon(Icons.notes, color: AppColors.getAccentColor(isDark)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildSectionTitle('Detalles del Servicio', isDark),
                Card(
                  elevation: 8,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shadowColor: isDark ? Colors.black54 : Colors.grey[300],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                          // Tipo de Servicio
                          () {
                            final serviciosController = context.watch<ServiciosController>();
                            return DropdownButtonFormField<int>(
                              value: _selectedTipoServicio,
                              items: serviciosController.tiposServicios.map((tipo) => DropdownMenuItem<int>(
                                value: tipo.codigo,
                                child: Text(tipo.descripcion),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedTipoServicio = value),
                              decoration: InputDecoration(
                                labelText: 'Tipo de Servicio',
                                labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                                prefixIcon: Icon(Icons.category, color: AppColors.getAccentColor(isDark)),
                              ),
                              validator: (value) => value == null ? 'Selecciona tipo' : null,
                            );
                          }(),
                          const SizedBox(height: 16),
                          // Fecha
                          TextFormField(
                            controller: _fechaController,
                            readOnly: true,
                            onTap: () => _selectFecha(context),
                            decoration: InputDecoration(
                              labelText: 'Fecha',
                              suffixIcon: const Icon(Icons.calendar_today),
                              labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                              prefixIcon: Icon(Icons.date_range, color: AppColors.getAccentColor(isDark)),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Selecciona fecha' : null,
                          ),
                          const SizedBox(height: 16),
                          // Hora
                          TextFormField(
                            controller: _horaController,
                            readOnly: true,
                            onTap: () => _selectHora(context),
                            decoration: InputDecoration(
                              labelText: 'Hora',
                              suffixIcon: const Icon(Icons.access_time),
                              labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                              prefixIcon: Icon(Icons.schedule, color: AppColors.getAccentColor(isDark)),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Selecciona hora' : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildSectionTitle('Información de Pago', isDark),
                Card(
                  elevation: 8,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shadowColor: isDark ? Colors.black54 : Colors.grey[300],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pagoMontoController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Saldo',
                                    labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                                    prefixIcon: Icon(Icons.attach_money, color: AppColors.getAccentColor(isDark)),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Requerido';
                                    final num = double.tryParse(value!);
                                    if (num == null || num < 0) return 'Monto válido';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _reservaTotalController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Total de Reserva',
                                    labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                                    prefixIcon: Icon(Icons.account_balance_wallet, color: AppColors.getAccentColor(isDark)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildSectionTitle('Contactos', isDark),
                Card(
                  elevation: 8,
                  color: isDark ? Colors.grey[850] : Colors.white,
                  shadowColor: isDark ? Colors.black54 : Colors.grey[300],
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                          FutureBuilder<List<TipoContacto>>(
                            future: _tiposContactoFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text('No hay tipos de contacto disponibles');
                              } else {
                                final tiposContacto = snapshot.data!;
                                return Column(
                                  children: _contactos.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final contacto = entry.value;
                                    final tipoNombre = tiposContacto.firstWhere(
                                      (tipo) => tipo.id == contacto.tipoContactoCodigo,
                                      orElse: () => TipoContacto(id: 0, descripcion: 'Desconocido', activo: false),
                                    ).descripcion;
                                    return ListTile(
                                      title: Text('$tipoNombre: ${contacto.contacto}'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _removerContacto(index),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }
                            },
                          ),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _agregarContacto,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Contacto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.getAccentColor(isDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppColors.getButtonGradient(isDark),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: ElevatedButton(
                            onPressed: _crearReserva,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Crear Reserva',
                              style: TextStyle(
                                color: AppColors.getTextColor(isDark),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.getTextColor(isDark),
        ),
      ),
    );
  }
}
