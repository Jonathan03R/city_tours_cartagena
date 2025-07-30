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
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.r),
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de Información de Perfil (Editable)
          Card(
            elevation: 3.h,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
            margin: EdgeInsets.only(bottom: 20.h),
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Form(
                key: _profileFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de Perfil',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildEditableTextField(
                      controller: _usernameController,
                      label: 'Usuario',
                      icon: Icons.person_outline,
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
                    SizedBox(height: 12.h),
                    _buildInfoRow( // Roles es solo de lectura
                      icon: Icons.security,
                      label: 'Rol:',
                      value: usuario?.roles.join(', ') ?? 'No disponible',
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
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
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 3.h,
                        ),
                        icon: _isUpdatingProfile
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.w,
                                ),
                              )
                            : Icon(Icons.save_alt, size: 20.w, color: Colors.white),
                        label: Text(
                          _isUpdatingProfile ? 'Guardando...' : 'Guardar Cambios',
                          style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.w600),
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
            elevation: 3.h,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actualizar Contraseña',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 20.h),
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
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
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
                          backgroundColor: Colors.blue.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          elevation: 3.h,
                        ),
                        icon: _isUpdatingPassword
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.w,
                                ),
                              )
                            : Icon(Icons.vpn_key_outlined, size: 20.w, color: Colors.white),
                        label: Text(
                          _isUpdatingPassword ? 'Actualizando...' : 'Actualizar Contraseña',
                          style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.w600),
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade900),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.w, color: Colors.grey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2.w),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),
      ),
    );
  }

  // Widget auxiliar para filas de información no editable
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.w, color: Colors.blue.shade600),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
