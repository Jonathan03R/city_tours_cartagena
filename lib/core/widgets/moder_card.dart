import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool hasGradient;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.hasGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: hasGradient ? AppColors.cardGradient : null,
        color: hasGradient ? null : (backgroundColor ?? AppColors.cardBackground),
        borderRadius: borderRadius ?? BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNightBlue.withOpacity(0.08),
            blurRadius: 20.r,
            offset: Offset(0, 4.h),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.primaryNightBlue.withOpacity(0.04),
            blurRadius: 4.r,
            offset: Offset(0, 1.h),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(20.w),
        child: child,
      ),
    );
  }
}
