import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:flutter/material.dart';

import '../core/mvvc/reservas_controller.dart';
import '../core/widgets/add_reserva_form.dart';
import '../core/widgets/add_reserva_pro_form.dart';
import '../core/widgets/date_filter_buttons.dart';
import '../core/widgets/reserva_card_item.dart';
import '../core/widgets/reserva_details.dart';
import '../core/widgets/reservas_table.dart';

class ReservasView extends StatefulWidget {
  final String? agenciaId;

  const ReservasView({super.key, this.agenciaId});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  List<ReservaConAgencia> _reservas = [];
  DateFilterType _selectedFilter = DateFilterType.today;
  DateTime? _customDate;
  bool _isTableView = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ReservasController.printDebugInfo();
    _loadReservas();
  }

  Future<void> _loadReservas() async {
    setState(() => _isLoading = true);
    try {
      // 1) Obtengo todas las reservas que cumplen el filtro de fecha
      List<ReservaConAgencia> reservas;
      switch (_selectedFilter) {
        case DateFilterType.all:
          reservas = await ReservasController.getAllReservas();
          break;
        case DateFilterType.today:
          reservas = await ReservasController.getReservasByFecha(
            DateTime.now(),
          );
          break;
        case DateFilterType.tomorrow:
          reservas = await ReservasController.getReservasByFecha(
            DateTime.now().add(const Duration(days: 1)),
          );
          break;
        case DateFilterType.lastWeek:
          reservas = await ReservasController.getReservasLastWeek();
          break;
        case DateFilterType.custom:
          if (_customDate != null) {
            reservas = await ReservasController.getReservasByFecha(
              _customDate!,
            );
          } else {
            reservas = [];
          }
          break;
      }

      // 2) Si vengo con una agencia concreta, aplico el filtro adicional
      if (widget.agenciaId != null) {
        reservas = reservas
            .where((r) => r.agencia.id == widget.agenciaId)
            .toList();
      }

      setState(() {
        _reservas = reservas;
        _isLoading = false;
      });
      debugPrint('🔄 Reservas cargadas en vista: ${_reservas.length}');
    } catch (e) {
      debugPrint('❌ Error cargando reservas: $e');
      setState(() {
        _reservas = [];
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(DateFilterType filter, DateTime? date) {
    setState(() {
      _selectedFilter = filter;
      if (date != null) {
        _customDate = date;
      }
    });
    _loadReservas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.agenciaId != null ? 'Reservas de Agencia' : 'Reservas',
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTableView ? Icons.view_list : Icons.table_chart),
            onPressed: () {
              setState(() {
                _isTableView = !_isTableView;
              });
            },
            tooltip: _isTableView ? 'Vista de lista' : 'Vista de tabla',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservas,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de fecha (solo si no es vista de agencia específica)
          // if (widget.agenciaId == null)
          DateFilterButtons(
            selectedFilter: _selectedFilter,
            customDate: _customDate,
            onFilterChanged: _onFilterChanged,
          ),

          // Contador de reservas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getFilterTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_reservas.length} reserva${_reservas.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Vista de contenido
          Expanded(
            child: _isLoading
                // mientras cargas
                ? const Center(child: CircularProgressIndicator())
                // ya cargaste, ahora decides tabla o lista
                : _isTableView
                ? ReservasTable(reservas: _reservas, onUpdate: _loadReservas)
                : _reservas.isEmpty
                ? const Center(child: Text('No hay reservas'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservas.length,
                    itemBuilder: (ctx, i) {
                      return ReservaCardItem(
                        reserva: _reservas[i],
                        onTap: () => _showReservaDetails(_reservas[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.agenciaId == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón Modo Pro
                FloatingActionButton.extended(
                  onPressed: _showAddReservaProForm,
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('registro rapido'),
                  heroTag: "pro_button",
                ),
                const SizedBox(height: 16),
                // Botón normal
                FloatingActionButton(
                  onPressed: _showAddReservaForm,
                  backgroundColor: Colors.blue.shade600,
                  heroTag: "normal_button",
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            )
          : null,
    );
  }

  String _getFilterTitle() {
    switch (_selectedFilter) {
      case DateFilterType.all:
        return 'Todas las reservas';
      case DateFilterType.today:
        return 'Reservas de hoy';
      case DateFilterType.tomorrow:
        return 'Reservas de mañana';
      case DateFilterType.lastWeek:
        return 'Reservas de la última semana';
      case DateFilterType.custom:
        return _customDate != null
            ? 'Reservas del ${_customDate!.day}/${_customDate!.month}/${_customDate!.year}'
            : 'Fecha personalizada';
    }
  }

  void _showReservaDetails(ReservaConAgencia reserva) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          ReservaDetails(reserva: reserva, onUpdate: _loadReservas),
    );
  }

  void _showAddReservaForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaForm(onAdd: _loadReservas),
    );
  }

  void _showAddReservaProForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaProForm(onAdd: _loadReservas),
    );
  }
}
