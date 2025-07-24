import 'package:flutter/material.dart';

enum DateFilterType { all, today, yesterday, tomorrow, lastWeek, custom }

class DateFilterButtons extends StatelessWidget {
  final DateFilterType selectedFilter;
  final DateTime? customDate;
  final Function(DateFilterType, DateTime?) onFilterChanged;

  const DateFilterButtons({
    super.key,
    required this.selectedFilter,
    this.customDate,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por fecha:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Todas', DateFilterType.all, Icons.list_alt),
              _buildFilterChip('Hoy', DateFilterType.today, Icons.today),
              _buildFilterChip('Ayer', DateFilterType.yesterday, Icons.history), 
              _buildFilterChip('Mañana', DateFilterType.tomorrow, Icons.next_plan),
              _buildFilterChip('Última semana', DateFilterType.lastWeek, Icons.date_range),
              _buildFilterChip(
                customDate != null
                    ? 'Fecha: ${customDate!.day}/${customDate!.month}'
                    : 'Fecha específica',
                DateFilterType.custom,
                Icons.calendar_today,
                isCustom: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DateFilterType type, IconData icon,
      {bool isCustom = false}) {
    final isSelected = selectedFilter == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (sel) async {
        if (!sel) return;
        if (isCustom) {
          _showDatePicker();
        } else {
          DateTime? date;
          switch (type) {
            case DateFilterType.all:
              date = null;
              break;
            case DateFilterType.today:
              date = DateTime.now();
              break;
            case DateFilterType.yesterday:  // ← nuevo
              date = DateTime.now().subtract(const Duration(days: 1));
              break;
            case DateFilterType.tomorrow:
              date = DateTime.now().add(const Duration(days: 1));
              break;
            case DateFilterType.lastWeek:
              date = DateTime.now().subtract(const Duration(days: 7));
              break;
            case DateFilterType.custom:
              // no entra aquí
              break;
          }
          onFilterChanged(type, date);
        }
      },
    );
  }

  void _showDatePicker() async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: customDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      onFilterChanged(DateFilterType.custom, picked);
    }
  }
}

// Global navigator key para acceder al context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
