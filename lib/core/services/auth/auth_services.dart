import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/auth/usuarios.dart';

class AuthSupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Usuario?> register({
    required String email,
    required String password,
    String? nombre,
  }) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final user = res.user;
    if (user == null) return null;
    final nuevoUsuario = Usuario(
      id: user.id,
      email: email,
      nombre: nombre,
      roles: ['user'], 
      activo: true,
    );
    return nuevoUsuario;
  }

  Future<void> deleteUser(String userId) async {
    await _client.auth.admin.deleteUser(userId);
  }

  Future<String?> getLoginToken() async {
    final session = _client.auth.currentSession;
    return session?.accessToken;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    return res.session?.accessToken;
  }

  String? getUidFromToken(String token) {
    final decodedToken = JwtDecoder.decode(token);
    return decodedToken['sub'];
  }
}