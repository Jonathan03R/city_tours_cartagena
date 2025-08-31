import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/moder_buttom.dart';
import 'package:citytourscartagena/core/widgets/moder_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';


class ModernFiltrosFlexiblesWidget extends StatefulWidget {
  final FiltroFlexibleController controller;
  const ModernFiltrosFlexiblesWidget({super.key, required this.controller});

  @override
  State<ModernFiltrosFlexiblesWidget> createState() => _ModernFiltrosFlexiblesWidgetState();
}

class _ModernFiltrosFlexiblesWidgetState extends State<ModernFiltrosFlexiblesWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ModernCard(
      hasGradient: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accentBlue, AppColors.lightBlue],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.filter_alt_outlined,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Filtros de Análisis',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (!_isExpanded) _buildCompactSummary(c),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),

                // Selección de turno (si hay periodo seleccionado)
                if (c.periodoSeleccionado != null) ...[
                  Text(
                    'Turno:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.textLight.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: DropdownButton<TurnoType?>(
                      value: c.turnoSeleccionado,
                      isExpanded: true,
                      underline: SizedBox(),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      items: [
                        DropdownMenuItem<TurnoType?>(
                          value: null,
                          child: Text('Todos los turnos'),
                        ),
                        ...TurnoType.values.map((tt) {
                          return DropdownMenuItem<TurnoType?>(
                            value: tt,
                            child: Text(tt.label),
                          );
                        }).toList(),
                      ],
                      onChanged: (tt) => setState(() => c.seleccionarTurno(tt)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Selección de periodo
                Text(
                  'Período de Análisis:',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.textLight.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                  child: DropdownButton<FiltroPeriodo>(
                    value: c.periodoSeleccionado,
                    hint: Text(
                      'Selecciona período',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.sp,
                      ),
                    ),
                    isExpanded: true,
                    underline: SizedBox(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    items: FiltroPeriodo.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Icon(
                              _getIconForPeriod(p),
                              size: 16.sp,
                              color: AppColors.accentBlue,
                            ),
                            SizedBox(width: 8.w),
                            Text(p.name[0].toUpperCase() + p.name.substring(1)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (p) {
                      setState(() => c.seleccionarPeriodo(p!));
                    },
                  ),
                ),
                SizedBox(height: 16.h),

                // Botones de acción según el período
                if (c.periodoSeleccionado == FiltroPeriodo.semana)
                  ModernButton(
                    text: 'Agregar Semana',
                    icon: Icons.calendar_view_week,
                    onPressed: () async {
                      final now = DateTime.now();
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 5),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppColors.accentBlue,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: AppColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (fecha != null) {
                        c.agregarSemana(fecha);
                        setState(() {});
                      }
                    },
                  ),

                if (c.periodoSeleccionado == FiltroPeriodo.mes)
                  ModernButton(
                    text: 'Seleccionar Mes',
                    icon: Icons.calendar_month,
                    onPressed: () async {
                      final now = DateTime.now();
                      final selected = await showMonthPicker(
                        context: context,
                        initialDate: DateTime(now.year, now.month),
                        firstDate: DateTime(now.year - 5, 1),
                        lastDate: DateTime(now.year + 5, 12),
                      );
                      if (selected != null) {
                        c.agregarMes(DateTime(selected.year, selected.month, 1));
                        setState(() {});
                      }
                    },
                  ),

                if (c.periodoSeleccionado == FiltroPeriodo.anio)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.textLight.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: DropdownButton<int>(
                      hint: Text(
                        'Selecciona año',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14.sp,
                        ),
                      ),
                      value: null,
                      isExpanded: true,
                      underline: SizedBox(),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                      items: List.generate(11, (i) => DateTime.now().year - 5 + i).map((anio) {
                        return DropdownMenuItem(
                          value: anio,
                          child: Text(
                            anio.toString(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (anio) {
                        if (anio != null) {
                          c.agregarAnio(anio);
                          setState(() {});
                        }
                      },
                    ),
                  ),

                SizedBox(height: 16.h),

                if (c.periodoSeleccionado == FiltroPeriodo.semana && c.semanasSeleccionadas.isNotEmpty)
                  _buildCompactSemanasChips(c),

                if (c.periodoSeleccionado == FiltroPeriodo.mes && c.mesesSeleccionados.isNotEmpty)
                  _buildCompactMesesChips(c),

                if (c.periodoSeleccionado == FiltroPeriodo.anio && c.aniosSeleccionados.isNotEmpty)
                  _buildCompactAniosChips(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummary(FiltroFlexibleController c) {
    if (c.periodoSeleccionado == null) return SizedBox();
    
    int count = 0;
    String type = '';
    
    if (c.periodoSeleccionado == FiltroPeriodo.semana) {
      count = c.semanasSeleccionadas.length;
      type = 'semana${count != 1 ? 's' : ''}';
    } else if (c.periodoSeleccionado == FiltroPeriodo.mes) {
      count = c.mesesSeleccionados.length;
      type = 'mes${count != 1 ? 'es' : ''}';
    } else if (c.periodoSeleccionado == FiltroPeriodo.anio) {
      count = c.aniosSeleccionados.length;
      type = 'año${count != 1 ? 's' : ''}';
    }

    if (count == 0) return SizedBox();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        '$count $type',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.accentBlue,
        ),
      ),
    );
  }

  Widget _buildCompactSemanasChips(FiltroFlexibleController c) {
    final semanasOrdenadas = List<DateTimeRange>.from(c.semanasSeleccionadas)
      ..sort((a, b) => a.start.compareTo(b.start)); // Ascendente: más antigua primero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semanas Seleccionadas (${semanasOrdenadas.length}):',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 40.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: semanasOrdenadas.length,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, i) {
              final semana = semanasOrdenadas[i];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.accentBlue.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_view_week,
                      size: 14.sp,
                      color: AppColors.accentBlue,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${i + 1} (${_formatDate(semana.start)} - ${_formatDate(semana.end)})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () {
                        c.eliminarSemana(semana);
                        setState(() {});
                      },
                      child: Icon(
                        Icons.close,
                        size: 16.sp,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactMesesChips(FiltroFlexibleController c) {
    final mesesOrdenados = List<DateTime>.from(c.mesesSeleccionados)
      ..sort((a, b) {
        if (a.year != b.year) return a.year.compareTo(b.year);
        return a.month.compareTo(b.month);
      }); // Ascendente: más antiguo primero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meses Seleccionados (${mesesOrdenados.length}):',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 40.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: mesesOrdenados.length,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final m = mesesOrdenados[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.success.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 14.sp,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${index + 1} (${_nombreMes(m.month)} ${m.year})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () {
                        c.eliminarMes(m);
                        setState(() {});
                      },
                      child: Icon(
                        Icons.close,
                        size: 16.sp,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactAniosChips(FiltroFlexibleController c) {
    final aniosOrdenados = List<int>.from(c.aniosSeleccionados)
      ..sort(); // Ascendente: más antiguo primero

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Años Seleccionados (${aniosOrdenados.length}):',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 40.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: aniosOrdenados.length,
            separatorBuilder: (context, index) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final a = aniosOrdenados[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14.sp,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '${index + 1} (${a})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () {
                        c.eliminarAnio(a);
                        setState(() {});
                      },
                      child: Icon(
                        Icons.close,
                        size: 16.sp,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForPeriod(FiltroPeriodo periodo) {
    switch (periodo) {
      case FiltroPeriodo.semana:
        return Icons.calendar_view_week;
      case FiltroPeriodo.mes:
        return Icons.calendar_month;
      case FiltroPeriodo.anio:
        return Icons.calendar_today;
    }
  }

  String _formatDate(DateTime date) {
    // Usa Formatters.formatDate pero trunca a dd/MM para semanas
    final fullDate = Formatters.formatDate(date); // dd/MM/yyyy
    return fullDate.substring(0, 5); // dd/MM
  }



  String _nombreMes(int mes) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return meses[mes - 1];
  }
}
