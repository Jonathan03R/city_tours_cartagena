import 'package:citytourscartagena/core/controller/filters_controller.dart';
import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/models/enum/selecion_rango_fechas.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/widgets/moder_buttom.dart';
import 'package:citytourscartagena/core/widgets/moder_card.dart';
import 'package:citytourscartagena/screens/reportes/historial_gastos_view.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/filtros_flexibles.dart';
import 'package:citytourscartagena/screens/reportes/widget_reportes/grafica_gastos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ModernGastosScreen extends StatefulWidget {
  const ModernGastosScreen({super.key});

  @override
  _ModernGastosScreenState createState() => _ModernGastosScreenState();
}

class _ModernGastosScreenState extends State<ModernGastosScreen> {
  late FiltroFlexibleController _filtrosController;

  @override
  void initState() {
    super.initState();
    _filtrosController = FiltroFlexibleController();
    // // Default: última semana y 3 anteriores
    _filtrosController.seleccionarPeriodo(FiltroPeriodo.semana);
    // final now = DateTime.now();
    // for (var i = 0; i < 4; i++) {
    //   _filtrosController.agregarSemana(now.subtract(Duration(days: i * 7)));
    // }
  }

  @override
  void dispose() {
    _filtrosController.dispose();
    super.dispose();
  }

