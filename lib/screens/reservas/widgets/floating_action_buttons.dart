import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

/// NO SE USA ? 

class FloatingActionButtonsWidget extends StatelessWidget {
  final AgenciaConReservas? agencia;
  final ReservasController reservasController;

  const FloatingActionButtonsWidget({
    super.key,
    this.agencia,
    required this.reservasController,
  });

  @override
  Widget build(BuildContext context) {
    final authRole = context.read<AuthController>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (authRole.hasPermission(Permission.crear_reserva))
          SizedBox(
            height: 48.h,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddReservaProForm(context),
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
              onPressed: () => _showAddReservaForm(context),
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
    );
  }

  void _showAddReservaProForm(BuildContext context) {
    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   // builder: (context) => AddReservaProForm(
    //   //   agencia: agencia?.agencia,
    //   //   turno: reservasController.turnoFilter,
    //   //   onAdd: () {
    //   //     reservasController.updateFilter(
    //   //       reservasController.selectedFilter,
    //   //       date: reservasController.customDate,
    //   //       agenciaId: agencia?.id,
    //   //       turno: reservasController.turnoFilter,
    //   //     );
    //   //   },
    //   ),
    // );
  }

  void _showAddReservaForm(BuildContext context) {
    // showModalBottomSheet(
    //   context: context,
    //   isScrollControlled: true,
    //   // builder: (context) => AddReservaForm(
    //   //   agenciaId: agencia?.id,
    //   //   onAdd: () {
    //   //     reservasController.updateFilter(
    //   //       reservasController.selectedFilter,
    //   //       date: reservasController.customDate,
    //   //       agenciaId: agencia?.id,
    //   //       turno: reservasController.turnoFilter,
    //   //     );
    //   //   },
    //   // ),
    // );
  }
}
