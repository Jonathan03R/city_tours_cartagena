import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ErrorDialogs {
  static Future<void> showErrorDialog(BuildContext context, String msg) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(msg, style: TextStyle(color: Colors.red.shade300)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static Future<void> showDialogVerificarDisponibilidad(BuildContext context, String? whatsapp) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificar disponibilidad'),
        content: const Text('Se ha superado el límite de cupos para este turno. ¿Deseas contactar al administrador por WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          if (whatsapp != null && whatsapp.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.message, color: Colors.green),
              label: const Text('Contactar WhatsApp'),
              onPressed: () async {
                final telefono = whatsapp.replaceAll('+', '').replaceAll(' ', '');
                final uriApp = Uri.parse('whatsapp://send?phone=$telefono');
                final uriWeb = Uri.parse('https://wa.me/$telefono');
                if (await canLaunchUrl(uriApp)) {
                  await launchUrl(uriApp, mode: LaunchMode.externalApplication);
                } else if (await canLaunchUrl(uriWeb)) {
                  await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se pudo abrir WhatsApp'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
                Navigator.of(ctx).pop();
              },
            ),
        ],
      ),
    );
  }
}
