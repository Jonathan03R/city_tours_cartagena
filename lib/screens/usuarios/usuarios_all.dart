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
    final authController = context
        .watch<AuthController>(); // Acceder al AuthController
    // Obtener el ID del usuario actualmente logeado
    final currentUserId = authController
        .appUser
        ?.id; // <-- Obtener el ID del usuario logeado aquí

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
                  Icon(
                    Icons.error_outline,
                    size: 60.w,
                    color: Colors.red.shade400,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Error al cargar usuarios: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.red.shade400,
                    ),
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
                  Icon(
                    Icons.people_outline,
                    size: 60.w,
                    color: Colors.grey[400],
                  ),
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
              .where(
                (usuario) => usuario.id != currentUserId,
              ) // <-- ¡Esta es la línea clave!
              .toList();

          if (usuarios.isEmpty) {
            // Si después de filtrar no quedan usuarios
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 60.w,
                    color: Colors.grey[400],
                  ),
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

  const UserCard({
    super.key,
    required this.usuario,
    required this.authController,
  });

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = usuario.id == authController.appUser?.id;

    return Card(
      elevation: 1.5,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserDetailScreen(usuario: usuario),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario.usuario ?? 'Usuario',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      usuario.email ?? 'Email',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: usuario.roles
                          .map((rol) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Text(
                                  rol,
                                  style: TextStyle(
                                    fontSize: 9.sp,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(
                    usuario.activo
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: usuario.activo
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                    size: 20.w,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    usuario.activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: usuario.activo
                          ? Colors.green.shade400
                          : Colors.red.shade400,
                    ),
                  ),
                ],
              ),
              if (!isCurrentUser) ...[
                SizedBox(width: 10.w),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, size: 20.w),
                  onSelected: (value) async {
                    if (value == 'toggle_status') {
                      try {
                        await authController.toggleUserActiveStatus(
                          usuario.id!,
                          !usuario.activo,
                        );
                        if (!context.mounted) return;
                        _showSnackBar(
                          context,
                          'Estado actualizado con éxito.',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        _showSnackBar(context, 'Error: $e', isError: true);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_status',
                      child: Row(
                        children: [
                          Icon(
                            usuario.activo
                                ? Icons.block
                                : Icons.check_circle_outline,
                            color: usuario.activo
                                ? Colors.red.shade400
                                : Colors.green.shade400,
                            size: 18.w,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            usuario.activo
                                ? 'Desactivar'
                                : 'Activar',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
