import 'package:citytourscartagena/auth/LoginScreen.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/utils/notification_handler.dart';
// import 'package:citytourscartagena/core/test/pdfpreview.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // 1) No hay sesión
    if (auth.user == null) {
      return LoginScreen();
    }

    // 2) Sesión iniciada pero aún cargando el modelo Firestore
    if (auth.appUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 3) Ya autenticado y con usuario cargado: devolvemos un wrapper
    // que ejecuta la navegación tras el primer frame, de forma robusta (sin delays).
    return const _MainEntryAfterFirstFrame();
  }
}

class _MainEntryAfterFirstFrame extends StatefulWidget {
  const _MainEntryAfterFirstFrame();

  @override
  State<_MainEntryAfterFirstFrame> createState() => _MainEntryAfterFirstFrameState();
}

class _MainEntryAfterFirstFrameState extends State<_MainEntryAfterFirstFrame> {
  bool _ran = false;

  @override
  void initState() {
    super.initState();
    // Ejecutar justo después del primer frame de esta pantalla principal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ran) return;
      _ran = true;
      debugPrint('[AuthGate] After first frame -> procesando notificación pendiente');
      NotificationHandler.processPendingNotificationIfAny();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Renderiza la pantalla principal real.
    return const MainScreen();
  }
}
