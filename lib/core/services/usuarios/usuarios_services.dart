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

    // Manejo robusto: res puede venir como PostgrestResponse, List, Map o incluso int.
    dynamic payload;
    try {
      // intenta leer .error/.data si existen (PostgrestResponse)
      final maybeError = (res as dynamic).error;
      if (maybeError != null) {
        throw Exception('Error en la respuesta de Supabase: ${maybeError.message ?? maybeError}');
      }
      payload = (res as dynamic).data ?? res;
    } catch (_) {
      // res no tiene .error/.data, usamos directamente
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
      throw Exception('Error: no se pudo extraer el ID del usuario (respuesta: $payload)');
    }

    debugPrint('Usuario creado con ID: $idUsuario');
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

  Future<Map<String, dynamic>?> getEntidad(String tipoUsuario, int usuarioCodigo) async {
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

  Future<Map<String, dynamic>?> obtenerPerfil(dynamic usuarioIdentificador) async {
    // usuarioIdentificador puede ser int (usuario_codigo) o String (auth UID guardado en usuario_password_encriptado)
    Map<String, dynamic>? usuario;

    if (usuarioIdentificador is String) {
      final res = await _client
          .from('usuarios')
          .select()
          .eq('usuario_password_encriptado', usuarioIdentificador)
          .eq('usuario_activo', true)
          .maybeSingle();
      if (res == null) return null;
      usuario = Map<String, dynamic>.from(res as Map);
    } else if (usuarioIdentificador is int) {
      usuario = await getUsuario(usuarioIdentificador);
      if (usuario == null) return null;
    } else {
      return null;
    }

    final personaCodigo = usuario['persona_codigo'] is int ? usuario['persona_codigo'] as int : int.tryParse('${usuario['persona_codigo']}');
    final rolCodigo = usuario['rol_codigo'] is int ? usuario['rol_codigo'] as int : int.tryParse('${usuario['rol_codigo']}');
    final tipoUsuario = usuario['tipo_usuario'] as String?;
    final usuarioCodigo = usuario['usuario_codigo'] is int ? usuario['usuario_codigo'] as int : int.tryParse('${usuario['usuario_codigo']}');

    final persona = personaCodigo != null ? await getPersona(personaCodigo) : null;
    final rol = rolCodigo != null ? await getRol(rolCodigo) : null;
    final entidad = (tipoUsuario != null && usuarioCodigo != null) ? await getEntidad(tipoUsuario, usuarioCodigo) : null;

    return {
      'usuario': usuario,
      'persona': persona,
      'rol': rol,
      'entidad': entidad,
    };
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
}