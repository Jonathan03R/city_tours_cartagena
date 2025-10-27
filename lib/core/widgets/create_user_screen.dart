import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/models/roles.dart';
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

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<String> _selectedRoles = [Roles.verReservas];
  String _accountType = 'empresa'; // 'empresa' o 'agencia'

  String? _selectedAgenciaId; // ← para guardar la agencia elegida
  bool _agencyError = false; // ← para validar selección

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
    // Asegúrate de proveer AgenciasController en tu MultiProvider

    return Scaffold(
      backgroundColor: _white,
      appBar: AppBar(
        backgroundColor: _nightBlue,
        elevation: 4.h,
        title: Text(
          'Crear Nuevo Usuario',
          style: TextStyle(
            color: _white,
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _white),
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
                  if (value.length < 6) {
                    return 'El usuario debe tener al menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Icons.badge_outlined,
                validator: (value) => value == null || value.isEmpty
                    ? 'Ingrese el nombre completo.'
                    : null,
              ),
              SizedBox(height: 20.h),
              _buildTextField(
                controller: _emailController,
                label: 'Email (Opcional)',
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
                controller: _phoneController,
                label: 'Teléfono (Opcional)',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 30.h),
              // Selector de tipo de cuenta
              Text(
                'Tipo de Cuenta',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: _darkGreyText,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Empresa'),
                      value: 'empresa',
                      groupValue: _accountType,
                      onChanged: (value) {
                        setState(() {
                          _accountType = value!;
                          _selectedRoles.clear();
                          _selectedRoles.add(Roles.verReservas);
                          _selectedAgenciaId = null;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Agencia'),
                      value: 'agencia',
                      groupValue: _accountType,
                      onChanged: (value) {
                        setState(() {
                          _accountType = value!;
                          _selectedRoles.clear();
                          _selectedRoles.add(Roles.agencia);
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              if (_accountType == 'empresa') ...[
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
                  children: Roles.allRoles
                      .where((role) => role != Roles.agencia)
                      .map((role) {
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
                          selectedColor: _lightNightBlue,
                          backgroundColor: _white,
                          labelStyle: TextStyle(
                            color: isSelected ? _white : _darkGreyText,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                            side: BorderSide(
                              color: isSelected
                                  ? _lightNightBlue
                                  : Colors.grey.shade400,
                              width: 1.5.w,
                            ),
                          ),
                          elevation: isSelected ? 4.h : 1.h,
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 10.h,
                          ),
                        );
                      })
                      .toList(),
                ),
              ],

              // Mostrar selector de agencia solo si es tipo agencia
              if (_accountType == 'agencia') ...[
                SizedBox(height: 16.h),
                Text(
                  'Agencia *',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                // AgenciaSelector(
                //   selectedAgenciaId: _selectedAgenciaId,
                //   onAgenciaSelected: (id) {
                //     setState(() {
                //       _selectedAgenciaId = id;
                //       _agencyError = false;
                //     });
                //   },
                // ),
                if (_agencyError)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 4.w),
                    child: Text(
                      'Debes seleccionar una agencia',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                SizedBox(height: 20.h),
              ],

              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton.icon(
                  onPressed: authController.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            // validar agencia si aplica
                            if (_formKey.currentState!.validate()) {
                              if (_selectedRoles.contains(Roles.agencia) &&
                                  _selectedAgenciaId == null) {
                                setState(() => _agencyError = true);
                                return;
                              }
                              print(
                                'Agencia seleccionada: $_selectedAgenciaId',
                              ); // <-- Depuración
                              // ... resto del código ...
                            } else {
                              _showSnackBar(
                                'Se necesitan mínimo 6 caracteres para crear al usuario.',
                                isError: true,
                              );
                            }
                            if (_selectedRoles.isEmpty) {
                              _showSnackBar(
                                'Seleccione al menos un rol para el usuario.',
                                isError: true,
                              );
                              return;
                            }
                            try {
                              // Aquí se mantiene la llamada a tu AuthController
                              await authController.adminCreateUser(
                                username: _usernameController.text.trim(),
                                name: _nameController.text.trim(),
                                email: _emailController.text.trim().isEmpty
                                    ? null
                                    : _emailController.text.trim(),
                                phone: _phoneController.text.trim().isEmpty
                                    ? null
                                    : _phoneController.text.trim(),
                                roles: _selectedRoles,
                                agenciaId: _selectedAgenciaId,
                              );
                              _showSnackBar('Usuario creado con éxito.');
                              Navigator.of(context).pop();
                            } catch (e) {
                              final msg = e.toString().replaceFirst(
                                'Exception: ',
                                '',
                              );
                              _showSnackBar('Error: $msg', isError: true);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _nightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 8.h,
                    shadowColor: _nightBlue.withOpacity(0.4),
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
                      : Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 24.w,
                          color: _white,
                        ),
                  label: Text(
                    authController.isLoading ? 'Creando...' : 'Crear Usuario',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: _white,
                      fontWeight: FontWeight.w700,
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 17.sp, color: _darkGreyText),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 16.sp),
        prefixIcon: Icon(icon, size: 22.w, color: _lightNightBlue),
        filled: true,
        fillColor: _lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.w),
        ),
        focusedBorder: OutlineInputBorder(
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
