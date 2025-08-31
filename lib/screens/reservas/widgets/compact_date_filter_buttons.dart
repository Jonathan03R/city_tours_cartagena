import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum MoreFilterOption { yesterday, tomorrow, lastWeek }

class CompactDateFilterButtons extends StatelessWidget {
  final DateFilterType selectedFilter;
  final DateTime? customDate;
  final TurnoType? selectedTurno;
  final Function(DateFilterType, DateTime?, {TurnoType? turno}) onFilterChanged;

  const CompactDateFilterButtons({
    super.key,
    required this.selectedFilter,
    this.customDate,
    this.selectedTurno,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMoreFiltersSelected = selectedFilter == DateFilterType.yesterday ||
        selectedFilter == DateFilterType.tomorrow ||
        selectedFilter == DateFilterType.lastWeek;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton(
            context,
            DateFilterType.today,
            _getButtonText(DateFilterType.today, null),
            selectedFilter == DateFilterType.today,
            onPressed: () => onFilterChanged(DateFilterType.today, null, turno: null),
          ),
          _buildFilterButton(
            context,
            DateFilterType.all,
            _getButtonText(DateFilterType.all, null),
            selectedFilter == DateFilterType.all,
            onPressed: () => onFilterChanged(DateFilterType.all, null, turno: null),
          ),
          _buildFilterButton(
            context,
            DateFilterType.custom,
            customDate != null
                ? _getButtonText(DateFilterType.custom, customDate)
                : 'Fecha Específica',
            selectedFilter == DateFilterType.custom,
            onPressed: () => _showDatePicker(context),
          ),
          _buildMoreFiltersButton(context, isMoreFiltersSelected),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    DateFilterType filterType,
    String text,
    bool isSelected, {
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.0.w),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: isSelected ? 4 : 1,
            minimumSize: const Size(0, 40),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreFiltersButton(BuildContext context, bool isMoreFiltersSelected) {
    return PopupMenuButton<MoreFilterOption>(
      onSelected: (MoreFilterOption item) {
        switch (item) {
          case MoreFilterOption.yesterday:
            onFilterChanged(DateFilterType.yesterday, null, turno: null);
            break;
          case MoreFilterOption.tomorrow:
            onFilterChanged(DateFilterType.tomorrow, null, turno: null);
            break;
          case MoreFilterOption.lastWeek:
            onFilterChanged(DateFilterType.lastWeek, null, turno: null);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<MoreFilterOption>>[
        PopupMenuItem<MoreFilterOption>(
          value: MoreFilterOption.yesterday,
          child: Text(_getMoreFilterOptionText(MoreFilterOption.yesterday)),
        ),
        PopupMenuItem<MoreFilterOption>(
          value: MoreFilterOption.tomorrow,
          child: Text(_getMoreFilterOptionText(MoreFilterOption.tomorrow)),
        ),
        PopupMenuItem<MoreFilterOption>(
          value: MoreFilterOption.lastWeek,
          child: Text(_getMoreFilterOptionText(MoreFilterOption.lastWeek)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMoreFiltersSelected ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMoreFiltersSelected ? Colors.blue.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_list,
              size: 18.sp,
              color: isMoreFiltersSelected ? Colors.white : Colors.blue,
            ),
            const SizedBox(width: 4),
            Text(
              'Más filtros',
              style: TextStyle(
                color: isMoreFiltersSelected ? Colors.white : Colors.blue,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: customDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      onFilterChanged(DateFilterType.custom, pickedDate, turno: null);
    }
  }

  String _getButtonText(DateFilterType filter, DateTime? date) {
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];

    String formatearFecha(DateTime fecha) {
      return '${fecha.day} de ${meses[fecha.month - 1]}';
    }

    switch (filter) {
      case DateFilterType.all:
        return 'Todas';
      case DateFilterType.today:
        return 'Hoy';
      case DateFilterType.yesterday:
        return 'Ayer';
      case DateFilterType.tomorrow:
        return 'Mañana';
      case DateFilterType.lastWeek:
        return 'Última Semana';
      case DateFilterType.custom:
        return date != null ? formatearFecha(date) : 'Fecha Específica';
    }
  }

  String _getMoreFilterOptionText(MoreFilterOption option) {
    switch (option) {
      case MoreFilterOption.yesterday:
        return 'Ayer';
      case MoreFilterOption.tomorrow:
        return 'Mañana';
      case MoreFilterOption.lastWeek:
        return 'Última Semana';
    }
  }
}
