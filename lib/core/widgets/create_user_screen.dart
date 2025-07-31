import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/models/roles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// Colores de la paleta "Azul Noche y Blanco" definidos globalmente en este archivo
const Color _nightBlue = Color(0xFF1A237E); // Azul noche profundo
const Color _lightNightBlue = Color(0xFF3F51B5); // Azul más claro para acentos
const Color _white = Colors.white;
const Color _lightGrey = Color(0xFFF5F5F5); // Gris muy claro para fondos de campos
const Color _darkGreyText = Color(0xFF212121); // Gris oscuro para texto principal

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Campo de email opcional
  final TextEditingController _phoneController = TextEditingController();
  final List<String> _selectedRoles = [Roles.verReservas]; // Rol por defecto

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: _white)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.all(16.r),
        elevation: 6.h,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    return Scaffold(
      backgroundColor: _white, // Fondo principal blanco
      appBar: AppBar(
        backgroundColor: _nightBlue, // AppBar azul noche
        elevation: 4.h,
        title: Text(
          'Crear Nuevo Usuario',
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
                'Datos del Nuevo Usuario',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: _darkGreyText,
                ),
              ),
              SizedBox(height: 24.h),
              _buildTextField(
                controller: _usernameController,
                label: 'Usuario (para login y contraseña inicial)',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese un nombre de usuario.';
                  }
                  if (value.contains('@') || value.contains(' ')) {
                    return 'El usuario no debe contener "@" ni espacios.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Icons.badge_outlined,
                validator: (value) => value == null || value.isEmpty ? 'Ingrese el nombre completo.' : null,
              ),
              SizedBox(height: 20.h),
              _buildTextField(
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
              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono (Opcional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 30.h),
              Text(
                'Roles de Usuario',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: _darkGreyText,
                ),
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: Roles.allRoles.map((role) {
                  final isSelected = _selectedRoles.contains(role);
                  return ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRoles.add(role);
                        } else {
                          _selectedRoles.remove(role);
                        }
                      });
                    },
                    selectedColor: _lightNightBlue, // Azul claro para seleccionado
                    backgroundColor: _white, // Fondo blanco para no seleccionado
                    labelStyle: TextStyle(
                      color: isSelected ? _white : _darkGreyText, // Texto blanco si seleccionado, oscuro si no
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r), // Bordes más redondeados
                      side: BorderSide(
                        color: isSelected ? _lightNightBlue : Colors.grey.shade400, // Borde azul si seleccionado
                        width: 1.5.w,
                      ),
                    ),
                    elevation: isSelected ? 4.h : 1.h, // Sombra sutil
                    padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  );
                }).toList(),
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 56.h, // Altura del botón ligeramente mayor
                child: ElevatedButton.icon(
                  onPressed: authController.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedRoles.isEmpty) {
                        _showSnackBar('Seleccione al menos un rol para el usuario.', isError: true);
                        return;
                      }
                      try {
                        // Aquí se mantiene la llamada a tu AuthController
                        await authController.adminCreateUser(
                          username: _usernameController.text.trim(),
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
                          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                          roles: _selectedRoles,
                        );
                        _showSnackBar('Usuario creado con éxito.');
                        Navigator.of(context).pop(); // Volver a la pantalla anterior
                      } catch (e) {
                        String errorMessage = 'Error al crear usuario: ${e.toString().replaceFirst('Exception: ', '')}';
                        _showSnackBar(errorMessage, isError: true);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _nightBlue, // Botón azul noche
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r), // Bordes redondeados
                    ),
                    elevation: 8.h, // Mayor elevación para un look premium
                    shadowColor: _nightBlue.withOpacity(0.4), // Sombra con color del botón
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  icon: authController.isLoading
                      ? SizedBox(
                          width: 24.w,
                          height: 24.h,
                          child: const CircularProgressIndicator(
                            color: _white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(Icons.person_add_alt_1_outlined, size: 24.w, color: _white),
                  label: Text(
                    authController.isLoading ? 'Creando...' : 'Crear Usuario',
                    style: TextStyle(fontSize: 18.sp, color: _white, fontWeight: FontWeight.w700),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 17.sp, color: _darkGreyText),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 16.sp),
        prefixIcon: Icon(icon, size: 22.w, color: _lightNightBlue), // Icono azul claro
        filled: true,
        fillColor: _lightGrey, // Fondo del campo muy claro
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r), // Bordes más redondeados
          borderSide: BorderSide.none, // Sin borde visible por defecto
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w), // Borde sutil
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _lightNightBlue, width: 2.5.w), // Borde azul más grueso al enfocar
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2.w), // Borde rojo para errores
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red.shade800, width: 2.5.w),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w), // Mayor padding
      ),
    );
  }
}
