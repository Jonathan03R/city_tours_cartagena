import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/screens/usuarios/my_count.dart';
import 'package:citytourscartagena/screens/usuarios/usuarios_all.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart'; // Importar ScreenUtil

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authRole = context.read<AuthController>();
    final showAll = authRole.hasPermission(Permission.view_usuarios);
    return DefaultTabController(
      length: showAll ? 2 : 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            TabBar(
              indicatorColor: Colors.blue.shade600,
              indicatorWeight: 3.h,
              labelColor: Colors.blue.shade600,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                if (showAll) Tab(text: 'Todos los Usuarios'),
                Tab(text: 'Mi Perfil'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  if (showAll) TodosUsuariosTab(),
                  MiCuentaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

