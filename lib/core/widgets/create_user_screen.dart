import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/models/roles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

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
  List<String> _selectedRoles = [Roles.colaborador]; // Rol por defecto

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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2.h,
        title: Text(
          'Crear Nuevo Usuario',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.grey.shade700),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datos del Nuevo Usuario',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 20.h),
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
              SizedBox(height: 20.h),
              Text(
                'Roles',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: Roles.allRoles.map((role) {
                  final isSelected = _selectedRoles.contains(role);
                  return FilterChip(
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
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade600,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
                      fontSize: 14.sp,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      side: BorderSide(
                        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade300,
                        width: 1.w,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  onPressed: authController.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      if (_selectedRoles.isEmpty) {
                        _showSnackBar('Seleccione al menos un rol para el usuario.', isError: true);
                        return;
                      }
                      try {
                        await authController.adminCreateUser(
                          username: _usernameController.text.trim(),
                          name: _nameController.text.trim(),
                          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(), // Pasa null si está vacío
                          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(), // Pasa null si está vacío
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
                    backgroundColor: Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 3.h,
                  ),
                  icon: authController.isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Icon(Icons.person_add_alt_1_outlined, size: 20.w, color: Colors.white),
                  label: Text(
                    authController.isLoading ? 'Creando...' : 'Crear Usuario',
                    style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.w600),
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
}
