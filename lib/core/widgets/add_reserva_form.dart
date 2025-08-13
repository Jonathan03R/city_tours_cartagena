// ignore_for_file: use_build_context_synchronously

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'agencia_selector.dart';
import 'error_dialogs.dart';

/// AddReservaForm (MERGE: refactor base + feature extra fields)
/// - Mantiene el diseño seccionado y validación del refactor.
/// - Incorpora campos: ticket, habitacion, estatusReserva de la feature.
/// - Sin mutaciones de estado dentro de build; todo derivado por getters.
/// - Validación robusta, feedback claro y UX consistente.
class AddReservaForm extends StatefulWidget {
  final VoidCallback onAdd;
  final String? agenciaId;

  const AddReservaForm({
    super.key,
    required this.onAdd,
    this.agenciaId,
  });

  @override
  State<AddReservaForm> createState() => _AddReservaFormState();
}

class _AddReservaFormState extends State<AddReservaForm> {
  // Form
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.onUserInteraction;

  // Controllers
  final _nombreController = TextEditingController();
  final _hotelController = TextEditingController();
  final _paxController = TextEditingController(text: '1');
  final _saldoController = TextEditingController(text: '0');
  final _observacionController = TextEditingController();
  final _telefonoController = TextEditingController();

  // MERGE: feature/Add-N-habitaciones-ticket añadió estos campos
  final _ticketController = TextEditingController();
  final _habitacionController = TextEditingController();
  final _estatusReservaController = TextEditingController(text: 'A'); // Ej: A=Activa
  // NUEVO: Controlador para costo total privado
  final _costoTotalPrivadoController = TextEditingController();

  // Focus (MERGE: del refactor/user-agencia)
  final _focusNombre = FocusNode();
  final _focusHotel = FocusNode();
  final _focusPax = FocusNode();
  final _focusSaldo = FocusNode();
  final _focusTelefono = FocusNode();
  final _focusObs = FocusNode();

  // State
  DateTime _selectedDate = DateTime.now();
  TurnoType? _selectedTurno = TurnoType.manana;
  Agencia? _selectedAgencia;
  String? _selectedAgenciaId;

  bool _isLoading = false;
  bool _isLoadingAgencia = false;
  bool _agencyError = false;

  // Animations keys (en refactor usamos keys dentro de widgets animados)
  final _estadoKey = UniqueKey();
  final _totalesKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    // Inicializa agencia si viene prefijada (MERGE: ambas ramas coinciden en intención)
    if (widget.agenciaId != null) {
      _selectedAgenciaId = widget.agenciaId;
      _loadAgenciaAndMaybePrice();
    }

    // Listeners para recomputar totales/estado
    _paxController.addListener(_onValuesChanged);
    _saldoController.addListener(_onValuesChanged);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _hotelController.dispose();

    _paxController.removeListener(_onValuesChanged);
    _paxController.dispose();

    _saldoController.removeListener(_onValuesChanged);
    _saldoController.dispose();

    _observacionController.dispose();
    _telefonoController.dispose();

    // MERGE KEEP: Campos agregados en feature/Add-N-habitaciones-ticket
    _ticketController.dispose();
    _habitacionController.dispose();
    _estatusReservaController.dispose();
  // NUEVO: Dispose del controlador de costo total privado
  _costoTotalPrivadoController.dispose();
    // MERGE KEEP: FocusNodes del refactor/user-agencia
    _focusNombre.dispose();
    _focusHotel.dispose();
    _focusPax.dispose();
    _focusSaldo.dispose();
    _focusTelefono.dispose();
    _focusObs.dispose();

