import 'dart:ui';

import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/controller/auth/registro_paginacion_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/screens/auth/logeo/login.dart';
import 'package:citytourscartagena/screens/auth/registro/nevegacion/ingresar_contrasena.dart';
import 'package:citytourscartagena/screens/auth/registro/nevegacion/ingresar_datos_personales.dart';
import 'package:citytourscartagena/screens/auth/registro/nevegacion/ingresar_email.dart';
import 'package:citytourscartagena/screens/auth/registro/nevegacion/ingresar_empresa.dart';
import 'package:citytourscartagena/screens/auth/registro/nevegacion/tipo_equipo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen>
    with TickerProviderStateMixin {
  late RegistroWizardController _wizardController;
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isDarkMode = true;
  int _previousPaso = 0;

  @override
  void initState() {
    super.initState();
    _wizardController = RegistroWizardController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _animationController.forward();
    _slideController.forward();
    
    _previousPaso = _wizardController.pasoActual;

    _wizardController.addListener(_onWizardChange);
  }


  void _onWizardChange() {
    if (mounted) {
      if (_wizardController.pasoActual != _previousPaso) {
        _slideController.reset();
        _slideController.forward();
        _previousPaso = _wizardController.pasoActual;
      }
    }
  }

  // void _onWizardChange() {
  //   if (mounted) {
  //     _slideController.reset();
  //     _slideController.forward();
  //   }
  // }

  @override
  void dispose() {
    _wizardController.removeListener(_onWizardChange);
    _wizardController.dispose();
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
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
            _buildBackgroundElements(size),
            
            Positioned(
              top: 50.h,
              right: 20.w,
              child: _buildThemeToggle(),
            ),

            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        _buildHeader(),
                        SizedBox(height: 20.h),
                        _buildProgressIndicator(),
                        Expanded(
                          child: _buildStepContent(authController),
                        ),
                        _buildBottomNavigation(authController),
                        SizedBox(height: 20.h),
                      ],
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
                color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.03),
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
                color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.02),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.h,
            decoration: BoxDecoration(
              gradient: AppColors.getButtonGradient(_isDarkMode),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
                  blurRadius: 20.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Icon(
              Icons.person_add_rounded,
              color: AppColors.white,
              size: 32.r,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'CREAR CUENTA',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppColors.getTextColor(_isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ListenableBuilder(
        listenable: _wizardController,
        builder: (context, child) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paso ${_wizardController.pasoActual + 1} de ${_wizardController.totalPasos}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.getSecondaryTextColor(_isDarkMode),
                    ),
                  ),
                  Text(
                    '${(_wizardController.progreso * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getAccentColor(_isDarkMode),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              LinearProgressIndicator(
                value: _wizardController.progreso,
                backgroundColor: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.getAccentColor(_isDarkMode),
                ),
                minHeight: 4.h,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepContent(AuthSupabaseController authController) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 20.h),
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      gradient: AppColors.getCardGradient(_isDarkMode),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: (_isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.1),
                          blurRadius: 20.r,
                          offset: Offset(0, 10.h),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: ListenableBuilder(
                          listenable: _wizardController,
                          builder: (context, child) {
                            return _getCurrentStep();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getCurrentStep() {
    switch (_wizardController.pasoActual) {
      case 0:
        return PasoInformacionPersonal(
          controller: _wizardController,
          isDarkMode: _isDarkMode,
        );
      case 1:
        return PasoEmail(
          controller: _wizardController,
          isDarkMode: _isDarkMode,
        );
      case 2:
        return PasoPassword(
          controller: _wizardController,
          isDarkMode: _isDarkMode,
        );
      case 3:
        return PasoTipoEquipo(
          controller: _wizardController,
          isDarkMode: _isDarkMode,
        );
      case 4:
        return PasoCodigoRelacion(
          controller: _wizardController,
          isDarkMode: _isDarkMode,
        );
      default:
        return Container();
    }
  }

  Widget _buildBottomNavigation(AuthSupabaseController authController) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ListenableBuilder(
        listenable: _wizardController,
        builder: (context, child) {
          final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          return Column(
            children: [
              Row(
                children: [
                  if (!_wizardController.esPrimerPaso)
                    Expanded(
                      child: _buildBotonSecundario(
                        texto: 'Atrás',
                        onTap: _wizardController.pasoAnterior,
                      ),
                    ),
                  if (!_wizardController.esPrimerPaso) SizedBox(width: 16.w),
                  Expanded(
                    flex: 2,
                    child: _buildBotonPrincipal(
                      texto: _wizardController.esUltimoPaso ? 'Registrarse' : 'Continuar',
                      habilitado: _wizardController.pasoActualValido,
                      cargando: authController.isLoading,
                      onTap: () => _wizardController.esUltimoPaso 
                          ? _registrarUsuario(authController)
                          : _wizardController.siguientePaso(),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 16.h),

              // Ocultar este enlace cuando el teclado esté abierto (no interesa al usuario)
              if (!isKeyboardOpen)
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    '¿Ya tienes cuenta? Inicia sesión',
                    style: TextStyle(
                      color: AppColors.getAccentColor(_isDarkMode),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBotonPrincipal({
    required String texto,
    required bool habilitado,
    required VoidCallback onTap,
    bool cargando = false,
  }) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        gradient: habilitado 
            ? AppColors.getButtonGradient(_isDarkMode)
            : LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.3),
                  Colors.grey.withOpacity(0.2),
                ],
              ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: habilitado ? [
          BoxShadow(
            color: Colors.black.withOpacity(_isDarkMode ? 0.3 : 0.1),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: habilitado && !cargando ? onTap : null,
          child: Container(
            alignment: Alignment.center,
            child: cargando
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    texto,
                    style: TextStyle(
                      color: habilitado ? AppColors.white : Colors.grey,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonSecundario({
    required String texto,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.getAccentColor(_isDarkMode).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              texto,
              style: TextStyle(
                color: AppColors.getAccentColor(_isDarkMode),
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _registrarUsuario(AuthSupabaseController authController) async {
    final datos = _wizardController.obtenerDatosRegistro();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await authController.register(
      nombre: datos['nombre'],
      apellido: datos['apellido'],
      email: datos['email'],
      password: datos['password'],
      alias: datos['alias'],
      rol: datos['rol'],
      tipoUsuario: datos['tipoUsuario'],
      codigoRelacion: datos['codigoRelacion'],
    );

    if (authController.usuario != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('¡Registro exitoso! Bienvenido ${datos['alias']}'),
          backgroundColor: AppColors.success,
        ),
      );
      
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(authController.error ?? 'Error en el registro'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
