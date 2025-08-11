// Reemplazo del botón de WhatsApp en tu _buildAgencyHeader
// Usa este widget en lugar del IconButton actual.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyAvailabilityTag extends StatefulWidget {
  const VerifyAvailabilityTag({
    super.key,
    required this.telefonoRaw,
    required this.message,
    this.tooltip = 'Verificar disponibilidad hoy',
    this.compact = false,
  });

  final String telefonoRaw;
  final String message;
  final String tooltip;
  final bool compact;

  @override
  State<VerifyAvailabilityTag> createState() => _VerifyAvailabilityTagState();
}

class _VerifyAvailabilityTagState extends State<VerifyAvailabilityTag>
    with SingleTickerProviderStateMixin {
  bool _isLaunching = false;
  late final AnimationController _shadowController;
  late final Animation<double> _shadowOpacity;

  late final Animation<double> _scaleAnimation;

  @override
void initState() {
  super.initState();
  _shadowController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  // esto es para la sombra
  _shadowOpacity = Tween<double>(begin: 0.5, end: 0.80).animate(
    CurvedAnimation(parent: _shadowController, curve: Curves.easeInOut),
  );

  _scaleAnimation = Tween<double>(begin: 1.0, end: 1.005).animate(
    CurvedAnimation(parent: _shadowController, curve: Curves.easeInOut),
  );
}
  @override
  void dispose() {
    _shadowController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    if (_isLaunching) return;
    HapticFeedback.selectionClick();

    final raw = widget.telefonoRaw.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay número de WhatsApp configurado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLaunching = true);
    try {
      final telefono = raw.replaceAll(RegExp(r'[^\d]'), '');
      final mensaje = Uri.encodeComponent(widget.message);

      final uriApp = Uri.parse('whatsapp://send?phone=$telefono&text=$mensaje');
      final uriWeb = Uri.parse('https://wa.me/$telefono?text=$mensaje');

      if (await canLaunchUrl(uriApp)) {
        await launchUrl(uriApp, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error abriendo WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  @override
Widget build(BuildContext context) {
  final bg = Colors.red.shade600;
  final border = Colors.red.shade800;
  final textColor = Colors.white;
  final iconColor = Colors.white;

  final padding = EdgeInsets.symmetric(
    horizontal: widget.compact ? 14.w : 18.w,
    vertical: widget.compact ? 8.h : 12.h,
  );

  return AnimatedBuilder(
    animation: _shadowController,
    builder: (context, _) {
      return Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(_shadowOpacity.value),
                blurRadius: 25,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(color: border, width: 2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              splashColor: Colors.white.withOpacity(0.12),
              onTap: _isLaunching ? null : _openWhatsApp,
              child: Padding(
                padding: padding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLaunching)
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      )
                    else
                      Icon(Icons.chat_bubble_rounded,
                          size: 16.sp, color: iconColor),
                    SizedBox(width: 10.w),
                    Text(
                      'Verificar disponibilidad',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
}
