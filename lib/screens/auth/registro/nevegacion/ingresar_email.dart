import 'package:citytourscartagena/core/controller/auth/registro_paginacion_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasoEmail extends StatefulWidget {
  final RegistroWizardController controller;
  final bool isDarkMode;

  const PasoEmail({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<PasoEmail> createState() => _PasoEmailState();
}

class _PasoEmailState extends State<PasoEmail> {
  @override
  void initState() {
    super.initState();
    widget.controller.emailController.addListener(_validar);
  }

  void _validar() {
    widget.controller.validarPaso2();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingresa tu correo',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Ingresa tu correo correctamente',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.getSecondaryTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 32.h),

        Text(
          'Correo electrónico',
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
            controller: widget.controller.emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: AppColors.getTextColor(widget.isDarkMode),
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.com',
              hintStyle: TextStyle(
                color: AppColors.getSecondaryTextColor(widget.isDarkMode),
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
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
        
        if (widget.controller.emailController.text.isNotEmpty && 
            !widget.controller.emailController.text.contains('@'))
          Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              'Por favor ingresa un correo válido',
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