    super.dispose();
  }

  // Helpers -------------------------------------------------------------------

  // Convierte "1.234,56" o "1234.56" en double; admite ambas notaciones.
  double _parseMoneda(String input) {
    final cleaned = input.trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return 0.0;
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');
    String normalized = cleaned;
    if (hasComma && hasDot) {
      normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma && !hasDot) {
      normalized = cleaned.replaceAll(',', '.');
    }
    return double.tryParse(normalized) ?? 0.0;
  }

  int get _pax {
    final v = int.tryParse(_paxController.text.trim());
    return (v == null || v <= 0) ? 1 : v;
    // MERGE NOTE: la feature permitía valores negativos? Conservamos validación > 0.
  }

  double get _saldo {
    return _parseMoneda(_saldoController.text);
  }

  Configuracion? get _config => context.read<ConfiguracionController>().configuracion;

  double _precioAsiento({
    TurnoType? turno,
    Configuracion? config,
    Agencia? agencia,
  }) {
    if (agencia != null) {
      final precioAg = turno == TurnoType.manana
          ? agencia.precioPorAsientoTurnoManana
          : agencia.precioPorAsientoTurnoTarde;
      if (precioAg != null && precioAg > 0) return precioAg;
    }
    if (config != null) {
      return turno == TurnoType.manana
          ? config.precioGeneralAsientoTemprano
          : config.precioGeneralAsientoTarde;
    }
    return 0.0;
  }

  double get _costoAsientoActual {
    // Si el turno es privado, el costo lo ingresa el usuario manualmente
    if (_selectedTurno == TurnoType.privado) {
      final v = double.tryParse(_costoTotalPrivadoController.text.replaceAll(',', '.'));
      return v ?? 0.0;
    }
    return _precioAsiento(
      turno: _selectedTurno,
      config: _config,
      agencia: _selectedAgencia,
    );
  }

  double get _costoTotal {
    if (_selectedTurno == TurnoType.privado) {
      final v = double.tryParse(_costoTotalPrivadoController.text.replaceAll(',', '.'));
      return v ?? 0.0;
    }
    return _costoAsientoActual * _pax;
  }
  double get _diferencia => _costoTotal - _saldo;

  EstadoReserva _estadoPor(double costoAsiento, int pax, double saldo) {
    final total = costoAsiento * pax;
    final diff = total - saldo;
    return diff <= 0 ? EstadoReserva.pagada : EstadoReserva.pendiente;
  }

  EstadoReserva get _estadoActual => _estadoPor(_costoAsientoActual, _pax, _saldo);

  // Actions -------------------------------------------------------------------

  Future<void> _loadAgenciaAndMaybePrice() async {
    if (_selectedAgenciaId == null) return;
    setState(() => _isLoadingAgencia = true);
    final agenciasController = context.read<AgenciasController>();
    final agencia = agenciasController.getAgenciaById(_selectedAgenciaId!);
    if (!mounted) return;
    setState(() {
      _selectedAgencia = agencia;
      _isLoadingAgencia = false;
    });
  }

  void _onValuesChanged() {
    if (!mounted) return;
    // Recomputación derivada
    setState(() {});
  }

  Future<void> _onSubmit() async {
    setState(() => _autovalidateMode = AutovalidateMode.always);

    if (!_formKey.currentState!.validate()) {
      await ErrorDialogs.showErrorDialog(
        context,
        'Por favor, corrige los errores del formulario.',
      );
      return;
    }

    if (_selectedAgenciaId == null || _selectedAgencia == null) {
      setState(() => _agencyError = true);
      await ErrorDialogs.showErrorDialog(context, 'Debes seleccionar una agencia.');
      return;
    }

    if (_selectedTurno == null) {
      await ErrorDialogs.showErrorDialog(context, 'Por favor, selecciona un turno.');
      return;
    }

    final currentCostoAsiento = _costoAsientoActual;
    if (_selectedTurno == TurnoType.privado) {
      final v = double.tryParse(_costoTotalPrivadoController.text.replaceAll(',', '.'));
      if (v == null || v <= 0) {
        await ErrorDialogs.showErrorDialog(
          context,
          'Ingresa un costo total válido para el servicio privado.',
        );
        return;
      }
    } else {
      if (currentCostoAsiento <= 0) {
        await ErrorDialogs.showErrorDialog(
          context,
          'Error: precio por asiento no válido, comunícate con el administrador.',
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      // Validación de cupos (compartida por ambas ramas)
      final reservasCtrl = context.read<ReservasController>();
      final estadoCupos = await reservasCtrl.getEstadoCupos(
        turno: _selectedTurno,
        fecha: _selectedDate,
      );

      if (estadoCupos == CuposEstado.cerrado) {
        await ErrorDialogs.showErrorDialog(
          context,
          'No se puede crear la reserva: los cupos están cerrados para este turno.',
        );
        setState(() => _isLoading = false);
        return;
      } else if (estadoCupos == CuposEstado.limiteAlcanzado) {
        await ErrorDialogs.showDialogVerificarDisponibilidad(
          context,
          _config?.contact_whatsapp,
        );
        setState(() => _isLoading = false);
        return;
      }

      final estado = _estadoPor(currentCostoAsiento, _pax, _saldo);

      final nuevaReserva = Reserva(
        id: '',
        nombreCliente: _nombreController.text.trim(),
        hotel: _hotelController.text.trim(),
        pax: _pax,
        saldo: _saldo,
        observacion: _observacionController.text.trim(),
        fecha: _selectedDate,
        agenciaId: _selectedAgenciaId!,
        estado: estado,
    costoAsiento: _selectedTurno == TurnoType.privado
      ? double.tryParse(_costoTotalPrivadoController.text.replaceAll(',', '.')) ?? 0.0
      : currentCostoAsiento,
        telefono: _telefonoController.text.trim(),
        turno: _selectedTurno,
        // MERGE KEEP: campos de feature
        ticket: _ticketController.text.trim(),
        habitacion: _habitacionController.text.trim(),
        estatusReserva: 'A',
      );

      final reservasController = context.read<ReservasController>();
      await reservasController.addReserva(nuevaReserva);
      widget.onAdd();

      if (!mounted) return;
      Navigator.of(context).pop();
      await _showSnackDialog('Reserva agregada exitosamente (${estado.name}).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e.toString();
      if (msg.contains('No hay cupos disponibles')) {
        // Límite alcanzado -> WhatsApp
        await ErrorDialogs.showDialogVerificarDisponibilidad(
          context,
          _config?.contact_whatsapp,
        );
      } else if (msg.contains('los cupos están bloqueados')) {
        await ErrorDialogs.showErrorDialog(
          context,
          msg.replaceFirst('Exception: ', ''),
        );
      } else {
        await ErrorDialogs.showErrorDialog(
          context,
          'Ocurrió un error al crear la reserva. Intenta nuevamente o contacta al administrador.\n\nDetalle: $msg',
        );
      }
    }
  }

  Future<void> _showSnackDialog(String msg, {bool isError = false}) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: isError ? Colors.red.shade50 : Colors.green.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(isError ? 'Error' : 'Éxito'),
          ],
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: isError ? Colors.red.shade300 : Colors.green.shade800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  // UI ------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
  final isPrivado = _selectedTurno == TurnoType.privado;
    // Observa configuración para re-render si cambia el precio
    context.watch<ConfiguracionController>().configuracion;
    final cs = Theme.of(context).colorScheme;

    // MERGE RESOLUTION:
    // - feature: usaba SingleChildScrollView con padding bottom= viewInsets.bottom
    // - refactor: usaba SafeArea + estructura seccionada
    // Decisión: usar SafeArea + Form (refactor) y agregar padding inferior para teclado (feature).
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _Header(onClose: _isLoading ? null : () => Navigator.of(context).pop()),
            const SizedBox(height: 8),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Column(
                    children: [
                      _Section(
                        title: 'Agencia',
                        child: _buildAgencia(cs),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        title: 'Datos del cliente',
                        child: Column(
                          children: [
                            _LabeledField(
                              label: 'Cliente',
                              isRequired: true,
                              icon: Icons.person,
                              child: TextFormField(
                                controller: _nombreController,
                                focusNode: _focusNombre,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _focusHotel.requestFocus(),
                                decoration: const InputDecoration(hintText: 'Nombre y apellido'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Este campo es requerido' : null,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              label: 'Hotel',
                              icon: Icons.hotel,
                              child: TextFormField(
                                controller: _hotelController,
                                focusNode: _focusHotel,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _focusTelefono.requestFocus(),
                                decoration: const InputDecoration(hintText: 'Nombre del hotel (opcional)'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              label: 'Teléfono',
                              icon: Icons.phone,
                              child: TextFormField(
                                controller: _telefonoController,
                                focusNode: _focusTelefono,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _focusObs.requestFocus(),
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(hintText: 'Ej: +57 300 123 4567'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              label: 'Observaciones',
                              icon: Icons.note,
                              child: TextFormField(
                                controller: _observacionController,
                                focusNode: _focusObs,
                                minLines: 2,
                                maxLines: 4,
                                decoration:
                                    const InputDecoration(hintText: 'Detalles adicionales (opcional)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        title: 'Detalles de la reserva',
                        child: Column(
                          children: [
                            _LabeledField(
                              label: 'Turno',
                              isRequired: true,
                              icon: Icons.access_time,
                              child: DropdownButtonFormField<TurnoType>(
                                value: _selectedTurno,
                                items: TurnoType.values
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isLoading ? null : (v) => setState(() => _selectedTurno = v),
                                validator: (v) => v == null ? 'Debes seleccionar un turno' : null,
                              ),
                            ),
                            if (isPrivado) ...[
                              const SizedBox(height: 12),
                              _LabeledField(
                                label: 'Costo total del servicio',
                                isRequired: true,
                                icon: Icons.attach_money,
                                child: TextFormField(
                                  controller: _costoTotalPrivadoController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'Ej: 40000'),
                                  validator: (v) {
                                    final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                                    if (d == null || d <= 0) return 'Ingresa un valor válido';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            _LabeledField(
                              label: 'Fecha',
                              isRequired: true,
                              icon: Icons.calendar_today,
                              child: InkWell(
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime(2035),
                                        );
                                        if (picked != null) {
                                          setState(() => _selectedDate = picked);
                                        }
                                      },
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: const InputDecoration(),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd-MM-yyyy').format(_selectedDate)),
                                      const Icon(Icons.expand_more),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _LabeledField(
                                    label: 'PAX',
                                    isRequired: true,
                                    icon: Icons.people,
                                    child: TextFormField(
                                      controller: _paxController,
                                      focusNode: _focusPax,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) => _focusSaldo.requestFocus(),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(hintText: 'Ej: 2'),
                                      validator: (v) {
                                        final n = int.tryParse((v ?? '').trim());
                                        if (n == null || n <= 0) return 'Ingresa un número válido';
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _LabeledField(
                                    label: 'Saldo (recibido)',
                                    isRequired: true,
                                    icon: Icons.attach_money,
                                    child: TextFormField(
                                      controller: _saldoController,
                                      focusNode: _focusSaldo,
                                      textInputAction: TextInputAction.done,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.\s]')),
                                      ],
                                      decoration: const InputDecoration(hintText: 'Ej: 150.00'),
                                      validator: (v) {
                                        final d = _parseMoneda(v ?? '');
                                        if (d < 0) return 'No puede ser negativo';
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // MERGE KEEP: Campos extra de feature en estilo refactor
                            _LabeledField(
                              label: 'Tickets',
                              icon: Icons.confirmation_number_outlined,
                              child: TextFormField(
                                controller: _ticketController,
                                decoration: const InputDecoration(hintText: 'Ej: ABC-123'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              label: 'N° Habitación',
                              icon: Icons.meeting_room,
                              child: TextFormField(
                                controller: _habitacionController,
                                decoration: const InputDecoration(hintText: 'Ej: 406'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Section(
                        title: 'Resumen y estado',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_selectedTurno != TurnoType.privado) ...[
                              _InfoChip(
                                icon: Icons.monetization_on_outlined,
                                title: 'Precio por asiento',
                                value: _currency(_costoAsientoActual),
                                color: cs.primaryContainer,
                                textColor: cs.onPrimaryContainer,
                                warning: _costoAsientoActual <= 0
                                    ? 'Revisa la configuración de precios'
                                    : null,
                              ),
                              const SizedBox(height: 8),
                            ],
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: _EstadoBox(
                                key: ValueKey(
                                    '${_estadoActual.name}-${_costoTotal.toStringAsFixed(2)}-${_saldo.toStringAsFixed(2)}'),
                                estado: _estadoActual,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _selectedTurno == TurnoType.privado
                                  ? _TotalesBox(
                                      key: ValueKey('totales-privado-${_saldo.toStringAsFixed(2)}-${_costoTotal.toStringAsFixed(2)}'),
                                      total: _costoTotal,
                                      diferencia: _diferencia,
                                      formatter: _currency,
                                      labelTotal: 'Costo total',
                                    )
                                  : _TotalesBox(
                                      key: ValueKey('totales-${_pax}-${_saldo.toStringAsFixed(2)}-${_costoAsientoActual.toStringAsFixed(2)}'),
                                      total: _costoTotal,
                                      diferencia: _diferencia,
                                      formatter: _currency,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _FooterActions(
              isLoading: _isLoading,
              onCancel: _isLoading ? null : () => Navigator.of(context).pop(),
              onSubmit: _isLoading ? null : _onSubmit,
            ),
          ],
        ),
      ),
    );
  }

  // Sub-widgets ---------------------------------------------------------------

  Widget _buildAgencia(ColorScheme cs) {
    if (widget.agenciaId != null) {
      return _isLoadingAgencia
          ? const _LoadingLine(text: 'Cargando agencia…')
          : Row(
              children: [
                Icon(Icons.business, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedAgencia?.nombre != null
                        ? 'Agencia: ${_selectedAgencia!.nombre} (ID: ${widget.agenciaId})'
                        : 'Agencia: (ID: ${widget.agenciaId})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgenciaSelector(
          selectedAgenciaId: _selectedAgenciaId,
          onAgenciaSelected: (id) async {
            setState(() {
              _selectedAgenciaId = id;
              _agencyError = false;
              _isLoadingAgencia = true;
            });
            await _loadAgenciaAndMaybePrice();
          },
        ),
        if (_agencyError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Debes seleccionar una agencia',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _currency(num n) {
    final locale = Intl.getCurrentLocale();
    final fmt = NumberFormat.currency(locale: locale, symbol: r'$', decimalDigits: 2);
    return fmt.format(n);
  }
}

// UI pieces -------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Agregar nueva reserva',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: 'Cerrar',
        ),
      ],
    );
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.isLoading,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isLoading;
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onSubmit,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Agregar reserva'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                title,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.isRequired = false,
    this.icon,
  });

  final String label;
  final bool isRequired;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, size: 16, color: cs.primary),
            if (icon != null) const SizedBox(width: 8),
            Text(
              isRequired ? '$label *' : label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.textColor,
    this.warning,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color textColor;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
              ),
            ),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
          ]),
          if (warning != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: cs.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    warning!,
                    style: TextStyle(
                      color: cs.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EstadoBox extends StatelessWidget {
  const _EstadoBox({super.key, required this.estado});
  final EstadoReserva estado;

  @override
  Widget build(BuildContext context) {
    final isPagada = estado == EstadoReserva.pagada;
    final bg = isPagada ? Colors.green.shade50 : Colors.orange.shade50;
    final fg = isPagada ? Colors.green.shade800 : Colors.orange.shade800;
    final icon = isPagada ? Icons.check_circle : Icons.info;
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPagada ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 8),
          Text(
            'Estado: ${Formatters.getEstadoText(estado)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}

class _TotalesBox extends StatelessWidget {
  const _TotalesBox({
    super.key,
    required this.total,
    required this.diferencia,
    required this.formatter,
    this.labelTotal,
  });

  final double total;
  final double diferencia;
  final String Function(num) formatter;
  final String? labelTotal;

  @override
  Widget build(BuildContext context) {
    final isPendiente = diferencia > 0;
    final label = isPendiente ? 'Pendiente' : 'Pagado (sobrante)';
    final value = isPendiente ? formatter(diferencia) : formatter(-diferencia);
    final icon = isPendiente ? Icons.warning_amber_rounded : Icons.verified;
    final color = isPendiente ? Colors.orange.shade700 : Colors.green.shade700;
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.calculate, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              labelTotal ?? 'Costo total: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(formatter(total), style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                '$label: $value',
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}