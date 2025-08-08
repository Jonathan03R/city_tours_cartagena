import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abre WhatsApp para verificar disponibilidad del "servicio privado" de HOY.
/// - Respeta la regla shouldShowWhatsAppButton(turno, fecha).
/// - Usa configuracion.contact_whatsapp como destino.
/// - Mensaje: "Hola, soy de {nombreAgencia}. ¿Hay disponibilidad para servicio privado hoy?"
///
/// Requisitos:
/// - pubspec.yaml -> url_launcher: ^6.3.0
/// - import 'package:url_launcher/url_launcher.dart';
Future<void> openWhatsAppPrivado(
  BuildContext context, {
  required TurnoType turno,
  required String nombreAgencia,
}) async {
  final reservasController = context.read<ReservasController>();
  final configuracion = context.read<ConfiguracionController>().configuracion;
  final hoy = DateTime.now();

  try {
    final shouldOpen = await reservasController.shouldShowWhatsAppButton(
      turno: turno,
      fecha: hoy,
    );

    if (!shouldOpen) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se requiere verificación por WhatsApp en este momento.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final raw = (configuracion?.contact_whatsapp ?? '').trim();
    if (raw.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay número de WhatsApp configurado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Limpia el teléfono: quita +, espacios y caracteres no numéricos
    final telefono = raw.replaceAll(RegExp(r'[\s\-$$$$\+]'), '');
    final mensaje = Uri.encodeComponent(
      'Hola, soy de $nombreAgencia. ¿Hay disponibilidad para servicio privado hoy?',
    );

    final uriApp = Uri.parse('whatsapp://send?phone=$telefono&text=$mensaje');
    final uriWeb = Uri.parse('https://wa.me/$telefono?text=$mensaje');

    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(uriWeb)) {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error abriendo WhatsApp: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}