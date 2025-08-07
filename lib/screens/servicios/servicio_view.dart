import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart' as agencia_model;
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
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
              child: Text('Error cargando reservas: \\${reservasSnapshot.error}'),
            );
          }

          final reservas = reservasSnapshot.data ?? [];
          final reservasAgencia = reservas.where((r) => r.agenciaId == agenciaId).toList();

          // Agrupar reservas por turno, ignorando reservas con turno nulo
          final Map<TurnoType, List<ReservaConAgencia>> reservasPorTurno = {};
          for (var reserva in reservasAgencia) {
            if (reserva.turno != null) {
              reservasPorTurno.putIfAbsent(reserva.turno!, () => []).add(reserva);
            }
          }

          // Mostrar todos los turnos definidos en TurnoType, aunque no haya reservas para alguno
          final turnos = TurnoType.values;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65, // Card más largo
            ),
            itemCount: turnos.length,
            itemBuilder: (context, index) {
              final turno = turnos[index];
              final reservasTurno = reservasPorTurno[turno] ?? [];
              final today = DateTime.now();
              // Filtrar reservas de este turno para la fecha de hoy
              final reservasHoy = reservasTurno.where((r) =>
                r.fecha.year == today.year &&
                r.fecha.month == today.month &&
                r.fecha.day == today.day
              ).toList();
              final totalPaxHoy = reservasHoy.fold<int>(0, (sum, r) => sum + r.pax);
              const int maxCupos = 20;
              final cuposDisponibles = (maxCupos - totalPaxHoy).clamp(0, maxCupos);

              // Badge color y texto según cupos
              Color badgeColor;
              Color badgeTextColor;
              String badgeText;
              if (cuposDisponibles == 0) {
                badgeColor = Colors.red.shade600;
                badgeTextColor = Colors.white;
                badgeText = 'Sin cupos disponibles';
              } else if (cuposDisponibles <= 5) {
                badgeColor = Colors.orange.shade600;
                badgeTextColor = Colors.white;
                badgeText = '$cuposDisponibles cupos disponibles';
              } else if (cuposDisponibles <= 10) {
                badgeColor = Colors.amber.shade200;
                badgeTextColor = Colors.blue.shade900;
                badgeText = '$cuposDisponibles cupos disponibles';
              } else {
                badgeColor = Colors.blue.shade600;
                badgeTextColor = Colors.white;
                badgeText = '$cuposDisponibles cupos disponibles';
              }

              // Personalización visual premium por turno
              Color borderColor;
              IconData iconoTurno;
              Color iconColor = Colors.blue.shade700;
              switch (turno) {
                case TurnoType.manana:
                  borderColor = Colors.blue.shade300;
                  iconoTurno = Icons.wb_sunny;
                  break;
                case TurnoType.tarde:
                  borderColor = Colors.blue.shade500;
                  iconoTurno = Icons.wb_twilight;
                  break;
                case TurnoType.privado:
                  borderColor = Colors.blue.shade900;
                  iconoTurno = Icons.lock;
                  break;
              }

              return GestureDetector(
                onTap: () {
                  final agencia = agencia_model.AgenciaConReservas(
                    agencia: agencia_model.Agencia(
                      id: agenciaId,
                      nombre: 'City Tours Cartagena',
                      imagenUrl: null,
                      eliminada: false,
                    ),
                    totalReservas: 0, // Valor estático temporal
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReservasView(agencia: agencia, turno: turno),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              // Ícono del turno
                              Container(
                                decoration: BoxDecoration(
                                  color: borderColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  iconoTurno,
                                  size: 32,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Turno arriba
                              Text(
                                turno.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: borderColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Logo
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor.withOpacity(0.3), width: 2),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/logo.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Nombre empresa
                              Text(
                                'City Tours Climatizado',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Badge de cupos disponibles
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: badgeTextColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
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
  // Eliminada función _getTurnoLabel, se usa la extensión TurnoTypeLabel
}
