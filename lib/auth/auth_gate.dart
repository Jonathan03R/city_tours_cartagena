import 'package:citytourscartagena/auth/LoginScreen.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
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

    // 3) Ya autenticado y con usuario cargado
    // return const MainScreen();
    // return PdfPreviewScreen();
    return const MainScreen();
  }
}