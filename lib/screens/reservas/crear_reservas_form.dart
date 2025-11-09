import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/controller/filtros/servicios_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/models/reservas/crear_reserva_dto.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_contacto.dart';
import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:citytourscartagena/core/models/tipos/tipo_contacto.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/widgets/agencia_selector.dart';
import 'package:citytourscartagena/core/widgets/selectores/tipos_servicios_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int? _selectedTipoServicioId;
  int? _selectedAgenciaId;
  double? _precioServicio;
  bool _agenciaError = false;
  bool _isFetchingPrecio = false;

  final List<ReservaContacto> _contactos = [];

  late Future<List<TipoContacto>> _tiposContactoFuture;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pasajerosController.addListener(_onPasajerosChanged);
    final operadoresController = context.read<OperadoresController>();
    _tiposContactoFuture = operadoresController.obtenerTiposContactosActivos();
    // Prefetch servicios para evitar ver el loader del selector
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiciosController>().cargarTiposServiciosv2();
    });
  }

  @override
  void dispose() {
    _pasajerosController.removeListener(_onPasajerosChanged);
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

  double? _tryParseDouble(String value) {
    final sanitized = value.trim();
    if (sanitized.isEmpty) return null;
    return double.tryParse(sanitized.replaceAll(',', '.'));
  }

  void _onAgenciaSelected(int id) {
    setState(() {
      _selectedAgenciaId = id;
      _agenciaError = false;
    });
    _recalcularPrecio();
  }

  void _onServicioSeleccionado(TipoServicio? servicio) {
    setState(() {
      _selectedTipoServicioId = servicio?.codigo;
    });
    _recalcularPrecio();
  }

  void _onPasajerosChanged() {
    if (_precioServicio == null) return;
    _actualizarTotalCalculado();
  }

  Future<void> _recalcularPrecio() async {
    if (_selectedTipoServicioId == null) {
      if (_precioServicio != null) {
        setState(() => _precioServicio = null);
      }
      return;
    }

    setState(() => _isFetchingPrecio = true);
    try {
      final serviciosController = context.read<ServiciosController>();
      final previousPrecio = _precioServicio;
      final precio = await serviciosController.obtenerPrecioPorServicio(
        tipoServicioCodigo: _selectedTipoServicioId!,
        agenciaCodigo: _selectedAgenciaId,
      );
      if (!mounted) return;
      setState(() => _precioServicio = precio);
      if (_precioServicio != null) {
        _actualizarTotalCalculado();
      } else if (previousPrecio != null) {
        _reservaTotalController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _precioServicio = null);
      debugPrint('Error obteniendo precio: $e');
    } finally {
      if (mounted) {
        setState(() => _isFetchingPrecio = false);
      }
    }
  }

  void _actualizarTotalCalculado() {
    if (_precioServicio == null) return;
    final pax = int.tryParse(_pasajerosController.text);
    if (pax == null || pax <= 0) return;
    final total = _precioServicio! * pax;
    _reservaTotalController.text = total.toStringAsFixed(2);
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
    final formValid = _formKey.currentState?.validate() ?? false;
    bool isValid = formValid;

    if (_selectedAgenciaId == null) {
      setState(() => _agenciaError = true);
      isValid = false;
    }

    if (!isValid) return;

    if (_selectedFecha == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha')),
      );
      return;
    }

    if (_selectedTipoServicioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un tipo de servicio')),
      );
      return;
    }

    if (_selectedAgenciaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una agencia')),
      );
      return;
    }

    final pasajeros = int.tryParse(_pasajerosController.text) ?? 0;
    if (pasajeros <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa la cantidad de pasajeros')),
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

  final double? pagoMonto = _tryParseDouble(_pagoMontoController.text);

      double? totalReserva;
      if (_precioServicio != null) {
        totalReserva = _precioServicio! * pasajeros;
      } else {
        totalReserva = _tryParseDouble(_reservaTotalController.text);
      }

      final dto = CrearReservaDto(
        reservaFecha: reservaFechaHora,
        numeroHabitacion: _habitacionController.text.isEmpty ? null : _habitacionController.text,
        puntoEncuentro: _puntoEncuentroController.text.isEmpty ? null : _puntoEncuentroController.text,
        observaciones: _observacionesController.text.isEmpty ? null : _observacionesController.text,
        pasajeros: pasajeros,
        tipoServicioCodigo: _selectedTipoServicioId!,
        agenciaCodigo: _selectedAgenciaId!,
        operadorCodigo: operador.id,
        creadoPor: authController.perfilUsuario!.usuario.codigo,
        representante: _representanteController.text.isEmpty ? null : _representanteController.text,
        numeroTickete: _numeroTicketeController.text.isEmpty ? null : _numeroTicketeController.text,
  pagoMonto: pagoMonto,
        reservaTotal: totalReserva,
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
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Agencia *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextColor(isDark),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          AgenciaSelector(
                            selectedAgenciaId: _selectedAgenciaId,
                            onAgenciaSelected: _onAgenciaSelected,
                          ),
                          if (_agenciaError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                'Selecciona una agencia',
                                style: TextStyle(
                                  color: Colors.red.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
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
                          TipoServicioSelector(
                            selectedTipoServicioId: _selectedTipoServicioId,
                            onSelected: _onServicioSeleccionado,
                          ),
                          if (_isFetchingPrecio)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: LinearProgressIndicator(),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _pasajerosController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Pasajeros',
                              labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                              prefixIcon: Icon(Icons.people, color: AppColors.getAccentColor(isDark)),
                            ),
                            validator: (value) {
                              final pax = int.tryParse(value ?? '');
                              if (pax == null || pax <= 0) return 'Ingresa PAX';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _precioServicio != null
                                  ? 'Tarifa detectada: \$${_precioServicio!.toStringAsFixed(2)} por persona'
                                  : 'Sin tarifa guardada, escribe el total a mano (sorry).',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getSecondaryTextColor(isDark),
                              ),
                            ),
                          ),
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
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'Saldo',
                                    labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                                    prefixIcon: Icon(Icons.attach_money, color: AppColors.getAccentColor(isDark)),
                                  ),
                                  validator: (value) {
                                    final sanitized = value?.trim() ?? '';
                                    if (sanitized.isEmpty) return null;
                                    final monto = _tryParseDouble(sanitized);
                                    if (monto == null || monto < 0) return 'Monto válido';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _reservaTotalController,
                                  readOnly: _precioServicio != null,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: _precioServicio != null ? 'Total calculado' : 'Total de Reserva',
                                    labelStyle: TextStyle(color: AppColors.getSecondaryTextColor(isDark)),
                                    prefixIcon: Icon(Icons.account_balance_wallet, color: AppColors.getAccentColor(isDark)),
                                  ),
                                  validator: (value) {
                                    if (_precioServicio != null) return null;
                                    final sanitized = value?.trim() ?? '';
                                    if (sanitized.isEmpty) return 'Requerido';
                                    final total = _tryParseDouble(sanitized);
                                    if (total == null || total <= 0) return 'Monto válido';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _precioServicio != null
                                  ? 'Se calcula solo con los pax ingresados.'
                                  : 'Como no hay tarifa, valida que el total manual tenga sentido.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.getSecondaryTextColor(isDark),
                              ),
                            ),
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
