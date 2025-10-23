import 'package:citytourscartagena/core/models/reservas/reserva_contacto.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservasContactosService {
  final SupabaseClient _client;

  ReservasContactosService(this._client);

  Future<void> insertarContactosReserva({
    required int reservaId,
    required List<ReservaContacto> contactos,
  }) async {
    for (final contacto in contactos) {
      try {
        await _client.rpc(
          'insertar_reserva_contacto',
          params: {
            'p_reserva_id': reservaId,
            'p_tipo_contacto_codigo': contacto.tipoContactoCodigo,
            'p_contacto': contacto.contacto,
          },
        );
      } on PostgrestException catch (e) {
        throw Exception('Error al insertar contacto: ${e.message}');
      } catch (e, s) {
        debugPrint('insertarContactosReserva error: $e\n$s');
        throw Exception('No se pudo insertar contacto: ${e.toString()}');
      }
    }
  }
}
