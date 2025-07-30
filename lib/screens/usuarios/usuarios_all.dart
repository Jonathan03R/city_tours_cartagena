import 'package:citytourscartagena/core/models/usuarios.dart';
import 'package:citytourscartagena/core/widgets/create_user_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/controller/auth_controller.dart'; // Importar AuthController
import 'user_detail_screen.dart'; // <-- Add this import

class TodosUsuariosTab extends StatelessWidget {
  const TodosUsuariosTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>(); // Acceder al AuthController
    // Obtener el ID del usuario actualmente logeado
    final currentUserId = authController.appUser?.id; // <-- Obtener el ID del usuario logeado aquí

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade600,
                strokeWidth: 3.w,
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60.w, color: Colors.red.shade400),
                  SizedBox(height: 16.h),
                  Text(
                    'Error al cargar usuarios: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.sp, color: Colors.red.shade400),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60.w, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  Text(
                    'No hay usuarios registrados.',
                    style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          final docs = snapshot.data!.docs;
          // Filtrar la lista de usuarios para excluir al usuario actualmente logeado
          final usuarios = docs
              .map((e) => Usuarios.fromMap(e.data() as Map<String, dynamic>))
              .where((usuario) => usuario.id != currentUserId) // <-- ¡Esta es la línea clave!
              .toList();

          if (usuarios.isEmpty) { // Si después de filtrar no quedan usuarios
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60.w, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  Text(
                    'No hay otros usuarios registrados para mostrar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            itemCount: usuarios.length,
            itemBuilder: (context, index) {
              final usuario = usuarios[index];
              return UserCard(
                usuario: usuario,
                authController: authController, // Pasar el controlador
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_user_fab',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateUserScreen()),
          );
        },
        label: Text(
          'Crear Usuario',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        icon: Icon(Icons.person_add_alt_1_outlined, size: 24.w),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 4.h,
      ),
    );
  }
}

// La clase UserCard no necesita cambios, ya que el filtrado se hace antes de que se le pasen los datos.
// Sin embargo, para que el CodeProject sea completo, la incluyo.
class UserCard extends StatelessWidget {
  final Usuarios usuario;
  final AuthController authController;
  const UserCard({super.key, required this.usuario, required this.authController});

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
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
    // Aunque el filtrado ya se hizo, esta lógica sigue siendo útil si la tarjeta se usa en otro contexto
    final currentUserId = authController.appUser?.id;
    final isCurrentUser = usuario.id == currentUserId;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserDetailScreen(usuario: usuario),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 12.h),
        elevation: 2.h,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28.r,
                backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.person_outline, size: 28.w, color: Colors.blue.shade600),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.usuario ?? 'N/A',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      usuario.email ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: usuario.roles.map((rol) => Chip(
                        label: Text(
                          rol,
                          style: TextStyle(fontSize: 12.sp, color: Colors.white),
                        ),
                        backgroundColor: Colors.blue.shade400,
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              // Indicador de estado activo/inactivo
              Column(
                children: [
                  Icon(
                    usuario.activo ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: usuario.activo ? Colors.green.shade400 : Colors.red.shade400,
                    size: 24.w,
                  ),
                  Text(
                    usuario.activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: usuario.activo ? Colors.green.shade400 : Colors.red.shade400,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 10.w),
              // Botón de opciones (activar/desactivar)
              // Solo muestra el botón si NO es el usuario actualmente logeado
              if (!isCurrentUser)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 24.w),
                  onSelected: (value) async {
                    if (value == 'toggle_status') {
                      try {
                        await authController.toggleUserActiveStatus(usuario.id!, !usuario.activo);
                        _showSnackBar(
                          context,
                          'Usuario ${usuario.usuario} ${usuario.activo ? "desactivado" : "activado"} con éxito.',
                        );
                      } catch (e) {
                        _showSnackBar(context, 'Error al cambiar estado: ${e.toString()}', isError: true);
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(
                              usuario.activo ? Icons.block : Icons.check_circle_outline,
                              color: usuario.activo ? Colors.red.shade400 : Colors.green.shade400,
                              size: 20.w,
                            ),
                            SizedBox(width: 8.w),
                            Text(usuario.activo ? 'Desactivar Usuario' : 'Activar Usuario'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
