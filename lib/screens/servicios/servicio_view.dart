import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart' as agencia_model;
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServiciosView extends StatefulWidget {
  final String searchTerm; // Recibir el término de búsqueda desde MainScreen

  const ServiciosView({super.key, this.searchTerm = ''});

  @override
  State<ServiciosView> createState() => _ServiciosViewState();
}

class _ServiciosViewState extends State<ServiciosView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }



  void _navigateToAgenciaReservas(agencia_model.AgenciaConReservas agencia) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservasView(agencia: agencia),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final reservasController = context.watch<ReservasController>();
    final agenciaId = authController.appUser?.agenciaId;

    if (agenciaId == null) {
      return const Center(
        child: Text(
          'No se encontró información de la agencia.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<ReservaConAgencia>>(
        stream: reservasController.getAllReservasConAgenciaStream(),
        builder: (context, reservasSnapshot) {
          if (reservasSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (reservasSnapshot.hasError) {
            return Center(
              child: Text('Error cargando reservas: ${reservasSnapshot.error}'),
            );
          }

          final reservas = reservasSnapshot.data ?? [];
          final reservasAgencia = reservas.where((r) => r.agenciaId == agenciaId).toList();

          final totalReservas = reservasAgencia.length;
          final totalDeuda = reservasAgencia.fold<double>(
            0.0,
            (sum, reserva) => sum + (reserva.deuda),
          );

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.83,
            ),
            itemCount: 1,
            itemBuilder: (context, index) {
              final agencia = agencia_model.AgenciaConReservas(
                agencia: agencia_model.Agencia(
                  id: agenciaId,
                  nombre: 'City Tours Cartagena',
                  imagenUrl: null,
                  eliminada: false,
                ),
                totalReservas: totalReservas,
              );

              return GestureDetector(
                onTap: () => _navigateToAgenciaReservas(agencia),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'City Tours Cartagena',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalReservas reservas',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: totalDeuda > 0
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Deuda: \$${totalDeuda.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: totalDeuda > 0
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
