import 'package:citytourscartagena/core/controller/auth/registro_paginacion_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasoInformacionPersonal extends StatefulWidget {
  final RegistroWizardController controller;
  final bool isDarkMode;

  const PasoInformacionPersonal({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<PasoInformacionPersonal> createState() => _PasoInformacionPersonalState();
}

class _PasoInformacionPersonalState extends State<PasoInformacionPersonal> {
  @override
  void initState() {
    super.initState();
    // Escuchar cambios en los campos para validar
    widget.controller.nombreController.addListener(_validar);
    widget.controller.apellidoController.addListener(_validar);
    widget.controller.aliasController.addListener(_validar);
  }

  void _validar() {
    widget.controller.validarPaso1();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresa tu nombre y apellidos',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Y como quieres que te llamen en la aplicación',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.getSecondaryTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 32.h),

        _buildCampoTexto(
          controller: widget.controller.nombreController,
          label: 'Nombre',
          icon: Icons.person_outline,
          hint: 'Ingresa tu nombre',
        ),
        SizedBox(height: 20.h),

        _buildCampoTexto(
          controller: widget.controller.apellidoController,
          label: 'Apellidos',
          icon: Icons.person_outline,
          hint: 'Ingresa tus apellidos',
        ),
        SizedBox(height: 20.h),

        _buildCampoTexto(
          controller: widget.controller.aliasController,
          label: '¿Cómo quieres que te llamen?',
          icon: Icons.alternate_email,
          hint: 'Tu nombre en la app',
        ),
      ],
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.getTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: (widget.isDarkMode ? Colors.white : Colors.black).withOpacity(0.15),
            ),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: AppColors.getTextColor(widget.isDarkMode),
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.getSecondaryTextColor(widget.isDarkMode),
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.getSecondaryTextColor(widget.isDarkMode),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
