import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/widgets/bloqueo_fecha_widget.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/screens/reservas/widgets/unified_filters_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ReservasHeaderWidget extends StatelessWidget {
  final ReservasController reservasController;
  final String? agenciaId;
  final Function(DateFilterType, DateTime?, {TurnoType? turno}) onFilterChanged;

  const ReservasHeaderWidget({
    super.key,
    required this.reservasController,
    this.agenciaId,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final authRole = context.read<AuthController>();

    return Column(
      children: [
        // Filtros profesionales con acordeón
        ProfessionalFiltersWidget(
          selectedFilter: reservasController.selectedFilter,
          customDate: reservasController.customDate,
          selectedTurno: reservasController.turnoFilter,
          selectedEstado: reservasController.estadoFilter,
          onFilterChanged: onFilterChanged,
          onTurnoChanged: (nuevoTurno) {
            reservasController.updateFilter(
              reservasController.selectedFilter,
              date: reservasController.customDate,
              agenciaId: agenciaId,
              turno: nuevoTurno,
            );
          },
          onEstadoChanged: (nuevoEstado) {
            reservasController.updateFilter(
              reservasController.selectedFilter,
              date: reservasController.customDate,
              agenciaId: agenciaId,
              turno: reservasController.turnoFilter,
              estado: nuevoEstado,
            );
          },
        ),
        
        // Widget de bloqueo de fecha/turno (espaciado interno manejado por el propio widget)
        if (reservasController.selectedFilter == DateFilterType.today ||
            reservasController.selectedFilter == DateFilterType.custom)
          _buildBloqueoWidget(reservasController, authRole),
      ],
    );
  }

  Widget _buildBloqueoWidget(ReservasController reservasController, AuthController authRole) {
    DateTime selectedDate = reservasController.selectedFilter == DateFilterType.custom
        ? (reservasController.customDate ?? DateTime.now())
        : DateTime.now();
    DateTime dateOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return Container(
      // mover el espaciado aquí para evitar doble padding externo
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: BloqueoFechaWidget(
        key: ValueKey(dateOnly.toIso8601String()),
        fecha: dateOnly,
        turnoActual: reservasController.turnoFilter == null
            ? 'ambos'
            : reservasController.turnoFilter == TurnoType.manana
                ? 'manana'
                : reservasController.turnoFilter == TurnoType.tarde
                    ? 'tarde'
                    : 'ambos',
        puedeEditar: authRole.hasPermission(Permission.edit_configuracion),
      ),
    );
  }
}
