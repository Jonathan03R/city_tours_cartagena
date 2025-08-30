import 'package:citytourscartagena/core/controller/gastos_controller.dart';
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
  
  static const Color _primaryNavy = Color(0xFF0F172A);
  static const Color _secondaryNavy = Color(0xFF1E293B);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _lightBlue = Color(0xFF60A5FA);
  static const Color _surfaceWhite = Color(0xFFFFFFFF);
  static const Color _backgroundGray = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _errorRed = Color(0xFFEF4444);
  static const Color _successGreen = Color(0xFF10B981);

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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3), 
      end: Offset.zero
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

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
      backgroundColor: _backgroundGray,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundGray, Color(0xFFE2E8F0)],
            stops: [0.0, 1.0],
          ),
        ),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryNavy, _secondaryNavy],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32.r),
                    bottomRight: Radius.circular(32.r),
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: Text(
                    'Historial de Gastos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            ),
            
            if (_cargando)
              SliverFillRemaining(
                child: _buildLoadingState(),
              )
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
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: _primaryNavy.withOpacity(0.1),
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
                valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
                strokeWidth: 4.w,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Cargando historial...',
              style: TextStyle(
                color: _textPrimary,
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
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _primaryNavy.withOpacity(0.08),
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
                  colors: [_errorRed, Color(0xFFF87171)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: _errorRed.withOpacity(0.3),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 32.sp,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _controller.estadoTexto,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Gestiona tus gastos empresariales',
                    style: TextStyle(
                      color: _textSecondary,
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
            child: _buildGastoCard(gasto, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGastoCard(Map<String, dynamic> gasto, int index) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final fecha = gasto['fecha']?.toDate() ?? DateTime.now();
    final descripcion = gasto['descripcion'] ?? 'Sin descripción';
    final monto = (gasto['monto'] ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: _surfaceWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withOpacity(0.06),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gasto: $descripcion'),
                backgroundColor: _accentBlue,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_errorRed.withOpacity(0.1), _errorRed.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.trending_down_rounded,
                    color: _errorRed,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        descripcion,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: _textSecondary,
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            DateFormat('dd/MM/yyyy • HH:mm').format(fecha),
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: _errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        formatter.format(monto),
                        style: TextStyle(
                          color: _errorRed,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: _textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(40.w),
        decoration: BoxDecoration(
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: _primaryNavy.withOpacity(0.06),
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
                  colors: [_textSecondary.withOpacity(0.1), _textSecondary.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.receipt_outlined,
                size: 48.sp,
                color: _textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No hay gastos registrados',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Los gastos aparecerán aquí cuando los registres',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14.sp,
              ),
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
          color: _surfaceWhite,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: _primaryNavy.withOpacity(0.06),
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
                    ? LinearGradient(colors: [_accentBlue, _lightBlue])
                    : null,
                color: _controller.paginaActual > 1 ? null : _textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: _controller.paginaActual > 1 ? [
                  BoxShadow(
                    color: _accentBlue.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: _controller.paginaActual > 1 ? _anterior : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _controller.paginaActual > 1 ? Colors.white : _textSecondary,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Anterior',
                          style: TextStyle(
                            color: _controller.paginaActual > 1 ? Colors.white : _textSecondary,
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
                color: _accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Página ${_controller.paginaActual} de ${_controller.totalPaginas}',
                style: TextStyle(
                  color: _accentBlue,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                gradient: _controller.paginaActual < _controller.totalPaginas 
                    ? LinearGradient(colors: [_accentBlue, _lightBlue])
                    : null,
                color: _controller.paginaActual < _controller.totalPaginas ? null : _textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: _controller.paginaActual < _controller.totalPaginas ? [
                  BoxShadow(
                    color: _accentBlue.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ] : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: _controller.paginaActual < _controller.totalPaginas ? _siguiente : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Siguiente',
                          style: TextStyle(
                            color: _controller.paginaActual < _controller.totalPaginas ? Colors.white : _textSecondary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _controller.paginaActual < _controller.totalPaginas ? Colors.white : _textSecondary,
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
