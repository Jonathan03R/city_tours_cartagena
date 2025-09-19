import 'package:citytourscartagena/core/models/auth/usuarios.dart';
import 'package:citytourscartagena/core/services/auth/auth_services.dart';
import 'package:citytourscartagena/core/services/usuarios/usuarios_services.dart';
import 'package:flutter/material.dart';

class AuthSupabaseController extends ChangeNotifier {
  final AuthSupabaseService _authService = AuthSupabaseService();
  final UsuariosService _usuariosService = UsuariosService();

  Usuario? usuario;
  bool isLoading = false;
  String? error;

  Future<void> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String alias,
    required int rol,
    required String tipoUsuario,
    required int codigoRelacion,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    Usuario? authUser;

    try {
      debugPrint('Intentando registrar usuario en Supabase Auth...');
      authUser = await _authService.register(
        email: email,
        password: password,
        nombre: nombre,
      );

      if (authUser == null) {
        throw Exception('No se pudo crear el usuario en Supabase Auth');
      }

      debugPrint('Usuario creado en Supabase Auth: ${authUser.toMap()}');

      try {
        debugPrint('Intentando registrar usuario en la base de datos...');
        await _usuariosService.crearUsuario(
          nombre: nombre,
          apellido: apellido,
          email: email,
          alias: alias,
          passwordEncriptado: authUser.id,
          rol: rol,
          tipoUsuario: tipoUsuario,
          codigoRelacion: codigoRelacion,
        );

        usuario = authUser;
        debugPrint('Usuario registrado exitosamente en la base de datos.');
      } catch (dbError) {
        debugPrint('Error al registrar usuario en la base de datos: $dbError');

        // Rollback seguro
        try {
          await _authService.deleteUser(authUser.id);
          debugPrint('Rollback exitoso: usuario eliminado de Auth');
        } catch (rollbackError) {
          debugPrint(
            'Error al eliminar usuario en Auth durante rollback: $rollbackError',
          );
        }

        throw Exception('Error al crear usuario en la base de datos: $dbError');
      }
    } catch (e) {
      debugPrint('Error en el registro: $e');
      error = e.toString();
      usuario = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final token = await _authService.login(email: email, password: password);
      if (token == null) {
        throw Exception('Credenciales inválidas. No se pudo iniciar sesión.');
      }

      final uid = _authService.getUidFromToken(token);
      if (uid == null) {
        throw Exception('No se pudo extraer el UID del token.');
      }

      final perfil = await _usuariosService.obtenerPerfil(uid);
      if (perfil == null) {
        throw Exception(
          'No estás autorizado. Usuario no encontrado o inactivo.',
        );
      }

      try {
        final usuarioMap = perfil['usuario'] as Map<String, dynamic>?;
        final dynamic rawId = usuarioMap != null
            ? usuarioMap['usuario_codigo']
            : null;
        final int? usuarioCodigo = rawId is int
            ? rawId
            : int.tryParse('$rawId');
        if (usuarioCodigo != null) {
          await _usuariosService.actualizarUltimoIngreso(usuarioCodigo);
        } else {
          debugPrint(
            'No se pudo obtener usuario_codigo para actualizar ultimo ingreso: $rawId',
          );
        }
      } catch (e) {
        debugPrint('Error al actualizar ultimo ingreso: $e');
      }
      return perfil;
    } catch (e) {
      debugPrint('Error en el inicio de sesión: $e');
      error = e.toString();
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
