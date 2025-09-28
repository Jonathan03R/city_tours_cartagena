import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:flutter/material.dart';

class ReservaDetalles extends StatefulWidget {
  final int codigoAgencia;

  const ReservaDetalles({super.key, required this.codigoAgencia});

  @override
  State<ReservaDetalles> createState() => _ReservaDetallesState();
}

class _ReservaDetallesState extends State<ReservaDetalles> {
  late Future<List<ReservaResumen>> _reservasFuture;

  @override
  void initState() {
    super.initState();
    // Usa un operador de prueba, por ejemplo 1. Cambia según tu lógica real.
    _reservasFuture = ReservasSupabaseController().obtenerReservaAgencia(
      idAgencia: widget.codigoAgencia,
      idOperador: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reservas Agencia ${widget.codigoAgencia}')),
      body: FutureBuilder<List<ReservaResumen>>(
        future: _reservasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final reservas = snapshot.data ?? [];
          if (reservas.isEmpty) {
            return const Center(child: Text('No hay reservas'));
          }
          return ListView.builder(
            itemCount: reservas.length,
            itemBuilder: (context, index) {
              final r = reservas[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código: ${r.reservaCodigo}'),
                      Text('Tipo servicio: ${r.tipoServicioDescripcion}'),
                      Text('Punto encuentro: ${r.reservaPuntoEncuentro}'),
                      Text('Representante: ${r.reservaRepresentante}'),
                      Text('Fecha: ${r.reservaFecha}'),
                      Text('Pasajeros: ${r.reservaPasajeros}'),
                      Text('Agencia: ${r.agenciaNombre}'),
                      Text('Ticket: ${r.numeroTickete ?? "S/N"}'),
                      Text('Habitación: ${r.numeroHabitacion ?? "S/N"}'),
                      Text('Estado: ${r.estadoNombre}'),
                      Text('Color: ${r.colorPrefijo}'),
                      Text('Saldo: ${r.saldo}'),
                      Text('Deuda: ${r.deuda}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}