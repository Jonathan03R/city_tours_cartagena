import 'dart:ui' show ImageFilter;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (_, snapshot) {
        final results = snapshot.data ?? const <ConnectivityResult>[];
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isOnline
              ? const SizedBox.shrink()
              : IgnorePointer(
                  key: const ValueKey('offline-banner'),
                  ignoring: true,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SafeArea(
                      bottom: false,
                      child: _CompactOfflinePill(),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _CompactOfflinePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        builder: (context, t, child) {
          // Clamp para garantizar 0..1 y evitar aserciones
          final double tt = t.clamp(0.0, 1.0);
          return Opacity(
            opacity: tt,
            child: Transform.translate(
              offset: Offset(0, (1 - tt) * -12),
              child: Transform.scale(
                scale: 0.7 + (tt * 0.3), // Animación de escala sutil
                child: child,
              ),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.symmetric(
            horizontal: 10.w, 
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.shade600.withOpacity(0.9),
                Colors.red.shade700.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 12.sp,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'Sin conexión',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
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
  }
}
