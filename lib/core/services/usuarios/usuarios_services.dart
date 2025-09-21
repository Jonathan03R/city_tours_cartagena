import 'package:citytourscartagena/core/models/perfil/perfil_usuario.dart';
import 'package:citytourscartagena/core/models/perfil/persona.dart';
import 'package:citytourscartagena/core/models/perfil/usuario.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuariosService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> crearUsuario({
    required String nombre,
    required String apellido,
    required String email,
    required String alias,
    required String passwordEncriptado,
    required int rol,
    required String tipoUsuario,
    required int codigoRelacion,
  }) async {
    final params = {
      'p_nombre': nombre,
      'p_apellido': apellido,
      'p_email': email,
      'p_alias': alias,
      'p_password': passwordEncriptado,
      'p_rol': rol,
      'p_tipo_usuario': tipoUsuario,
      'p_codigo_relacion': codigoRelacion,
    };

    final res = await _client.rpc('fn_crear_usuario', params: params);
    dynamic payload;
    try {
      final maybeError = (res as dynamic).error;
      if (maybeError != null) {
        throw Exception(
          'Error en la respuesta de Supabase: ${maybeError.message ?? maybeError}',
        );
      }
      payload = (res as dynamic).data ?? res;
    } catch (_) {
      payload = res;
    }

    // Normalizar y extraer ID
    int? idUsuario;
    if (payload == null) {
      throw Exception('Error: respuesta vacía de fn_crear_usuario');
    } else if (payload is int) {
      idUsuario = payload;
    } else if (payload is List && payload.isNotEmpty) {
      final first = payload[0];
      if (first is Map && first.containsKey('fn_crear_usuario')) {
        idUsuario = first['fn_crear_usuario'] as int?;
      } else if (first is int) {
        idUsuario = first;
      }
    } else if (payload is Map) {
      if (payload.containsKey('fn_crear_usuario')) {
        idUsuario = payload['fn_crear_usuario'] as int?;
      } else if (payload.values.isNotEmpty && payload.values.first is int) {
        idUsuario = payload.values.first as int?;
      }
    }

    if (idUsuario == null) {
      throw Exception(
        'Error: no se pudo extraer el ID del usuario (respuesta: $payload)',
      );
    }
  }

  Future<Map<String, dynamic>?> getUsuario(int usuarioCodigo) async {
    final res = await _client
        .from('usuarios')
        .select()
        .eq('usuario_codigo', usuarioCodigo)
        .eq('usuario_activo', true)
        .maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>?> getPersona(int personaCodigo) async {
    final res = await _client
        .from('personas')
        .select()
        .eq('persona_codigo', personaCodigo)
        .maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>?> getRol(int rolCodigo) async {
    final res = await _client
        .from('roles')
        .select()
        .eq('rol_codigo', rolCodigo)
        .maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>?> getEntidad(
    String tipoUsuario,
    int usuarioCodigo,
  ) async {
    if (tipoUsuario == 'operador') {
      final operadorRel = await _client
          .from('usuarios_operadores')
          .select()
          .eq('usuario_codigo', usuarioCodigo)
          .maybeSingle();

      if (operadorRel == null) return null;

      final operador = await _client
          .from('operadores')
          .select()
          .eq('operador_codigo', (operadorRel as Map)['operador_codigo'])
          .maybeSingle();
      if (operador == null) return null;
      return Map<String, dynamic>.from(operador as Map);
    } else if (tipoUsuario == 'agencia') {
      final agenciaRel = await _client
          .from('usuarios_agencias')
          .select()
          .eq('usuario_codigo', usuarioCodigo)
          .maybeSingle();

      if (agenciaRel == null) return null;

      final agencia = await _client
          .from('agencias')
          .select()
          .eq('agencia_codigo', (agenciaRel as Map)['agencia_codigo'])
          .maybeSingle();
      if (agencia == null) return null;
      return Map<String, dynamic>.from(agencia as Map);
    }
    return null;
  }

  Future<Map<String, dynamic>?> obtenerPerfil({
    required String usuarioIdentificador,
  }) async {
    // usuarioIdentificador es el String (auth UID guardado en usuario_password_encriptado)
    Map<String, dynamic>? usuario;

    final res = await _client
        .from('usuarios')
        .select()
        .eq('usuario_password_encriptado', usuarioIdentificador)
        .eq('usuario_activo', true)
        .maybeSingle();

    if (res == null) return null;
    usuario = Map<String, dynamic>.from(res as Map);
    final personaCodigo = usuario['persona_codigo'];
    final rolCodigo = usuario['rol_codigo'];
    final tipoUsuario = usuario['tipo_usuario'];
    final usuarioCodigo = usuario['usuario_codigo'];

    final persona = await getPersona(personaCodigo!);
    final rol = await getRol(rolCodigo!);
    final entidad = await getEntidad(tipoUsuario, usuarioCodigo!);
    final perfilCompleto = {
      'usuario': usuario,
      'persona': persona,
      'rol': rol,
      'entidad': entidad,
    };

    debugPrint('todo el objeto del perfil es: ${perfilCompleto.toString()}');

    return perfilCompleto;
  }

  Future<bool> actualizarUltimoIngreso(int usuarioCodigo) async {
    try {
      final now = DateTime.now();
      final ultimoIngreso = now.toIso8601String();

      final payload = <String, dynamic>{
        'usuario_ultimo_ingreso': ultimoIngreso,
      };

      final res = await _client
          .from('usuarios')
          .update(payload)
          .eq('usuario_codigo', usuarioCodigo)
          .select()
          .maybeSingle();

      return res != null;
    } catch (e) {
      debugPrint('Error actualizando usuario_ultimo_ingreso: $e');
      return false;
    }
  }

  Future<Perfil?> obtenerPerfilModelo(String usuarioIdentificador) async {
    final perfilRaw = await obtenerPerfil(
      usuarioIdentificador: usuarioIdentificador,
    );
    if (perfilRaw == null) return null;

    final usuarioMap = perfilRaw['usuario'] as Map<String, dynamic>;
    final personaMap = perfilRaw['persona'] as Map<String, dynamic>?;
    final entidadMap = perfilRaw['entidad'] as Map<String, dynamic>?;

    Perfil(
      usuario: Usuario.fromMap(usuarioMap),
      persona: personaMap != null ? Persona.fromMap(personaMap) : null,
      entidad: entidadMap,
      rol: perfilRaw['rol'] as Map<String, dynamic>?,
    );
    return Perfil.fromMap(perfilRaw);
  }
}
