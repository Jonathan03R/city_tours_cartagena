import 'package:citytourscartagena/core/controller/auth/registro_paginacion_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasoTipoEquipo extends StatefulWidget {
  final RegistroWizardController controller;
  final bool isDarkMode;

  const PasoTipoEquipo({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<PasoTipoEquipo> createState() => _PasoTipoEquipoState();
}

class _PasoTipoEquipoState extends State<PasoTipoEquipo> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿A qué equipo perteneces?',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Selecciona tu tipo de equipo',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.getSecondaryTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 32.h),

        _buildOpcionEquipo(
          titulo: 'Operador',
          descripcion: 'Personal operativo de tours',
          icono: Icons.directions_bus_rounded,
          valor: 'operador',
          seleccionado: widget.controller.tipoEquipo == 'operador',
        ),
        
        SizedBox(height: 16.h),
        
        _buildOpcionEquipo(
          titulo: 'Agencia',
          descripcion: 'Agencia de viajes',
          icono: Icons.business_rounded,
          valor: 'agencia',
          seleccionado: widget.controller.tipoEquipo == 'agencia',
        ),
      ],
    );
  }

  Widget _buildOpcionEquipo({
    required String titulo,
    required String descripcion,
    required IconData icono,
    required String valor,
    required bool seleccionado,
  }) {
    return GestureDetector(
      onTap: () => widget.controller.seleccionarTipoEquipo(valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: seleccionado 
              ? AppColors.getButtonGradient(widget.isDarkMode)
              : LinearGradient(
                  colors: [
                    (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                    (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
                  ],
                ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: seleccionado 
                ? AppColors.getAccentColor(widget.isDarkMode)
                : (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.15),
            width: seleccionado ? 2 : 1,
          ),
          boxShadow: seleccionado ? [
            BoxShadow(
              color: AppColors.getAccentColor(widget.isDarkMode).withOpacity(0.3),
              blurRadius: 10.r,
              offset: Offset(0, 4.h),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: seleccionado 
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.getAccentColor(widget.isDarkMode).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icono,
                color: seleccionado 
                    ? Colors.white
                    : AppColors.getAccentColor(widget.isDarkMode),
                size: 24.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: seleccionado 
                          ? Colors.white
                          : AppColors.getTextColor(widget.isDarkMode),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    descripcion,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: seleccionado 
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.getSecondaryTextColor(widget.isDarkMode),
                    ),
                  ),
                ],
              ),
            ),
            if (seleccionado)
              Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 24.r,
              ),
          ],
        ),
      ),
    );
  }
}
