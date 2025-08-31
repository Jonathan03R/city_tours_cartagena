import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isOutlined;
  final IconData? icon;
  final bool isLoading;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSecondary = false,
    this.isOutlined = false,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        gradient: !isOutlined && !isSecondary ? AppColors.primaryGradient : null,
        color: isOutlined ? Colors.transparent : 
               isSecondary ? AppColors.backgroundGray : null,
        borderRadius: BorderRadius.circular(12.r),
        border: isOutlined ? Border.all(
          color: AppColors.accentBlue,
          width: 1.5.w,
        ) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOutlined ? AppColors.accentBlue : Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                if (icon != null && !isLoading) ...[
                  Icon(
                    icon,
                    size: 18.sp,
                    color: isOutlined ? AppColors.accentBlue :
                           isSecondary ? AppColors.textPrimary : Colors.white,
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isOutlined ? AppColors.accentBlue :
                           isSecondary ? AppColors.textPrimary : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
