import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:citytourscartagena/core/widgets/add_reserva_form.dart';
import 'package:citytourscartagena/core/widgets/add_reserva_pro_form.dart';
import 'package:citytourscartagena/core/widgets/crear_agencia_form.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/core/widgets/table_only_view_screen.dart';
import 'package:citytourscartagena/core/widgets/whatsapp_contact_button.dart';
import 'package:citytourscartagena/screens/reservas/widgets/agency_header_widget.dart';
import 'package:citytourscartagena/screens/reservas/widgets/price_controls_widget.dart';
import 'package:citytourscartagena/screens/reservas/widgets/reservas_content_widget.dart';
import 'package:citytourscartagena/screens/reservas/widgets/reservas_header_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/controller/reservas_controller.dart';

class ReservasView extends StatefulWidget {
  final TurnoType? turno;
  final AgenciaConReservas? agencia;
  final VoidCallback? onBack;
  final bool isAgencyUser;
  final DateTime? customDate;
  final int codigoAgencia;

  final String? reservaIdNotificada; // nuevo
  // final bool forceShowAll; // nuevo

  const ReservasView({
    super.key,
    this.turno,
    this.agencia,
    this.onBack,
    this.isAgencyUser = false,
    this.reservaIdNotificada,
    this.customDate,
    this.codigoAgencia = 0,
    // this.forceShowAll = false,
  });

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  bool _isTableView = true;
  late AuthController _authController;
  AgenciaConReservas? _currentAgencia;
  StreamSubscription<List<AgenciaConReservas>>? _agenciasSub;

