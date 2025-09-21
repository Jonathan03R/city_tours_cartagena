import 'dart:async';

import 'package:citytourscartagena/core/models/perfil/perfil_usuario.dart';
import 'package:citytourscartagena/core/models/perfil/usuario.dart';
import 'package:citytourscartagena/core/services/auth/auth_services.dart';
import 'package:citytourscartagena/core/services/usuarios/usuarios_services.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSupabaseController extends ChangeNotifier {
  final AuthSupabaseService _authService = AuthSupabaseService();
  final UsuariosService _usuariosService = UsuariosService();

  Usuario? usuario;
  Perfil? perfilUsuario;
  bool isLoading = false;
  String? error;

  RealtimeChannel? _userChannel;
  StreamSubscription<AuthState>? _authSub;

  bool get isAuthenticated => usuario != null;

  AuthSupabaseController() {
    _listenAuthChanges();
  }

  void _listenAuthChanges() {
    final client = Supabase.instance.client;
    _authSub = client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        usuario = null;
        _disposeUserChannel();
        notifyListeners();
      } else {
        final uid = session.user.id;
        _listenUserChanges(uid);
      }
    });
  }

  void _listenUserChanges(String uid) {
    final client = Supabase.instance.client;
    _disposeUserChannel();

    _userChannel = client
        .channel('user-changes-$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'usuarios',
          // USAR named args aquí:
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: uid,
          ),
          callback: (payload) {
            final newData = payload.newRecord;
            // si fila borrada o activo == false -> cerrar sesión
            if (newData['activo'] == false) {
              client.auth.signOut();
            } else {
              // opcional: actualizar modelo local
              usuario = Usuario.fromMap(newData);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  void _disposeUserChannel() {
    _userChannel?.unsubscribe();
    _userChannel = null;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _disposeUserChannel();
    super.dispose();
  }

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

    try {
      final uid = await _authService.register(
        email: email,
        password: password,
      );
      if (uid == null) {
        throw Exception('No se pudo crear el usuario');
      }
      try {
        debugPrint('Intentando registrar usuario en la base de datos...');
        await _usuariosService.crearUsuario(
          nombre: nombre,
          apellido: apellido,
          email: email,
          alias: alias,
          passwordEncriptado: uid,
          rol: rol,
          tipoUsuario: tipoUsuario,
          codigoRelacion: codigoRelacion,
        );
        
      } catch (dbError) {
        try {
          await _authService.deleteUser(uid);
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

  Future<Perfil?> login({
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

      final perfil = await _usuariosService.obtenerPerfilModelo(uid);
      if (perfil == null) {
        throw Exception(
          'No estás autorizado. Usuario no encontrado o inactivo.',
        );
      }
      perfilUsuario = perfil;
      usuario = perfil.usuario;
      notifyListeners();
      final usuarioCodigo = perfil.usuario.codigo;
      await _usuariosService.actualizarUltimoIngreso(usuarioCodigo);
    
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

  Future<void> logout() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _authService.logout();
      usuario = null;
      _disposeUserChannel();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
