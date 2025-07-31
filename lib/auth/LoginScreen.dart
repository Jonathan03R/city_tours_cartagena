import 'dart:ui'; // Para BackdropFilter

import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // ¡Importante!
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _showPassword = false;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(
        milliseconds: 1200,
      ), // Animación de entrada suave
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F1C2E), // Azul Noche Profundo
              Color(0xFF1A2B42), // Azul Noche Ligeramente más Claro
            ],
          ),
        ),
        child: Stack(
          children: [
            // Patrones de fondo sutiles y abstractos (menos orgánicos, más geométricos)
            Positioned(
              top: -size.height * 0.1,
              left: -size.width * 0.2,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03), // Muy sutil
                    borderRadius: BorderRadius.circular(size.width * 0.2),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              right: -size.width * 0.2,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02), // Muy sutil
                    borderRadius: BorderRadius.circular(size.width * 0.15),
                  ),
                ),
              ),
            ),

            // Contenido principal
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      // Usamos LayoutBuilder para obtener la altura disponible
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                            ), // Usar .w para padding horizontal
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints
                                    .maxHeight, // Asegura que el contenido ocupe al menos la altura disponible
                              ),
                              child: IntrinsicHeight(
                                // Permite que los hijos tomen su altura natural, pero fuerza al padre a llenar el espacio
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween, // Distribuye el espacio entre los elementos
                                  children: [
                                    SizedBox(
                                      height: 80.h,
                                    ), // Usar .h para altura
                                    _buildHeader(),
                                    SizedBox(
                                      height: 60.h,
                                    ), // Usar .h para altura
                                    _buildLoginCard(auth),
                                    SizedBox(
                                      height: 30.h,
                                    ), // Usar .h para altura
                                    _buildFooter(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120.w, // Usar .w para ancho
          height: 120.h, // Usar .h para alto
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2B4F81),
                Color(0xFF1A2B42),
              ], // Gradiente azul oscuro para el fondo del logo
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 25.r, // Usar .r para radio de desenfoque
                offset: Offset(0, 12.h), // Usar .h para offset vertical
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r), // Usar .r para padding circular
            child: const CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage(
                'assets/images/logo.png',
              ), // Asumiendo que el logo es compatible con azul oscuro
            ),
          ),
        ),
        SizedBox(height: 24.h), // Usar .h para altura
        const Text(
          'CITY TOURS',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        const Text(
          'CLIMATIZADO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 8.h), // Usar .h para altura
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 8.h,
          ), // Usar .w y .h
          decoration: BoxDecoration(
            color: const Color(
              0xFF2B4F81,
            ).withValues(alpha: 0.5), // Acento azul oscuro
            borderRadius: BorderRadius.circular(20.r), // Usar .r
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Text(
            'Acceso de Administrador', // Texto más serio
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthController auth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w), // Usar .w
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(
              alpha: 0.08,
            ), // Menos transparente, cristal más oscuro
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(25.r), // Usar .r
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1), // Borde sutil
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 25.r, // Usar .r
            offset: Offset(0, 15.h), // Usar .h
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r), // Usar .r
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Menos desenfoque
          child: Padding(
            padding: EdgeInsets.all(32.r), // Usar .r
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    'Bienvenido de vuelta',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h), // Usar .h
                  Text(
                    'Inicia sesión para acceder al panel', // Texto más serio
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  SizedBox(height: 32.h), // Usar .h

                  if (_error != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.r), // Usar .r
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF8B0000,
                        ).withValues(alpha: 0.3), // Rojo oscuro y apagado
                        borderRadius: BorderRadius.circular(12.r), // Usar .r
                        border: Border.all(
                          color: const Color(0xFF8B0000).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20.h), // Usar .h
                  ],

                  _buildGlassTextField(
                    controller: _userCtrl,
                    label: 'Usuario',
                    icon: Icons.person_outline_rounded,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Ingrese su usuario' : null,
                  ),
                  SizedBox(height: 20.h), // Usar .h

                  _buildGlassTextField(
                    controller: _passCtrl,
                    label: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ),
                  SizedBox(height: 32.h), // Usar .h

                  _buildSeriousButton(auth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(
              alpha: 0.1,
            ), // Fondo de campo de entrada más oscuro
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r), // Usar .r
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !_showPassword : false,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ), // Usar .w y .h
        ),
      ),
    );
  }

  /// este boton es el que se encarga de iniciar sesión

  Widget _buildSeriousButton(AuthController auth) {
    return Container(
      width: double.infinity,
      height: 56.h, // Usar .h
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2B4F81),
            Color(0xFF1A2B42),
          ], // Gradiente azul noche
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.r), // Usar .r
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15.r, // Usar .r
            offset: Offset(0, 8.h), // Usar .h
          ),
        ],
      ),

      /// Aquí se usa Material para el efecto de InkWell
      /// InkWell es el que permite el efecto de pulsación
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r), // Usar .r
          /// Aquí se usa el onTap para manejar el inicio de sesión
          /// Si auth.isLoading es true, el botón no responderá a los toques
          onTap: auth.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (!mounted) return;
                  setState(() => _error = null);

                  try {
                    await auth.login(
                      _userCtrl.text.trim(),
                      _passCtrl.text.trim(),
                    );
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    setState(() => _error = _getErrorMessage(e));
                  }
                },
          child: Container(
            alignment: Alignment.center,
            child: auth.isLoading
                ? SizedBox(
                    width: 24.w, // Usar .w
                    height: 24.h, // Usar .h
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'INICIAR SESIÓN', // Texto más formal
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '¿Necesitas ayuda?', // Texto más formal
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 16,
            decoration: TextDecoration.underline,
            decorationColor: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 20.h), // Usar .h
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50.w, // Usar .w
              height: 1.h, // Línea más delgada, usar .h
              color: Colors.white.withValues(alpha: 0.2),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w), // Usar .w
              child: Text(
                'Seguridad y Confianza', // Eslogan más serio
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              width: 50.w, // Usar .w
              height: 1.h, // Línea más delgada, usar .h
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ],
    );
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario no encontrado.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'Correo inválido.';
      case 'user-disabled':
        return 'Cuenta deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Prueba más tarde.';
      case 'invalid-credential':
        return 'Credenciales inválidas.';
      case 'network-request-failed':
        return 'Error de red. Verifica tu conexión.';
      case 'user-inactive': // ← nuevo
        return 'Cuenta desactivada. Contacta al administrador.';
      case 'internal-error':
        return 'Error interno. Intenta nuevamente.';
      default:
        return e.message ?? 'Error al iniciar sesión.';
    }
  }
}
