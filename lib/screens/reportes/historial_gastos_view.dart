import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HistorialGastosView extends StatefulWidget {
  const HistorialGastosView({super.key});

  @override
  State<HistorialGastosView> createState() => _HistorialGastosViewState();
}

class _HistorialGastosViewState extends State<HistorialGastosView>
    with TickerProviderStateMixin {
  final GastosController _controller = GastosController();
  bool _cargando = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _initData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _controller.inicializar(limite: 5);
    setState(() => _cargando = false);

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _siguiente() async {
    await _controller.siguientePagina();
    setState(() {});
  }

  Future<void> _anterior() async {
    await _controller.paginaAnterior();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: Container(
        color: AppColors.backgroundGray,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.h,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32.r),
                    bottomRight: Radius.circular(32.r),
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    'Historial de Gastos',
                    style: TextStyle(
                      color: AppColors.backgroundWhite,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            ),

            if (_cargando)
              SliverFillRemaining(child: _buildLoadingState())
            else
              SliverPadding(
                padding: EdgeInsets.all(20.w),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsHeader(),
                    SizedBox(height: 24.h),
                    _buildGastosList(),
                    SizedBox(height: 24.h),
                    _buildPaginationControls(),
                    SizedBox(height: 100.h), // Bottom padding
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(40.r),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNightBlue.withOpacity(0.1),
              blurRadius: 32.r,
              offset: Offset(0, 8.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48.w,
              height: 48.h,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                strokeWidth: 4.w,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Cargando historial...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNightBlue.withOpacity(0.08),
              blurRadius: 20.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.error, Color(0xFFF87171)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: AppColors.backgroundWhite,
                size: 32.sp,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de Gastos',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Consulta el historial de tus gastos recientes.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGastosList() {
    if (_controller.gastosActuales.isEmpty) {
      return _buildEmptyState();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: _controller.gastosActuales.asMap().entries.map((entry) {
          final index = entry.key;
          final gastoDoc = entry.value;
          final gasto = gastoDoc.data() as Map<String, dynamic>;

          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            child: _buildGastoCard(gastoDoc, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGastoCard(QueryDocumentSnapshot gastoDoc, int index) {
    final gasto = gastoDoc.data() as Map<String, dynamic>;

    final fecha = gasto['fecha']?.toDate() ?? DateTime.now();
    final descripcion = gasto['descripcion'] ?? 'Sin descripción';
    final monto = (gasto['monto'] ?? 0).toDouble();
    final formattedMonto = Formatters.formatCurrency(monto);
    final id = gastoDoc.id;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNightBlue.withOpacity(0.06),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descripción y fecha
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descripcion,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.textSecondary,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          DateFormat('dd/MM/yyyy • HH:mm').format(fecha),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Monto y botón de eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Monto
              Text(
                formattedMonto,
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),

              // Botón de eliminar
              GestureDetector(
                onTap: () => _mostrarDialogoEliminar(gasto, id),
                child: Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEliminar(Map<String, dynamic> gasto, String id) {
    final descripcion = gasto['descripcion'] ?? 'este gasto';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24.sp),
            SizedBox(width: 12.w),
            Text(
              'Eliminar Gasto',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de eliminar $descripcion? Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _eliminarGasto(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarGasto(String id) async {
    try {
      await _controller.eliminarGasto(id); // Elimina el gasto

      // Recarga los datos de la primera página
      await _controller.inicializar(limite: _controller.limite);
      setState(() {}); // Notifica a la vista que los datos han cambiado

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gasto eliminado exitosamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar gasto'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(40.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNightBlue.withOpacity(0.06),
              blurRadius: 20.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.textSecondary.withOpacity(0.1),
                    AppColors.textSecondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.receipt_outlined,
                size: 48.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No hay gastos registrados',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Los gastos aparecerán aquí cuando los registres',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNightBlue.withOpacity(0.06),
              blurRadius: 16.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: _controller.paginaActual > 1
                    ? LinearGradient(colors: [AppColors.accentBlue, AppColors.lightBlue])
                    : null,
                color: _controller.paginaActual > 1
                    ? null
                    : AppColors.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: _controller.paginaActual > 1
                    ? [
                        BoxShadow(
                          color: AppColors.accentBlue.withOpacity(0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: _controller.paginaActual > 1 ? _anterior : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _controller.paginaActual > 1
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Anterior',
                          style: TextStyle(
                            color: _controller.paginaActual > 1
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Página ${_controller.paginaActual} de ${_controller.totalPaginas}',
                style: TextStyle(
                  color: AppColors.accentBlue,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                gradient: _controller.paginaActual < _controller.totalPaginas
                    ? LinearGradient(colors: [AppColors.accentBlue, AppColors.lightBlue])
                    : null,
                color: _controller.paginaActual < _controller.totalPaginas
                    ? null
                    : AppColors.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: _controller.paginaActual < _controller.totalPaginas
                    ? [
                        BoxShadow(
                          color: AppColors.accentBlue.withOpacity(0.3),
                          blurRadius: 8.r,
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: _controller.paginaActual < _controller.totalPaginas
                      ? _siguiente
                      : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Siguiente',
                          style: TextStyle(
                            color:
                                _controller.paginaActual <
                                    _controller.totalPaginas
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color:
                              _controller.paginaActual <
                                  _controller.totalPaginas
                              ? Colors.white
                              : AppColors.textSecondary,
                          size: 16.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