  String? _currentReservaIdNotificada;
  DateTime? _lastSeenReservas;
  bool _handledRouteArgs = false; // evita procesar dos veces
  // bool _filterInitialized = false; // no longer needed
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_handledRouteArgs) return;
    _handledRouteArgs = true;

    // Debug: imprimir parámetros recibidos
    debugPrint(
      'ReservasView.didChangeDependencies - agenciaId: ${widget.agencia?.id}, turno: ${widget.turno}',
    );

    // Obtener argumentos de navegación
    final route = ModalRoute.of(context);
    String? reservaFromArgs;
    DateTime? customDate;
    // bool forceAll = false;
    if (route != null && route.settings.arguments != null) {
      final arguments = route.settings.arguments;
      if (arguments is Map<String, dynamic>) {
        reservaFromArgs = arguments['reservaIdNotificada'] as String?;
        customDate = arguments['customDate'] as DateTime?;
        // forceAll = arguments['forceShowAll'] as bool? ?? false;
      } else if (arguments is String) {
        reservaFromArgs = arguments;
      }
    }
    reservaFromArgs ??= widget.reservaIdNotificada;
    // forceAll = forceAll || widget.forceShowAll;
    // Aplicar filtro y marcar reserva después de que la pantalla se construya completamente
    // un widgetBinding en español es un widget que se utiliza para interactuar con el ciclo de vida de la aplicación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      /// ctrl es el controlador de reservas es una instancia de ReservasController
      final ctrl = Provider.of<ReservasController>(context, listen: false);
      // Debug: antes de filtrar
      debugPrint(
        'ReservasView.postFrameCallback - filtrando con agenciaId: ${widget.agencia?.id}, turno: ${widget.turno}',
      );
      // Aplicar filtro de reservas
      ctrl.updateFilter(
        customDate != null ? DateFilterType.custom : DateFilterType.today,
        agenciaId: widget.agencia?.id,
        date: customDate,
        turno: widget.turno,
      );
      if (mounted) {
        setState(() {
          _currentReservaIdNotificada = reservaFromArgs;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    ///_authController es el controlador de autenticación
    ///sirve para gestionar la autenticación de usuarios
    _authController = Provider.of<AuthController>(context, listen: false);

    ///_currentAgencia es la agencia actualmente seleccionada
    ///sirve para gestionar la agencia seleccionada por el usuario
    _currentAgencia = widget.agencia;

    ///agenciasCtrl es el controlador de agencias y read es un método para acceder a su estado
    final agenciasCtrl = context.read<AgenciasController>();

    /// Si se ha pasado un ID de reserva notificada, lo asignamos
    /// _agenciasSub es una suscripción al stream de agencias con reservas
    _agenciasSub = agenciasCtrl.agenciasConReservasStream.listen((lista) {
      if (widget.agencia != null) {
        final updated = lista.firstWhereOrNull(
          (ar) => ar.agencia.id == widget.agencia!.agencia.id,
        );
        if (updated != null && mounted) {
          setState(() {
            _currentAgencia = updated;
          });
        }
      }
    });

    _loadLastSeenReservas();
  }

  /// Carga la última fecha de visualización de reservas del usuario
  /// sirve para mostrar las reservas no leídas
  Future<void> _loadLastSeenReservas() async {
    final userId = _authController.user?.uid;
    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data();
          final timestamp = data?['lastSeenReservas'] as Timestamp?;
          if (timestamp != null && mounted) {
            setState(() {
              _lastSeenReservas = timestamp.toDate();
            });
          }
        }
      } catch (e) {
        debugPrint('[ReservasView] Error loading last seen reservas: $e');
      }
    }
  }

  /// Limpia la reserva notificada actual

  void _clearNotificatedReserva() {
    if (_currentReservaIdNotificada != null && mounted) {
      setState(() {
        _currentReservaIdNotificada = null;
      });
      debugPrint('[v0] Reserva notificada limpiada');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.fixed,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Resaltado de notificación limpiado'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _agenciasSub?.cancel();
    _saveLastSeenTimestamp();
    super.dispose();
  }

  void _saveLastSeenTimestamp() {
    final userId = _authController.user?.uid;
    if (userId != null) {
      final now = DateTime.now();
      FirebaseFirestore.instance.collection('usuarios').doc(userId).update({
        'lastSeenReservas': Timestamp.fromDate(now),
      });
    }
  }

  void _onFilterChanged(
    DateFilterType filter,
    DateTime? date, {
    TurnoType? turno,
  }) {
    _clearNotificatedReserva();

    final ctrl = Provider.of<ReservasController>(context, listen: false);
    ctrl.updateFilter(
      filter,
      date: date,
      agenciaId: widget.agencia?.id,
      turno: turno ?? ctrl.turnoFilter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservasController = context.watch<ReservasController>();
    final configuracionController = context.watch<ConfiguracionController>();
    final configuracion = configuracionController.configuracion;
    final authRole = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null && widget.agencia == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        automaticallyImplyLeading: widget.onBack == null,
        title: _currentAgencia != null
            ? Text(
                'Reservas de ${_currentAgencia!.nombre}',
                overflow: TextOverflow.ellipsis,
              )
            : const Text('Reservas'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_currentReservaIdNotificada != null)
            IconButton(
              icon: const Icon(Icons.notifications_off),
              onPressed: _clearNotificatedReserva,
              tooltip: 'Limpiar resaltado de notificación',
            ),
          IconButton(
            icon: Icon(_isTableView ? Icons.view_list : Icons.table_chart),
            onPressed: () {
              setState(() {
                _isTableView = !_isTableView;
              });
            },
            tooltip: _isTableView ? 'Vista de lista' : 'Vista de tabla',
          ),
          if (widget.agencia != null) ...[
            if (authRole.hasPermission(Permission.edit_agencias))
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _editarAgencia,
                tooltip: 'Editar agencia',
              ),
          ],
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _showTableOnlyView,
            tooltip: 'Ver tabla completa',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              reservasController.updateFilter(
                reservasController.selectedFilter,
                date: reservasController.customDate,
                agenciaId: widget.agencia?.id,
                turno: reservasController.turnoFilter,
              );
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_currentReservaIdNotificada != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade100, Colors.orange.shade50],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notification_important,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reserva de notificación',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'ID: $_currentReservaIdNotificada',
                            style: TextStyle(
                              color: Colors.orange.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _clearNotificatedReserva,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Limpiar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            ReservasHeaderWidget(
              reservasController: reservasController,
              agenciaId: widget.agencia?.id,
              onFilterChanged: _onFilterChanged,
            ),
            if (_currentAgencia != null)
              AgencyHeaderWidget(
                agencia: _currentAgencia!,
                reservasController: reservasController,
              ),
            PriceControlsWidget(
              currentAgencia: _currentAgencia,
              configuracion: configuracion,
              reservasController: reservasController,
            ),
            ReservasContentWidget(
              isTableView: _isTableView,
              reservasController: reservasController,
              agenciaId: widget.agencia?.id,
              reservaIdNotificada: _currentReservaIdNotificada,
              lastSeenReservas: _lastSeenReservas,
            ),
            const SizedBox(height: 300),
          ],
        ),
      ),
      // ... existing code for floating action buttons ...
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (authRole.hasPermission(Permission.contacto_agencia_whatsapp))
            FutureBuilder<({bool hasContact, String? telefono, String? link})>(
              future: (widget.codigoAgencia != 0)
                  ? AgenciasService().getContactoAgencia(widget.codigoAgencia)
                  : Future.value((
                      hasContact: false,
                      telefono: null,
                      link: null,
                    )),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.hasContact) {
                  return const SizedBox.shrink();
                }
                final d = snap.data!;
                return WhatsappContactButton(
                  contacto: d.telefono,
                  link: d.link,
                );
              },
            ),

          if (_currentAgencia != null) const SizedBox(height: 16),

          if (authRole.hasPermission(Permission.crear_reserva))
            SizedBox(
              height: 48.h,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddReservaProForm(),
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                icon: Icon(Icons.auto_awesome, size: 24.sp),
                label: Text(
                  'Registro rápido',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                heroTag: "pro_button",
              ),
            ),
          SizedBox(height: 16.h),
          if (authRole.hasPermission(Permission.crear_agencias_agencias))
            SizedBox(
              height: 48.h,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddReservaForm(),
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                icon: Icon(Icons.add, size: 24.sp),
                label: Text(
                  'Agregar Reserva',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                heroTag: "manual_button",
              ),
            ),
        ],
      ),
    );
  }

  // ... existing code for methods ...
  void _showTableOnlyView() {
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TableOnlyViewScreen(
          turno: reservasController.turnoFilter,
          selectedFilter: reservasController.selectedFilter,
          customDate: reservasController.customDate,
          agenciaId: widget.agencia?.id,
          onUpdate: () {
            reservasController.updateFilter(
              reservasController.selectedFilter,
              date: reservasController.customDate,
              agenciaId: widget.agencia?.id,
              turno: widget.turno,
            );
          },
        ),
      ),
    );
  }

  void _editarAgencia() {
    final agencia = _currentAgencia!;
    final parentCtx = context;

    showDialog(
      context: context,
      builder: (_) => CrearAgenciaForm(
        initialNombre: agencia.nombre,
        initialImagenUrl: agencia.imagenUrl,
        initialPrecioPorAsientoTurnoManana: agencia.precioPorAsientoTurnoManana,
        initialPrecioPorAsientoTurnoTarde: agencia.precioPorAsientoTurnoTarde,
        initialTipoDocumento: agencia.tipoDocumento,
        initialNumeroDocumento: agencia.numeroDocumento,
        initialNombreBeneficiario: agencia.nombreBeneficiario,
        onCrear:
            (
              nuevoNombre,
              nuevaImagenFile,
              nuevoPrecioManana,
              nuevoPrecioTarde,
              nuevoTipoDocumento,
              nuevoNumeroDocumento,
              nuevoNombreBeneficiario,
              nuevoContactoAgencia,
              nuevoLinkContactoAgencia,
            ) async {
              final agenciasController = Provider.of<AgenciasController>(
                parentCtx,
                listen: false,
              );
              await agenciasController.updateAgencia(
                agencia.id,
                nuevoNombre,
                nuevaImagenFile?.path,
                agencia.imagenUrl,
                newPrecioPorAsientoTurnoManana: nuevoPrecioManana,
                newPrecioPorAsientoTurnoTarde: nuevoPrecioTarde,
                tipoDocumento: nuevoTipoDocumento,
                numeroDocumento: nuevoNumeroDocumento,
                nombreBeneficiario: nuevoNombreBeneficiario,
                contactoAgencia: nuevoContactoAgencia,
                linkContactoAgencia: nuevoLinkContactoAgencia,
              );
              Navigator.of(parentCtx).pop();
              ScaffoldMessenger.of(parentCtx).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.fixed,
                  content: Text('Agencia actualizada correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
      ),
    );
  }

  void _showAddReservaProForm() {
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaProForm(
        agencia: widget.agencia?.agencia,
        turno: reservasController.turnoFilter,
        onAdd: () {
          reservasController.updateFilter(
            reservasController.selectedFilter,
            date: reservasController.customDate,
            agenciaId: widget.agencia?.id,
            turno: reservasController.turnoFilter,
          );
        },
      ),
    );
  }

  void _showAddReservaForm() {
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaForm(
        agenciaId: widget.agencia?.id,
        onAdd: () {
          reservasController.updateFilter(
            reservasController.selectedFilter,
            date: reservasController.customDate,
            agenciaId: widget.agencia?.id,
            turno: reservasController.turnoFilter,
          );
        },
        initialTurno: reservasController.turnoFilter,
      ),
    );
  }
}
