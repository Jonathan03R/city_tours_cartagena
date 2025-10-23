import 'dart:ui';

import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/screens/auth/registro/registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _error;
  bool _isDarkMode = true; // Por defecto modo oscuro

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final authController = Provider.of<AuthSupabaseController>(
      context,
      listen: false,
    );

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final perfil = await authController.login(email: email, password: password);

    if (!mounted) return;

    if (perfil != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inicio de sesión exitoso'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() => _error = authController.error ?? 'Error desconocido');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthSupabaseController>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.getBackgroundGradient(_isDarkMode),
        ),
        child: Stack(
          children: [
            // Elementos decorativos de fondo
            _buildBackgroundElements(size),

            // Botón para cambiar tema
            Positioned(top: 50.h, right: 20.w, child: _buildThemeToggle()),

            // Contenido principal
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(height: 80.h),
                                    _buildHeader(),
                                    SizedBox(height: 60.h),
                                    _buildLoginCard(authController),
                                    SizedBox(height: 30.h),
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

  Widget _buildBackgroundElements(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -size.height * 0.1,
          left: -size.width * 0.2,
          child: Transform.rotate(
            angle: -0.3,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: BoxDecoration(
                color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(
                  0.03,
                ),
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
                color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(
                  0.02,
                ),
                borderRadius: BorderRadius.circular(size.width * 0.15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardColor(_isDarkMode).withOpacity(0.1),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25.r),
          onTap: () => setState(() => _isDarkMode = !_isDarkMode),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppColors.getTextColor(_isDarkMode),
              size: 24.r,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 120.w,
          height: 120.h,
          decoration: BoxDecoration(
            gradient: AppColors.getButtonGradient(_isDarkMode),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
                blurRadius: 25.r,
                offset: Offset(0, 12.h),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/images/logo.png'),
            ),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'CITY TOURS',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppColors.getTextColor(_isDarkMode),
          ),
        ),
        Text(
          'CLIMATIZADO',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            color: AppColors.getSecondaryTextColor(_isDarkMode),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.getAccentColor(_isDarkMode).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(
                0.1,
              ),
            ),
          ),
          child: Text(
            'Acceso de Administrador',
            style: TextStyle(
              color: AppColors.getTextColor(_isDarkMode),
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(AuthSupabaseController auth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: AppColors.getCardGradient(_isDarkMode),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.1),
            blurRadius: 25.r,
            offset: Offset(0, 15.h),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: EdgeInsets.all(32.r),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Text(
                    'Bienvenido de vuelta',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextColor(_isDarkMode),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Inicia sesión para acceder al panel',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.getSecondaryTextColor(_isDarkMode),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  if (_error != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: AppColors.getTextColor(_isDarkMode),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],

                  _buildGlassTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty || !v.contains('@'))
                        ? 'Ingrese un correo válido'
                        : null,
                  ),
                  SizedBox(height: 20.h),

                  _buildGlassTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
                  ),
                  SizedBox(height: 32.h),

                  _buildLoginButton(auth),

                  SizedBox(height: 20.h),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegistroScreen(),
                        ),
                      );
                    },
                    child: Text(
                      '¿No tienes cuenta? Regístrate',
                      style: TextStyle(
                        color: AppColors.getAccentColor(_isDarkMode),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
            (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.15),
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? !_showPassword : false,
        keyboardType: keyboardType,
        style: TextStyle(
          color: AppColors.getTextColor(_isDarkMode),
          fontSize: 16.sp,
        ),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.getSecondaryTextColor(_isDarkMode),
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.getSecondaryTextColor(_isDarkMode),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.getSecondaryTextColor(_isDarkMode),
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(AuthSupabaseController auth) {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: AppColors.getButtonGradient(_isDarkMode),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: auth.isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _error = null);
                  await _onLoginPressed();
                },
          child: Container(
            alignment: Alignment.center,
            child: auth.isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18.sp,
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
          '¿Necesitas ayuda?',
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(_isDarkMode),
            fontSize: 16.sp,
            decoration: TextDecoration.underline,
            decorationColor: AppColors.getSecondaryTextColor(_isDarkMode),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50.w,
              height: 1.h,
              color: AppColors.getSecondaryTextColor(
                _isDarkMode,
              ).withOpacity(0.3),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                'Seguridad y Confianza',
                style: TextStyle(
                  color: AppColors.getSecondaryTextColor(
                    _isDarkMode,
                  ).withOpacity(0.7),
                  fontSize: 12.sp,
                ),
              ),
            ),
            Container(
              width: 50.w,
              height: 1.h,
              color: AppColors.getSecondaryTextColor(
                _isDarkMode,
              ).withOpacity(0.3),
            ),
          ],
        ),
      ],
    );
  }
}
