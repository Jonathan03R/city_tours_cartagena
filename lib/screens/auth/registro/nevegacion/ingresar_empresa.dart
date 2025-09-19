import 'package:citytourscartagena/core/controller/auth/registro_paginacion_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasoCodigoRelacion extends StatefulWidget {
  final RegistroWizardController controller;
  final bool isDarkMode;

  const PasoCodigoRelacion({
    super.key,
    required this.controller,
    required this.isDarkMode,
  });

  @override
  State<PasoCodigoRelacion> createState() => _PasoCodigoRelacionState();
}

class _PasoCodigoRelacionState extends State<PasoCodigoRelacion> {
  @override
  void initState() {
    super.initState();
    widget.controller.codigoRelacionController.addListener(_validar);
  }

  void _validar() {
    widget.controller.validarPaso5();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Código de relación',
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.getTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Ingresa el número que conoces',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.getSecondaryTextColor(widget.isDarkMode),
          ),
        ),
        SizedBox(height: 32.h),

        Text(
          'Código',
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
            controller: widget.controller.codigoRelacionController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: AppColors.getTextColor(widget.isDarkMode),
              fontSize: 16.sp,
            ),
            decoration: InputDecoration(
              hintText: 'Ingresa el código',
              hintStyle: TextStyle(
                color: AppColors.getSecondaryTextColor(widget.isDarkMode),
              ),
              prefixIcon: Icon(
                Icons.code_rounded,
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
        
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: AppColors.getAccentColor(widget.isDarkMode).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.getAccentColor(widget.isDarkMode).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.getAccentColor(widget.isDarkMode),
                size: 20.r,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Este código te fue proporcionado por tu supervisor o administrador',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.getTextColor(widget.isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
