import 'package:citytourscartagena/screens/usuarios/my_count.dart';
import 'package:citytourscartagena/screens/usuarios/usuarios_all.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Importar ScreenUtil

class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // Fondo muy claro, casi blanco
        appBar: AppBar(
          backgroundColor: Colors.white, // AppBar blanco
          elevation: 2.h, // Sombra sutil para un efecto flotante
          title: Text(
            'Gestión de Usuarios', // Título más descriptivo
            style: TextStyle(
              color: Colors.grey.shade800, // Texto oscuro pero no negro puro
              fontSize: 20.sp, // Tamaño de fuente responsivo
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.blue.shade600, // Azul vibrante para el indicador
            indicatorWeight: 3.h,
            labelColor: Colors.blue.shade600, // Texto de pestaña seleccionada en azul
            unselectedLabelColor: Colors.grey.shade500, // Texto de pestaña no seleccionada en gris
            labelStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'Todos los Usuarios'), // Texto más claro
              Tab(text: 'Mi Perfil'), // Texto más claro
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TodosUsuariosTab(),
            MiCuentaTab(),
          ],
        ),
      ),
    );
  }
}
