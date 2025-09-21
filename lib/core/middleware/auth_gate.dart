import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/widgets/pantallas_carga/splash.dart';
import 'package:citytourscartagena/screens/Inicio/operadores/operadores_main_screen.dart';
import 'package:citytourscartagena/screens/auth/logeo/login.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthSupabaseController>();

    // 1. Pantalla de carga inicial
    if (auth.isLoading) return const SplashScreen();

    // 2. No autenticado → Login
    if (!auth.isAuthenticated) return const LoginScreen();

    // 3. Usuario autenticado
    final usuario = auth.usuario;

    if (usuario == null) return const LoginScreen();

    // Verificamos si está activo
    if (!usuario.activo) return const LoginScreen();

    // Redirigir según tipo_usuario
    switch (usuario.tipoUsuario) {
      // case 'admin':
      // //   return const HomeAdmin();
      // case 'operador':
      //   return const HomeOperador();
      case 'operador':
        return const MainOperadorScreen();
      case 'agencias':
        return const MainScreen();
      default:
        return const LoginScreen(); // fallback
    }
  }
}
