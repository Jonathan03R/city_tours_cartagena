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
  // Si compact true, usa un padding más pequeño (por si el espacio es muy reducido)
  final bool compact;

  @override
  State<VerifyAvailabilityTag> createState() => _VerifyAvailabilityTagState();
}

class _VerifyAvailabilityTagState extends State<VerifyAvailabilityTag> {
  bool _isLaunching = false;

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
      // Conserva solo dígitos
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
    final bg = Colors.green.shade50;
    final border = Colors.green.shade200;
    final text = Colors.green.shade800;
    final icon = Colors.green.shade700;

    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Semantics(
      button: true,
      label: 'Verificar disponibilidad hoy en WhatsApp',
      child: Tooltip(
        message: widget.tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _isLaunching ? null : _openWhatsApp,
            child: Ink(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: border),
              ),
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLaunching)
                    SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: icon,
                      ),
                    )
                  else
                    Icon(Icons.message, size: 16, color: icon),
                  SizedBox(width: 8.w),
                  Text(
                    'Verificar disponibilidad hoy',
                    style: TextStyle(
                      color: text,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
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