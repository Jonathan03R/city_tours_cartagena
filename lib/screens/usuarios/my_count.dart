import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MiCuentaTab extends StatefulWidget {
  const MiCuentaTab({super.key});

  @override
  State<MiCuentaTab> createState() => _MiCuentaTabState();
}

class _MiCuentaTabState extends State<MiCuentaTab> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _nameController;
  late TextEditingController _emailController; // Para el email opcional
  late TextEditingController _phoneController;
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isUpdatingProfile = false;
  bool _isUpdatingPassword = false;

  // Definición de colores personalizados
  static const Color _nightBlue = Color(0xFF1A2B4C); // Un azul noche profundo
  static const Color _lightGrey = Color(0xFFF0F2F5); // Un gris muy claro para fondos sutiles
  static const Color _darkGreyText = Color(0xFF333333); // Gris oscuro para texto principal
  static const Color _mediumGreyText = Color(0xFF666666); // Gris medio para texto secundario

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    _usernameController = TextEditingController(text: auth.appUser?.usuario ?? '');
    _nameController = TextEditingController(text: auth.appUser?.nombre ?? '');
    _emailController = TextEditingController(text: auth.appUser?.email ?? ''); // Inicializar con email del usuario
    _phoneController = TextEditingController(text: auth.appUser?.telefono ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.r),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final usuario = auth.appUser;

    // Actualizar controladores si el usuario cambia (ej. al recargar la app)
    // Solo si el controlador no está enfocado para evitar perder la entrada del usuario
    if (!_usernameController.hasListeners || _usernameController.text != (usuario?.usuario ?? '')) {
      _usernameController.text = usuario?.usuario ?? '';
    }
    if (!_nameController.hasListeners || _nameController.text != (usuario?.nombre ?? '')) {
      _nameController.text = usuario?.nombre ?? '';
    }
    if (!_emailController.hasListeners || _emailController.text != (usuario?.email ?? '')) {
      _emailController.text = usuario?.email ?? '';
    }
    if (!_phoneController.hasListeners || _phoneController.text != (usuario?.telefono ?? '')) {
      _phoneController.text = usuario?.telefono ?? '';
    }

    return Scaffold(
      backgroundColor: _lightGrey, // Fondo general de la pantalla
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r), // Aumentar el padding general
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Información de Perfil (Editable)
            Card(
              elevation: 6.h, // Aumentar la elevación para un efecto más premium
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)), // Bordes más redondeados
              margin: EdgeInsets.only(bottom: 24.h), // Margen inferior
              color: Colors.white, // Fondo de la tarjeta blanco
              child: Padding(
                padding: EdgeInsets.all(24.r), // Padding interno de la tarjeta
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información de Perfil',
                        style: TextStyle(
                          fontSize: 18.sp, // Tamaño de fuente más grande
                          fontWeight: FontWeight.w800, // Más negrita
                          color: _nightBlue, // Color azul noche
                        ),
                      ),
                      SizedBox(height: 24.h), // Espacio
                      _buildEditableTextField(
                        controller: _usernameController,
                        label: 'Usuario',
                        icon: Icons.person_outline,
                        readOnly: true, // Hacer el campo de usuario de solo lectura
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre de usuario no puede estar vacío.';
                          }
                          if (value.contains('@') || value.contains(' ')) {
                            return 'El usuario no debe contener "@" ni espacios.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),
                      _buildEditableTextField(
                        controller: _nameController,
                        label: 'Nombre Completo',
                        icon: Icons.badge_outlined,
                        validator: (value) => value == null || value.isEmpty ? 'Ingrese su nombre completo.' : null,
                      ),
                      SizedBox(height: 20.h),
                      _buildEditableTextField(
                        controller: _emailController,
                        label: 'Email (Opcional)',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Ingrese un email válido o déjelo vacío.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),
                      _buildEditableTextField(
                        controller: _phoneController,
                        label: 'Teléfono (Opcional)',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 20.h), // Espacio antes del rol
                      _buildInfoRow( // Roles es solo de lectura
                        icon: Icons.security,
                        label: 'Rol:',
                        value: usuario?.roles.join(', ') ?? 'No disponible',
                      ),
                      SizedBox(height: 30.h), // Espacio antes del botón
                      SizedBox(
                        width: double.infinity,
                        height: 55.h, // Altura del botón
                        child: ElevatedButton.icon(
                          onPressed: _isUpdatingProfile ? null : () async {
                            if (_profileFormKey.currentState!.validate()) {
                              setState(() {
                                _isUpdatingProfile = true;
                              });
                              try {
                                await auth.updateCurrentUserProfile(
                                  username: _usernameController.text.trim(),
                                  name: _nameController.text.trim(),
                                  email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                                  phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                                );
                                _showSnackBar('Perfil actualizado con éxito.');
                              } catch (e) {
                                _showSnackBar('Error al actualizar perfil: ${e.toString()}', isError: true);
                              } finally {
                                setState(() {
                                  _isUpdatingProfile = false;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _nightBlue, // Color azul noche para el botón
                            foregroundColor: Colors.white, // Color del texto e icono blanco
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r), // Bordes más redondeados
                            ),
                            elevation: 4.h, // Elevación del botón
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          icon: _isUpdatingProfile
                              ? SizedBox(
                                  width: 24.w,
                                  height: 24.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5.w,
                                  ),
                                )
                              : Icon(Icons.save_alt, size: 22.w),
                          label: Text(
                            _isUpdatingProfile ? 'Guardando...' : 'Guardar Cambios',
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700), // Texto más grande y negrita
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Sección de Actualización de Contraseña
            Card(
              elevation: 6.h, // Aumentar la elevación
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)), // Bordes más redondeados
              color: Colors.white, // Fondo de la tarjeta blanco
              child: Padding(
                padding: EdgeInsets.all(24.r), // Padding interno
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actualizar Contraseña',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: _nightBlue,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildEditableTextField(
                        controller: _newPassController,
                        label: 'Nueva contraseña',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        validator: (value) => value != null && value.length >= 6
                            ? null
                            : 'Mínimo 6 caracteres.',
                      ),
                      SizedBox(height: 20.h),
                      _buildEditableTextField(
                        controller: _confirmPassController,
                        label: 'Confirmar contraseña',
                        icon: Icons.lock_reset,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirme su contraseña.';
                          }
                          if (value != _newPassController.text) {
                            return 'Las contraseñas no coinciden.';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 30.h),
                      SizedBox(
                        width: double.infinity,
                        height: 55.h,
                        child: ElevatedButton.icon(
                          onPressed: _isUpdatingPassword ? null : () async {
                            if (_passwordFormKey.currentState!.validate()) {
                              setState(() {
                                _isUpdatingPassword = true;
                              });
                              try {
                                await auth.updateCurrentUserPassword(_newPassController.text);
                                _showSnackBar('Contraseña actualizada con éxito.');
                                _newPassController.clear();
                                _confirmPassController.clear();
                              } on FirebaseAuthException catch (e) {
                                _showSnackBar('Error: ${e.message ?? "No se pudo actualizar la contraseña."}', isError: true);
                              } catch (e) {
                                _showSnackBar('Error inesperado: ${e.toString()}', isError: true);
                              } finally {
                                setState(() {
                                  _isUpdatingPassword = false;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _nightBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            elevation: 4.h,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          icon: _isUpdatingPassword
                              ? SizedBox(
                                  width: 24.w,
                                  height: 24.h,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5.w,
                                  ),
                                )
                              : Icon(Icons.vpn_key_outlined, size: 22.w),
                          label: Text(
                            _isUpdatingPassword ? 'Actualizando...' : 'Actualizar Contraseña',
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para campos de texto editables
  Widget _buildEditableTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false, // Nuevo parámetro para hacer el campo de solo lectura
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      readOnly: readOnly, // Aplicar el estado de solo lectura
      style: TextStyle(
        fontSize: 14.sp, // Tamaño de fuente ligeramente más grande
        color: readOnly ? _mediumGreyText : _darkGreyText, // Color de texto diferente si es de solo lectura
        fontWeight: readOnly ? FontWeight.w500 : FontWeight.w600,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _mediumGreyText, fontSize: 12.sp),
        prefixIcon: Icon(icon, size: 22.w, color: _nightBlue), // Icono azul noche
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r), // Bordes más redondeados
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _nightBlue, width: 2.w), // Borde enfocado azul noche
        ),
        disabledBorder: OutlineInputBorder( // Estilo para campo deshabilitado
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.w),
        ),
        filled: readOnly, // Rellenar si es de solo lectura
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white, // Color de relleno para solo lectura
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w), // Padding interno
      ),
    );
  }

  // Widget auxiliar para filas de información no editable
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Centrar verticalmente
      children: [
        Icon(icon, size: 22.w, color: _nightBlue), // Icono azul noche
        SizedBox(width: 12.w), // Espacio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600, // Más negrita
                  color: _mediumGreyText, // Gris medio
                ),
              ),
              SizedBox(height: 4.h), // Pequeño espacio entre label y value
              Text(
                value,
                style: TextStyle(
                  fontSize: 10.sp, // Tamaño de fuente más grande
                  fontWeight: FontWeight.w700, // Más negrita
                  color: _darkGreyText, // Gris oscuro
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}