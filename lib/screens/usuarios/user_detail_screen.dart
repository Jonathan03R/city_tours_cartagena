import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/models/roles.dart';
import 'package:citytourscartagena/core/models/usuarios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

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
  late TextEditingController _phoneCtrl;
  late List<String> _selectedRoles;
  late bool _activo;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.usuario.usuario);
    _nameCtrl = TextEditingController(text: widget.usuario.nombre);
    _emailCtrl = TextEditingController(text: widget.usuario.email);
    _phoneCtrl = TextEditingController(text: widget.usuario.telefono);
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

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return Scaffold(
      appBar: AppBar(title: Text('Editar Usuario')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _usernameCtrl,
                decoration: InputDecoration(labelText: 'Usuario'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: 'Email'),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16.h),
              Text('Roles', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ...Roles.allRoles.map((r) => CheckboxListTile(
                    title: Text(r),
                    value: _selectedRoles.contains(r),
                    onChanged: (val) => setState(() {
                      if (val == true) {
                        _selectedRoles.add(r);
                      } else {
                        _selectedRoles.remove(r);
                      }
                    }),
                  )),
              SwitchListTile(
                title: Text('Activo'),
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final dataToUpdate = <String, dynamic>{
                      'usuario': _usernameCtrl.text.trim(),
                      'nombre': _nameCtrl.text.trim(),
                      'email': _emailCtrl.text.trim(),
                      'telefono': _phoneCtrl.text.trim(),
                      'rol': _selectedRoles,
                      'activo': _activo,
                    };
                    try {
                      await auth.updateUser(widget.usuario.id!, dataToUpdate);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Usuario actualizado')), 
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
