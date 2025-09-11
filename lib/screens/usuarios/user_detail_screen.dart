import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/models/roles.dart';
import 'package:citytourscartagena/core/models/usuarios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// Colores de la paleta "Azul Noche y Blanco" definidos globalmente en este archivo
const Color _nightBlue = Color(0xFF1A237E); // Azul noche profundo
const Color _lightNightBlue = Color(0xFF3F51B5); // Azul más claro para acentos
const Color _white = Colors.white;
const Color _lightGrey = Color(
  0xFFF5F5F5,
); // Gris muy claro para fondos de campos
const Color _darkGreyText = Color(
  0xFF212121,
); // Gris oscuro para texto principal
const Color _readOnlyGrey = Color(
  0xFFE0E0E0,
); // Gris para campos de solo lectura

class UserDetailScreen extends StatefulWidget {
  final Usuarios usuario;
  const UserDetailScreen({super.key, required this.usuario});

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController
  _phoneCtrl; // Asumo que es 'telefono' en tu modelo Usuarios
  late List<String> _selectedRoles;
  late bool _activo;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.usuario.usuario);
    _nameCtrl = TextEditingController(text: widget.usuario.nombre);
    _emailCtrl = TextEditingController(text: widget.usuario.email);
    _phoneCtrl = TextEditingController(
      text: widget.usuario.telefono,
    ); // Usando 'telefono' como en tu modelo Usuarios
    _selectedRoles = List.from(widget.usuario.roles);
    _activo = widget.usuario.activo;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  /// esto muestra un SnackBar con un mensaje de éxito o error
  /// dependiendo del resultado de la operación.

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: _white)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
  behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
        elevation: 6.h,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return Scaffold(
      backgroundColor: _lightGrey, // Fondo general de la pantalla
      appBar: AppBar(
        backgroundColor: _nightBlue, // AppBar azul noche
        elevation: 4.h,
        title: Text(
          'Editar Usuario',
          style: TextStyle(
            color: _white, // Título blanco
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _white), // Iconos blancos
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detalles del Usuario',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: _darkGreyText,
                ),
              ),
              SizedBox(height: 24.h),
              _buildTextField(
                controller: _usernameCtrl,
                label: 'Usuario',
                icon: Icons.person_outline,
                readOnly: true, // Campo de usuario NO EDITABLE
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                controller: _nameCtrl,
                label: 'Nombre Completo',
                icon: Icons.badge_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Ingrese un email válido o déjelo vacío.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Teléfono',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 30.h),
              Text(
                'Roles de Usuario',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _darkGreyText,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6.h,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: ListView.separated(
                  physics:
                      const NeverScrollableScrollPhysics(), // evita scroll interno
                  shrinkWrap: true,
                  itemCount: Roles.allRoles.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1.h, color: Colors.grey.shade300),
                  itemBuilder: (context, index) {
                    final role = Roles.allRoles[index];
                    final isSelected = _selectedRoles.contains(role);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedRoles.add(role);
                          } else {
                            _selectedRoles.remove(role);
                          }
                        });
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: _lightNightBlue,
                      title: Text(
                        role,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: _darkGreyText,
                        ),
                      ),
                      checkboxShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                    );
                  },
                ),
              ),

              SizedBox(height: 30.h),
              Container(
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8.h,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  title: Text(
                    'Estado Activo',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _darkGreyText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  activeColor: Colors.green.shade600,
                  inactiveThumbColor: Colors.red.shade600,
                  inactiveTrackColor: Colors.red.shade200,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                ),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _isSaving = true);

                          final updatedUser = widget.usuario.copyWith(
                            nombre: _nameCtrl.text.trim(),
                            email: _emailCtrl.text.trim(),
                            telefono: _phoneCtrl.text.trim(),
                            roles: _selectedRoles,
                            activo: _activo,
                          );

                          try {
                            await Future.delayed(const Duration(seconds: 2));
                            await context.read<AuthController>().updateUser(
                              widget.usuario.id!,
                              updatedUser.toJson(),
                            );
                            _showSnackBar('Usuario actualizado con éxito.');
                            Navigator.of(context).pop();
                          } catch (e) {
                            _showSnackBar(
                              'Error al actualizar: ${e.toString().split(': ').last}',
                              isError: true,
                            );
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _nightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 8.h,
                    shadowColor: _nightBlue.withOpacity(0.4),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSaving
                        ? Row(
                            key: const ValueKey('loading'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  color: _white,
                                  strokeWidth: 2.5.w,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Guardando...',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _white,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('idle'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_outlined,
                                size: 24.w,
                                color: _white,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Guardar Cambios',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _white,
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false, // Nuevo parámetro para solo lectura
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly, // Aplica la propiedad de solo lectura
      style: TextStyle(
        fontSize: 12.sp,
        color: readOnly
            ? Colors.grey.shade700
            : _darkGreyText, // Texto más claro si es solo lectura
        fontWeight: readOnly ? FontWeight.w500 : FontWeight.normal,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 16.sp),
        prefixIcon: Icon(icon, size: 22.w, color: _lightNightBlue),
        filled: true,
        fillColor: readOnly
            ? _readOnlyGrey
            : _lightGrey, // Fondo diferente para solo lectura
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
        ),
        focusedBorder:
            readOnly // Si es solo lectura, no hay borde de enfoque
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.w,
                ), // Mantiene el borde normal
              )
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: _lightNightBlue, width: 2.5.w),
              ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2.w),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red.shade800, width: 2.5.w),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      ),
    );
  }
}
