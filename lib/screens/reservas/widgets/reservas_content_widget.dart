import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/core/widgets/reserva_card_item.dart';
import 'package:citytourscartagena/core/widgets/reserva_details.dart';
import 'package:citytourscartagena/core/widgets/reservas_table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReservasContentWidget extends StatelessWidget {
  final bool isTableView;
  final ReservasController reservasController;
  final String? agenciaId;
  final String? reservaIdNotificada;

  const ReservasContentWidget({
    super.key,
    required this.isTableView,
    required this.reservasController,
    this.agenciaId,
    this.reservaIdNotificada,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterTitle(isWide),
              StreamBuilder<List<ReservaConAgencia>>(
                stream: reservasController.filteredReservasStream,
                builder: (context, snapshot) {
                  if (reservasController.isFetchingPage) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  
                  final currentReservas = snapshot.data ?? [];
                  
                  if (currentReservas.isEmpty && !reservasController.isFetchingPage) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.table_chart, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay reservas para mostrar',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return _buildReservasContent(context, currentReservas);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterTitle(bool isWide) {
    final filterTitle = _getFilterTitle(
      reservasController.selectedFilter,
      reservasController.customDate,
      reservasController.turnoFilter,
    );

    return Text(
      filterTitle,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isWide ? 18 : 20,
      ),
    );
  }

  Widget _buildReservasContent(BuildContext context, List<ReservaConAgencia> currentReservas) {
    final authController = context.read<AuthController>();
    final lastSeen = authController.appUser?.lastSeenReservas;

    return Column(
      children: [
        isTableView
            ? ReservasTable(
                turno: reservasController.turnoFilter,
                reservas: currentReservas,
                agenciaId: agenciaId,
                onUpdate: () {
                  reservasController.updateFilter(
                    reservasController.selectedFilter,
                    date: reservasController.customDate,
                    agenciaId: agenciaId,
                    turno: reservasController.turnoFilter,
                  );
                },
                currentFilter: reservasController.selectedFilter,
                lastSeenReservas: lastSeen,
                reservaIdNotificada: reservaIdNotificada,
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: currentReservas.length,
                itemBuilder: (ctx, i) {
                  return ReservaCardItem(
                    reserva: currentReservas[i],
                    onTap: () => _showReservaDetails(context, currentReservas[i]),
                  );
                },
              ),
      ],
    );
  }

  void _showReservaDetails(BuildContext context, ReservaConAgencia reserva) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReservaDetails(
        reserva: reserva,
        onUpdate: () {
          reservasController.updateFilter(
            reservasController.selectedFilter,
            date: reservasController.customDate,
            agenciaId: agenciaId,
            turno: reservasController.turnoFilter,
          );
        },
      ),
    );
  }

  String _getFilterTitle(
    DateFilterType selectedFilter,
    DateTime? customDate,
    TurnoType? selectedTurno,
  ) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];

    String formatearFecha(DateTime fecha) {
      return '${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}';
    }

    String dateText;
    switch (selectedFilter) {
      case DateFilterType.all:
        dateText = 'Todas las reservas';
        break;
      case DateFilterType.lastWeek:
        dateText = 'Reservas de la última semana';
        break;
      case DateFilterType.today:
        dateText = formatearFecha(DateTime.now());
        break;
      case DateFilterType.yesterday:
        dateText = formatearFecha(DateTime.now().subtract(const Duration(days: 1)));
        break;
      case DateFilterType.tomorrow:
        dateText = formatearFecha(DateTime.now().add(const Duration(days: 1)));
        break;
      case DateFilterType.custom:
        dateText = customDate != null ? formatearFecha(customDate) : 'Fecha personalizada';
        break;
    }

    String turnoText = '';
    if (selectedTurno != null) {
      turnoText = selectedTurno == TurnoType.manana ? ' 🌅 (Mañana)' : ' 🌆 (Tarde)';
    }

    return '$dateText$turnoText';
  }
}
