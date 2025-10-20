import 'package:supabase_flutter/supabase_flutter.dart';

class PagosService {
  final SupabaseClient _client;

  PagosService(this._client);

  /// Llama a la función RPC 'pagar_reserva' para procesar un pago.
  /// Retorna el monto pagado o excedente.
  Future<double> pagarReserva({
    required int reservaCodigo,
    int tipoPagoCodigo = 1,
    int? pagadoPor,
  }) async {
    try {
      final params = {
        'p_reserva_codigo': reservaCodigo,
        'p_tipo_pago_codigo': tipoPagoCodigo,
        if (pagadoPor != null) 'p_pagado_por': pagadoPor,
      };

      final response = await _client.rpc('pagar_reserva', params: params);

      // La función retorna NUMERIC, que en Dart es double
      return (response as num).toDouble();
    } on PostgrestException catch (e) {
      throw Exception('Error al procesar pago: ${e.message}');
    } catch (e, s) {
      throw Exception('Error inesperado al pagar reserva: ${e.toString()}');
    }
  }

  /// Llama a la función RPC 'revertir_pago' para revertir el último pago.
  /// Retorna el monto revertido.
  Future<double> revertirPago({
    required int reservaCodigo,
  }) async {
    try {
      final params = {
        'p_reserva_codigo': reservaCodigo,
      };

      final response = await _client.rpc('revertir_pago', params: params);

      // La función retorna NUMERIC, que en Dart es double
      return (response as num).toDouble();
    } on PostgrestException catch (e) {
      throw Exception('Error al revertir pago: ${e.message}');
    } catch (e, s) {
      throw Exception('Error inesperado al revertir pago: ${e.toString()}');
    }
  }
}