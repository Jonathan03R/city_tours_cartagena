import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AgenciesStatsSection extends StatelessWidget {
  final bool isVisible;

  const AgenciesStatsSection({
    super.key,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AgenciasController>(
      builder: (_, agCtrl, __) {
        return StreamBuilder<List<AgenciaConReservas>>(
          stream: agCtrl.agenciasConReservasStream,
          builder: (_, snapshot) {
            final count = snapshot.data?.length ?? 0;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              height: isVisible ? null : 0,
              child: AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF0D47A1).withOpacity(0.1),
                        const Color(0xFF1976D2).withOpacity(0.15),
                        const Color(0xFF42A5F5).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      width: 1.5.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.15),
                        blurRadius: 12.r,
                        offset: Offset(0, 6.h),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icono con animación
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 0.5),
                        duration: const Duration(milliseconds: 1200),
                        builder: (context, value, child) {
                          return Transform.rotate(
                            angle: value * 0.1,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF1976D2),
                                    const Color(0xFF42A5F5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1976D2).withOpacity(0.4),
                                    blurRadius: 8.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.business_center,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                            ),
                          );
                        },
                      ),
                      
                     SizedBox(width: 20.w),
                      
                      // Información
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Agencias Activas',
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: const Color(0xFF37474F),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'agencia${count != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF546E7A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Indicador visual
                      Container(
                        width: 4.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF1976D2),
                              const Color(0xFF42A5F5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
