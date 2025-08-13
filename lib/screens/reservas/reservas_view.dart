import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
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

import '../../core/controller/reservas_controller.dart';

class ReservasView extends StatefulWidget {
  final TurnoType? turno;
  final AgenciaConReservas? agencia;
  final VoidCallback? onBack;
  final bool isAgencyUser;

  const ReservasView({
    super.key,
    this.turno,
    this.agencia,
    this.onBack,
    this.isAgencyUser = false,
  });

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  bool _isTableView = true;
  String? _reservaIdNotificada;
  late AuthController _authController;
  AgenciaConReservas? _currentAgencia;
  StreamSubscription<List<AgenciaConReservas>>? _agenciasSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reservaId = ModalRoute.of(context)?.settings.arguments as String?;
    if (reservaId != null && reservaId != _reservaIdNotificada) {
      setState(() {
        _reservaIdNotificada = reservaId;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final reservasController = Provider.of<ReservasController>(
          context,
          listen: false,
        );
        reservasController.updateFilter(
          DateFilterType.all,
          agenciaId: widget.agencia?.id,
          turno: widget.turno,
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _authController = Provider.of<AuthController>(context, listen: false);
    _currentAgencia = widget.agencia;
    
    final agenciasCtrl = context.read<AgenciasController>();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = Provider.of<ReservasController>(context, listen: false);
      ctrl.updateFilter(
        DateFilterType.today,
        agenciaId: widget.agencia?.id,
        turno: widget.turno,
      );
    });
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
    final ctrl = Provider.of<ReservasController>(context, listen: false);
    ctrl.updateFilter(
      filter,
      date: date,
      agenciaId: widget.agencia?.id,
      turno: turno ?? ctrl.turnoFilter,
    );
  }

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
        // Campos de contacto de la rama ContactoAgencia
        initialContactoAgencia: agencia.contactoAgencia,
        initialLinkContactoAgencia: agencia.linkContactoAgencia,
        onCrear: (
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
              content: Text('Agencia actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
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
              reservaIdNotificada: _reservaIdNotificada,
            ),
            const SizedBox(height: 300),
          ],
        ),
      ),
      // Floating Action Button unificado - combina ambas ramas
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón WhatsApp de la rama ContactoAgencia (solo si hay agencia)
          if (_currentAgencia != null && authRole.hasPermission(Permission.contacto_agencia_whatsapp))
            WhatsappContactButton(
              contacto: _currentAgencia?.contactoAgencia,
              link: _currentAgencia?.linkContactoAgencia,
            ),
          if (_currentAgencia != null) const SizedBox(height: 16),
          
          // Botones originales de FloatingActionButtonsWidget
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
                  'Registro manual',
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
      ),
    );
  }
}
