import 'package:citytourscartagena/core/controller/auth/registro_paginacion_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasoPassword extends StatefulWidget {
  final RegistroWizardController controller;
  final bool isDarkMode;

  const PasoPassword({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<PasoPassword> createState() => _PasoPasswordState();
}

class _PasoPasswordState extends State<PasoPassword> {
  bool _mostrarPassword = false;

  @override
  void initState() {
    super.initState();
    widget.controller.passwordController.addListener(_validar);
  }

  void _validar() {
    widget.controller.validarPaso3();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresa tu contraseña',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Debe tener al menos 6 caracteres',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.getSecondaryTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 32.h),

        Text(
          'Contraseña',
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
            controller: widget.controller.passwordController,
            obscureText: !_mostrarPassword,
            style: TextStyle(
              color: AppColors.getTextColor(widget.isDarkMode),
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Ingresa tu contraseña',
              hintStyle: TextStyle(
                color: AppColors.getSecondaryTextColor(widget.isDarkMode),
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: AppColors.getSecondaryTextColor(widget.isDarkMode),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.getSecondaryTextColor(widget.isDarkMode),
                ),
                onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
        
        if (widget.controller.passwordController.text.isNotEmpty && 
            widget.controller.passwordController.text.length < 6)
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              'La contraseña debe tener al menos 6 caracteres',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14.sp,
              ),
            ),
          ),
      ],
    );
  }
}