  void _mostrarModalAgregarGasto(
    BuildContext context,
    GastosController gastosController,
  ) {
    final TextEditingController montoController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    DateTime fechaSeleccionada = DateTime.now();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.add_card_outlined,
                            size: 20.sp,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Agregar Nuevo Gasto',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    // Campo Monto
                    Text(
                      'Monto',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.textLight.withOpacity(0.3),
                          width: 1.w,
                        ),
                      ),
                      child: TextField(
                        controller: montoController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ingresa el monto',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: AppColors.textSecondary,
                            size: 20.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Campo Descripción
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.textLight.withOpacity(0.3),
                          width: 1.w,
                        ),
                      ),
                      child: TextField(
                        controller: descripcionController,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe el gasto',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            color: AppColors.textSecondary,
                            size: 20.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Selector de fecha
                    Text(
                      'Fecha',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
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
                        if (picked != null && picked != fechaSeleccionada) {
                          setState(() {
                            fechaSeleccionada = picked;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.textLight.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: AppColors.textSecondary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              '${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: ModernButton(
                            text: 'Cancelar',
                            isOutlined: true,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ModernButton(
                            text: 'Agregar',
                            isLoading: isLoading,
                            onPressed: () async {
                              final double? monto = double.tryParse(montoController.text);
                              final String descripcion = descripcionController.text.trim();
                              
                              if (monto != null && descripcion.isNotEmpty) {
                                setState(() => isLoading = true);
                                try {
                                  await gastosController.agregarGasto(
                                    monto: monto,
                                    descripcion: descripcion,
                                    fecha: fechaSeleccionada,
                                  );
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gasto agregado exitosamente'),
                                      backgroundColor: AppColors.success,
                                      behavior: SnackBarBehavior.fixed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al agregar gasto'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.fixed,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                    ),
                                  );
                                } finally {
                                  setState(() => isLoading = false);
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Por favor, completa todos los campos'),
                                    backgroundColor: AppColors.warning,
                                    behavior: SnackBarBehavior.fixed,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GastosController>(
      builder: (context, rc, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundGray,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            title: Text(
              'Gastos y Finanzas',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
                size: 20.sp,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: ChangeNotifierProvider.value(
              value: _filtrosController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtros
                  ModernFiltrosFlexiblesWidget(controller: _filtrosController),
                  SizedBox(height: 20.h),
                  
                  // Contenido principal
                  StreamBuilder<List<ReservaConAgencia>>(
                    stream: rc.reservasStream,
                    builder: (context, snapRes) {
                      if (snapRes.connectionState == ConnectionState.waiting) {
                        return ModernCard(
                          child: Container(
                            height: 200.h,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.accentBlue,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'Cargando datos...',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      
                      final reservas = snapRes.data ?? [];
                      return Consumer<FiltroFlexibleController>(
                        builder: (context, fc, _) {
                          if (fc.periodoSeleccionado == null) {
                            return ModernCard(
                              child: Container(
                                height: 200.h,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.filter_alt_outlined,
                                      size: 48.sp,
                                      color: AppColors.textLight,
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Seleccione un período para ver los datos',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          // ... existing code for determining inicio and fin ...
                          late DateTime inicio, fin;
                          switch (fc.periodoSeleccionado!) {
                            case FiltroPeriodo.semana:
                              final semanas = List<DateTimeRange>.from(fc.semanasSeleccionadas)
                                ..sort((a, b) => a.start.compareTo(b.start));
                              if (semanas.isEmpty) {
                                return ModernCard(
                                  child: Container(
                                    height: 200.h,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_view_week_outlined,
                                          size: 48.sp,
                                          color: AppColors.textLight,
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'Agregue al menos una semana',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              inicio = semanas.first.start;
                              fin = semanas.last.end;
                              break;
                            case FiltroPeriodo.mes:
                              final meses = List<DateTime>.from(fc.mesesSeleccionados)
                                ..sort((a, b) {
                                  if (a.year != b.year) return a.year.compareTo(b.year);
                                  return a.month.compareTo(b.month);
                                });
                              if (meses.isEmpty) {
                                return ModernCard(
                                  child: Container(
                                    height: 200.h,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_month_outlined,
                                          size: 48.sp,
                                          color: AppColors.textLight,
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'Agregue al menos un mes',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              inicio = DateTime(meses.first.year, meses.first.month, 1);
                              fin = DateTime(meses.last.year, meses.last.month + 1, 1)
                                  .subtract(const Duration(days: 1));
                              break;
                            case FiltroPeriodo.anio:
                              final anios = List<int>.from(fc.aniosSeleccionados)..sort();
                              if (anios.isEmpty) {
                                return ModernCard(
                                  child: Container(
                                    height: 200.h,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 48.sp,
                                          color: AppColors.textLight,
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'Agregue al menos un año',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              inicio = DateTime(anios.first, 1, 1);
                              fin = DateTime(anios.last, 12, 31);
                              break;
                          }
                          
                          return FutureBuilder<List<FinanceCategoryData>>(
                            future: rc.agruparFinanzasPorPeriodo(
                              reservas,
                              inicio,
                              fin,
                              turno: fc.turnoSeleccionado,
                              tipoAgrupacion: fc.periodoSeleccionado == FiltroPeriodo.semana
                                  ? 'semana'
                                  : fc.periodoSeleccionado == FiltroPeriodo.mes
                                      ? 'mes'
                                      : 'año',
                            ),
                            builder: (context, snapFin) {
                              if (snapFin.connectionState == ConnectionState.waiting) {
                                return ModernCard(
                                  child: SizedBox(
                                    height: 200.h,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.accentBlue,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              
                              if (snapFin.hasError) {
                                return ModernCard(
                                  child: Container(
                                    height: 200.h,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 48.sp,
                                          color: AppColors.error,
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'Error: ${snapFin.error}',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.error,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final finanzas = snapFin.data ?? [];

                              if (finanzas.isEmpty) {
                                return ModernCard(
                                  child: Container(
                                    height: 200.h,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.analytics_outlined,
                                          size: 48.sp,
                                          color: AppColors.textLight,
                                        ),
                                        SizedBox(height: 16.h),
                                        Text(
                                          'No hay datos para este período',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return FutureBuilder<Map<String, double>>(
                                future: rc.calcularTotales(finanzas),
                                builder: (context, snapTotales) {
                                  if (!snapTotales.hasData) {
                                    return ModernCard(
                                      child: Container(
                                        height: 200.h,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              AppColors.accentBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  final totales = snapTotales.data!;
                                  final periodoLabel = fc.periodoSeleccionado == FiltroPeriodo.semana
                                      ? 'Semana'
                                      : fc.periodoSeleccionado == FiltroPeriodo.mes
                                          ? 'Mes'
                                          : 'Año';

                                  return Column(
                                    children: [
                                      // Tarjeta de totales moderna
                                      ModernCard(
                                        hasGradient: true,
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(8.w),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.accentBlue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12.r),
                                                  ),
                                                  child: Icon(
                                                    Icons.account_balance_wallet_outlined,
                                                    size: 20.sp,
                                                    color: AppColors.accentBlue,
                                                  ),
                                                ),
                                                SizedBox(width: 12.w),
                                                Text(
                                                  "Resumen $periodoLabel",
                                                  style: TextStyle(
                                                    fontSize: 18.sp,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 20.h),
                                            
                                            // Grid de métricas
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildMetricCard(
                                                    'Ingresos',
                                                    '\$${totales["ganancias"]!.toStringAsFixed(0)}',
                                                    Icons.trending_up,
                                                    AppColors.success,
                                                  ),
                                                ),
                                                SizedBox(width: 12.w),
                                                Expanded(
                                                  child: _buildMetricCard(
                                                    'Gastos',
                                                    '\$${totales["gastos"]!.toStringAsFixed(0)}',
                                                    Icons.trending_down,
                                                    AppColors.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 12.h),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildMetricCard(
                                                    'Utilidad',
                                                    '\$${totales["utilidad"]!.toStringAsFixed(0)}',
                                                    Icons.account_balance,
                                                    AppColors.accentBlue,
                                                  ),
                                                ),
                                                SizedBox(width: 12.w),
                                                Expanded(
                                                  child: _buildMetricCard(
                                                    'Margen',
                                                    '${totales["margen"]!.toStringAsFixed(1)}%',
                                                    Icons.percent,
                                                    AppColors.warning,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 20.h),

                                      // Gráfico moderno
                                      ModernGraficaFinanzas(
                                        data: finanzas,
                                        titulo: 'Análisis Financiero por $periodoLabel',
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 20.h),

                  // Botones de acción modernos
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          text: 'Agregar Gasto',
                          icon: Icons.add_card_outlined,
                          onPressed: () async {
                            final gastosController = Provider.of<GastosController>(
                              context,
                              listen: false,
                            );
                            _mostrarModalAgregarGasto(context, gastosController);
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ModernButton(
                          text: 'Ver Historial',
                          icon: Icons.history_outlined,
                          isSecondary: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistorialGastosView(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: color,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
