import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Botón reutilizable de WhatsApp con FloatingActionButton y diálogo de contacto.
class WhatsappContactButton extends StatelessWidget {
  final String? contacto;
  final String? link;
  final String heroTag;

  const WhatsappContactButton({
    Key? key,
    required this.contacto,
    required this.link,
    this.heroTag = 'whatsapp_button',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Contacto WhatsApp'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (contacto != null && contacto!.isNotEmpty) ...[
                    ListTile(
                      leading: const Icon(Icons.phone, color: Color(0xFF25D366)),
                      title: Text('Número: $contacto'),
                      onTap: () async {
                        final waUri = Uri.parse('https://wa.me/$contacto');
                        if (await canLaunchUrl(waUri)) await launchUrl(waUri);
                      },
                    ),
                  ] else ...[
                    const Text('Registre el número de WhatsApp primero'),
                  ],
                  const SizedBox(height: 8),
                  if (link != null && link!.startsWith('https://chat.whatsapp.com/')) ...[
                    ListTile(
                      leading: const Icon(Icons.link, color: Color(0xFF25D366)),
                      title: const Text('Link de WhatsApp'),
                      onTap: () async {
                        final uri = Uri.parse(link!);
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                  ] else if (link != null && link!.isNotEmpty) ...[
                    const Text('Link incorrecto: debe ser enlace de grupo de WhatsApp'),
                  ] else ...[
                    const Text('Registre el enlace de grupo de WhatsApp primero'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
      backgroundColor: Colors.green.shade600,
      foregroundColor: Colors.white,
      icon: Image.asset('assets/images/iconWasap.png', width: 24, height: 24),
      label: const Text('WhatsApp'),
      heroTag: heroTag,
    );
  }
}
