import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum MoreFilterOption { yesterday, tomorrow, lastWeek }

class FiltrosView extends StatefulWidget {
  // Filtros de fecha
  final DateFilterType selectedFilter;
  final DateTime? customDate;
  final Function(DateFilterType, DateTime?, {TurnoType? turno}) onFilterChanged;
  
  // Filtros de turno (ahora tipos de servicios)
  final int? selectedTurno;
  final ValueChanged<int?> onTurnoChanged;
  final List<TipoServicio> tiposServicios;
  
  // Filtros de estado
  final EstadoReserva? selectedEstado;
  final ValueChanged<EstadoReserva?> onEstadoChanged;
  // Control del acordeón: expandido inicial
  final bool initiallyExpanded;

  const FiltrosView({
    super.key,
    required this.selectedFilter,
    this.customDate,
    required this.onFilterChanged,
    this.selectedTurno,
    required this.onTurnoChanged,
    required this.tiposServicios,
    this.selectedEstado,
    required this.onEstadoChanged,
    this.initiallyExpanded = false,
  });

  @override
  State<FiltrosView> createState() => _FiltrosViewState();
}

class _FiltrosViewState extends State<FiltrosView>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
  _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    if (_isExpanded) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildAccordionHeader(),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildFilterContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionHeader() {
    return InkWell(
      onTap: _toggleExpansion,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.tune,
                color: AppColors.primary,
                size: 20.sp,
              ),
            ),
            
            SizedBox(width: 12.w),
            
            // Información de filtros activos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkPrimary
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _getActiveFiltersText(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.gray600
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Indicadores de filtros activos
            _buildActiveFilterIndicators(),
            
            SizedBox(width: 8.w),
            
            // Icono de expansión
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterIndicators() {
    List<Widget> indicators = [];
    
    // Indicador de turno
    if (widget.selectedTurno != null) {
      final tipo = widget.tiposServicios.firstWhere(
        (t) => t.codigo == widget.selectedTurno,
        orElse: () => TipoServicio(codigo: -1, descripcion: 'Desconocido'),
      );
      indicators.add(_buildFilterChip(
        tipo.descripcion,
        Colors.orange.shade600,
        Icons.access_time,
      ));
    }
    
    // Indicador de estado
    if (widget.selectedEstado != null) {
      indicators.add(_buildFilterChip(
        widget.selectedEstado == EstadoReserva.pendiente ? 'Pendientes' : 'Pagadas',
        widget.selectedEstado == EstadoReserva.pendiente 
            ? Colors.orange.shade600 
            : Colors.green.shade600,
        widget.selectedEstado == EstadoReserva.pendiente 
            ? Icons.pending_actions 
            : Icons.check_circle,
      ));
    }
    
    // Indicador de fecha especial
    if (widget.selectedFilter != DateFilterType.today && widget.selectedFilter != DateFilterType.all) {
      indicators.add(_buildFilterChip(
        _getDateFilterLabel(),
        Colors.blue.shade600,
        Icons.date_range,
      ));
    }
    
    if (indicators.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: indicators.take(2).map((indicator) => Padding(
        padding: EdgeInsets.only(left: 4.w),
        child: indicator,
      )).toList(),
    );
  }

  Widget _buildFilterChip(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        children: [
          // Divider elegante
          Container(
            height: 1,
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade300,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Sección de filtros principales
          _buildMainFiltersSection(),
          
          SizedBox(height: 16.h),
          
          // Sección de filtros de fecha
          _buildDateFiltersSection(),
        ],
      ),
    );
  }

  Widget _buildMainFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros Principales',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildTurnoSelector()),
            SizedBox(width: 12.w),
            Expanded(child: _buildEstadoSelector()),
          ],
        ),
      ],
    );
  }

  Widget _buildDateFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtros de Fecha',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 12.h),
        _buildDateFilters(),
      ],
    );
  }

  Widget _buildTurnoSelector() {
    return Container(
      decoration: BoxDecoration(
        color: widget.selectedTurno != null 
            ? Colors.orange.shade50 
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: widget.selectedTurno != null 
              ? Colors.orange.shade200 
              : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTurnoSelector(context),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: widget.selectedTurno != null 
                      ? Colors.orange.shade600 
                      : Colors.grey.shade600,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Turno',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.selectedTurno != null 
                            ? widget.tiposServicios.firstWhere(
                                (t) => t.codigo == widget.selectedTurno,
                                orElse: () => TipoServicio(codigo: -1, descripcion: 'Desconocido'),
                              ).descripcion
                            : 'Todos los turnos',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: widget.selectedTurno != null 
                              ? Colors.orange.shade700 
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoSelector() {
    return Container(
      decoration: BoxDecoration(
        color: widget.selectedEstado != null 
            ? (widget.selectedEstado == EstadoReserva.pendiente 
                ? Colors.orange.shade50 
                : Colors.green.shade50)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: widget.selectedEstado != null 
              ? (widget.selectedEstado == EstadoReserva.pendiente 
                  ? Colors.orange.shade200 
                  : Colors.green.shade200)
              : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showEstadoSelector(context),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Icon(
                  widget.selectedEstado == EstadoReserva.pendiente 
                      ? Icons.pending_actions
                      : widget.selectedEstado == EstadoReserva.pagada
                          ? Icons.check_circle
                          : Icons.filter_alt,
                  color: widget.selectedEstado != null 
                      ? (widget.selectedEstado == EstadoReserva.pendiente 
                          ? Colors.orange.shade600 
                          : Colors.green.shade600)
                      : Colors.grey.shade600,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        widget.selectedEstado == EstadoReserva.pendiente 
                            ? 'Pendientes'
                            : widget.selectedEstado == EstadoReserva.pagada
                                ? 'Pagadas'
                                : 'Todos los estados',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: widget.selectedEstado != null 
                              ? (widget.selectedEstado == EstadoReserva.pendiente 
                                  ? Colors.orange.shade700 
                                  : Colors.green.shade700)
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    return Column(
      children: [
        // Primera fila: Filtros principales
        Row(
          children: [
            Expanded(
              child: _buildDateFilterButton(
                DateFilterType.today,
                'Hoy',
                Icons.today,
                widget.selectedFilter == DateFilterType.today,
                () => widget.onFilterChanged(DateFilterType.today, null, turno: null),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildDateFilterButton(
                DateFilterType.all,
                'Todas',
                Icons.all_inclusive,
                widget.selectedFilter == DateFilterType.all,
                () => widget.onFilterChanged(DateFilterType.all, null, turno: null),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8.h),
        
        // Segunda fila: Fecha personalizada y más opciones
        Row(
          children: [
            Expanded(
              child: _buildDateFilterButton(
                DateFilterType.custom,
                widget.customDate != null
                    ? _getButtonText(DateFilterType.custom, widget.customDate)
                    : 'Fecha específica',
                Icons.calendar_today,
                widget.selectedFilter == DateFilterType.custom,
                () => _showDatePicker(context),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildMoreFiltersButton(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateFilterButton(
    DateFilterType filterType,
    String text,
    IconData icon,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade600 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreFiltersButton() {
    final isMoreFiltersSelected = widget.selectedFilter == DateFilterType.yesterday ||
        widget.selectedFilter == DateFilterType.tomorrow ||
        widget.selectedFilter == DateFilterType.lastWeek;

    return PopupMenuButton<MoreFilterOption>(
      onSelected: (MoreFilterOption item) {
        switch (item) {
          case MoreFilterOption.yesterday:
            widget.onFilterChanged(DateFilterType.yesterday, null, turno: null);
            break;
          case MoreFilterOption.tomorrow:
            widget.onFilterChanged(DateFilterType.tomorrow, null, turno: null);
            break;
          case MoreFilterOption.lastWeek:
            widget.onFilterChanged(DateFilterType.lastWeek, null, turno: null);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<MoreFilterOption>>[
        PopupMenuItem<MoreFilterOption>(
          value: MoreFilterOption.yesterday,
          child: _buildPopupMenuItem(
            Icons.arrow_back,
            'Ayer',
            Colors.blue.shade600,
          ),
        ),
        PopupMenuItem<MoreFilterOption>(
          value: MoreFilterOption.tomorrow,
          child: _buildPopupMenuItem(
            Icons.arrow_forward,
            'Mañana',
            Colors.blue.shade600,
          ),
        ),
        PopupMenuItem<MoreFilterOption>(
          value: MoreFilterOption.lastWeek,
          child: _buildPopupMenuItem(
            Icons.date_range,
            'Última Semana',
            Colors.blue.shade600,
          ),
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: isMoreFiltersSelected ? Colors.blue.shade600 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isMoreFiltersSelected ? Colors.blue.shade600 : Colors.grey.shade200,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.more_horiz,
                color: isMoreFiltersSelected ? Colors.white : Colors.grey.shade600,
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'Más opciones',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: isMoreFiltersSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isMoreFiltersSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenuItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: 12.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares
  String _getActiveFiltersText() {
    List<String> activeFilters = [];
    
    if (widget.selectedTurno != null) {
      final tipo = widget.tiposServicios.firstWhere(
        (t) => t.codigo == widget.selectedTurno,
        orElse: () => TipoServicio(codigo: -1, descripcion: 'Desconocido'),
      );
      activeFilters.add(tipo.descripcion);
    }
    
    if (widget.selectedEstado != null) {
      activeFilters.add(widget.selectedEstado == EstadoReserva.pendiente ? 'Pendientes' : 'Pagadas');
    }
    
    if (widget.selectedFilter != DateFilterType.today && widget.selectedFilter != DateFilterType.all) {
      activeFilters.add(_getDateFilterLabel());
    }
    
    if (activeFilters.isEmpty) {
      return 'Filtros básicos activos';
    }
    
    return activeFilters.join(' • ');
  }

  String _getDateFilterLabel() {
    switch (widget.selectedFilter) {
      case DateFilterType.yesterday:
        return 'Ayer';
      case DateFilterType.tomorrow:
        return 'Mañana';
      case DateFilterType.lastWeek:
        return 'Última semana';
      case DateFilterType.custom:
        return widget.customDate != null 
            ? _getButtonText(DateFilterType.custom, widget.customDate)
            : 'Fecha específica';
      default:
        return '';
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
      case DateFilterType.custom:
        return date != null ? formatearFecha(date) : 'Fecha específica';
      default:
        return '';
    }
  }

  // Métodos de interacción
  void _showTurnoSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            
            Text(
              'Seleccionar Servicio',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 20.h),
            
            ...widget.tiposServicios.map((tipo) => _buildBottomSheetOption(
              icon: Icons.schedule,
              title: tipo.descripcion,
              subtitle: 'Tipo de servicio',
              isSelected: widget.selectedTurno == tipo.codigo,
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                widget.onTurnoChanged(tipo.codigo);
              },
            )),
            
            _buildBottomSheetOption(
              icon: Icons.clear,
              title: 'Quitar filtro',
              subtitle: 'Mostrar todos los servicios',
              isSelected: false,
              color: Colors.grey,
              onTap: () {
                Navigator.pop(context);
                widget.onTurnoChanged(null);
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showEstadoSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            
            Text(
              'Seleccionar Estado',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 20.h),
            
            _buildBottomSheetOption(
              icon: Icons.pending_actions,
              title: 'Pendientes',
              subtitle: 'Reservas sin pagar',
              isSelected: widget.selectedEstado == EstadoReserva.pendiente,
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                widget.onEstadoChanged(
                  widget.selectedEstado == EstadoReserva.pendiente 
                      ? null 
                      : EstadoReserva.pendiente,
                );
              },
            ),
            
            _buildBottomSheetOption(
              icon: Icons.check_circle,
              title: 'Pagadas',
              subtitle: 'Reservas completadas',
              isSelected: widget.selectedEstado == EstadoReserva.pagada,
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                widget.onEstadoChanged(
                  widget.selectedEstado == EstadoReserva.pagada 
                      ? null 
                      : EstadoReserva.pagada,
                );
              },
            ),
            
            _buildBottomSheetOption(
              icon: Icons.clear,
              title: 'Quitar filtro',
              subtitle: 'Mostrar todos los estados',
              isSelected: false,
              color: Colors.grey,
              onTap: () {
                Navigator.pop(context);
                widget.onEstadoChanged(null);
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected ? color.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : Colors.grey.shade800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: isSelected 
            ? Icon(Icons.check, color: color, size: 20.sp)
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.customDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      widget.onFilterChanged(DateFilterType.custom, pickedDate, turno: null);
    }
  }
}
