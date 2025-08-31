import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TurnoSelectorWidget extends StatelessWidget {
  final ValueChanged<TurnoType>? onTurnoSelected;
  /// Si true, además de llamar a onTurnoSelected navegará a `ReservasView`
  final bool navigateOnSelect;

  const TurnoSelectorWidget({
    super.key,
    this.onTurnoSelected,
    this.navigateOnSelect = false,
  });

  LinearGradient _gradientForTurno(TurnoType turno) {
    switch (turno) {
      case TurnoType.manana:
        return LinearGradient(
          colors: [
            AppColors.accentBlue,
            AppColors.lightBlue,
            AppColors.accentBlue.withOpacity(0.8),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case TurnoType.tarde:
        return LinearGradient(
          colors: [
            AppColors.lightBlue,
            AppColors.accentBlue,
            AppColors.primaryNightBlue.withOpacity(0.7),
          ],
          stops: const [0.0, 0.6, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case TurnoType.privado:
        return LinearGradient(
          colors: [
            AppColors.primaryNightBlue,
            AppColors.secondaryNightBlue,
            AppColors.primaryNightBlue.withOpacity(0.9),
            const Color(0xFF334155), // Subtle lighter accent
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  List<BoxShadow> _shadowForTurno(TurnoType turno) {
    switch (turno) {
      case TurnoType.manana:
        return [
          BoxShadow(
            color: AppColors.accentBlue.withOpacity(0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
            spreadRadius: 1.r,
          ),
          BoxShadow(
            color: AppColors.lightBlue.withOpacity(0.1),
            blurRadius: 25.r,
            offset: Offset(0, 4.h),
          ),
        ];
      case TurnoType.tarde:
        return [
          BoxShadow(
            color: AppColors.lightBlue.withOpacity(0.25),
            blurRadius: 12.r,
            offset: Offset(0, 6.h),
            spreadRadius: 0.5.r,
          ),
          BoxShadow(
            color: AppColors.accentBlue.withOpacity(0.1),
            blurRadius: 20.r,
            offset: Offset(0, 3.h),
          ),
        ];
      case TurnoType.privado:
        return [
          BoxShadow(
            color: AppColors.primaryNightBlue.withOpacity(0.4),
            blurRadius: 20.r,
            offset: Offset(0, 10.h),
            spreadRadius: 2.r,
          ),
          BoxShadow(
            color: AppColors.secondaryNightBlue.withOpacity(0.2),
            blurRadius: 30.r,
            offset: Offset(0, 5.h),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40.r,
            offset: Offset(0, 15.h),
          ),
        ];
    }
  }

  IconData _iconForTurno(TurnoType turno) {
    switch (turno) {
      case TurnoType.manana:
        return Icons.wb_sunny_rounded;
      case TurnoType.tarde:
        return Icons.wb_cloudy_rounded;
      case TurnoType.privado:
        return Icons.diamond_outlined;
    }
  }

  String _subtitleForTurno(TurnoType turno) {
    switch (turno) {
      case TurnoType.manana:
        return 'Mañana';
      case TurnoType.tarde:
        return 'Tarde';
      case TurnoType.privado:
        return 'Exclusivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundWhite,
            AppColors.backgroundGray.withOpacity(0.5),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNightBlue.withOpacity(0.12),
            blurRadius: 30.r,
            offset: Offset(0, 8.h),
            spreadRadius: 2.r,
          ),
          BoxShadow(
            color: AppColors.accentBlue.withOpacity(0.05),
            blurRadius: 50.r,
            offset: Offset(0, 20.h),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryNightBlue.withOpacity(0.08),
          width: 1.5.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turnos Disponibles',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Selecciona un turno para consultar reservas',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          Row(
            children: TurnoType.values.map((turno) {
              final gradient = _gradientForTurno(turno);
              final shadows = _shadowForTurno(turno);
              final isPrivate = turno == TurnoType.privado;
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: () {
                        if (onTurnoSelected != null) onTurnoSelected!(turno);
                        if (navigateOnSelect) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ReservasView(turno: turno),
                          ));
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 8.w),
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: shadows,
                          // border:
                          //  isPrivate 
                          //   ? Border.all(
                          //       color: Colors.white.withOpacity(0.2),
                          //       width: 1.w,
                          //     )
                          //   : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              // padding: isPrivate 
                              //   ? EdgeInsets.all(8.r)
                              //   // : EdgeInsets.zero,
                              decoration: isPrivate
                                ? BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                  )
                                : null,
                              child: Icon(
                                _iconForTurno(turno),
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              turno.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isPrivate ? 15.sp : 14.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: isPrivate ? 0.5 : 0,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _subtitleForTurno(turno),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
