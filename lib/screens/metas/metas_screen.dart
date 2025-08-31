import 'package:citytourscartagena/core/controller/metas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> with TickerProviderStateMixin {
  final _numeroMetaController = TextEditingController();
  TurnoType? _selectedTurno;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _numeroMetaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _agregarMeta() async {
    if (_numeroMetaController.text.isEmpty || _selectedTurno == null) return;

    setState(() => _isLoading = true);
    try {
      final numeroMeta = double.parse(_numeroMetaController.text);
      await context.read<MetasController>().agregarMeta(
        numeroMeta: numeroMeta,
        turno: _selectedTurno!,
      );
      _numeroMetaController.clear();
      setState(() => _selectedTurno = null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.white, size: 16.w),
              ),
              SizedBox(width: 12.w),
              const Text('Meta agregada exitosamente'),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20.w),
              SizedBox(width: 12.w),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metasController = context.watch<MetasController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
        ),
        title: Text(
          'Gestión de Metas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.w),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAddMetaCard(),
              SizedBox(height: 24.h),
              
              _buildCurrentWeekSection(metasController),
              SizedBox(height: 24.h),

              _buildHistorySection(metasController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMetaCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.add_task, color: Colors.white, size: 20.w),
              ),
              SizedBox(width: 16.w),
              Text(
                'Nueva Meta',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _numeroMetaController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 16.sp, color: const Color(0xFF1E3A8A)),
              decoration: InputDecoration(
                labelText: 'Número de Pasajeros Meta',
                labelStyle: TextStyle(color: const Color(0xFF64748B), fontSize: 14.sp),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.w),
                prefixIcon: Icon(Icons.people, color: const Color(0xFF64748B), size: 20.w),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonFormField<TurnoType>(
              value: _selectedTurno,
              decoration: InputDecoration(
                labelText: 'Turno',
                labelStyle: TextStyle(color: const Color(0xFF64748B), fontSize: 14.sp),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.w),
                prefixIcon: Icon(Icons.schedule, color: const Color(0xFF64748B), size: 20.w),
              ),
              items: TurnoType.values.map((turno) {
                return DropdownMenuItem(
                  value: turno,
                  child: Text(
                    turno.label,
                    style: TextStyle(color: const Color(0xFF1E3A8A), fontSize: 16.sp),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTurno = value),
            ),
          ),
          SizedBox(height: 20.h),
          
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _agregarMeta,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Agregar Meta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildCurrentWeekSection(MetasController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado Actual de la Semana',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        SizedBox(height: 16.h),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: controller.obtenerEstadoSemanaActual(),  // Movido al controller
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard();
            }
            if (snapshot.hasError) {
              return _buildErrorCard('Error: ${snapshot.error}');
            }
            final estados = snapshot.data ?? [];
            return Column(
              children: estados.map((estado) => _buildMetaStatusCard(estado)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetaStatusCard(Map<String, dynamic> estado) {
    final bool cumplida = estado['cumplida'] ?? false;
    final int pasajeros = estado['pasajeros'] ?? 0;
    final double meta = (estado['meta'] ?? 0).toDouble();
    final String turno = estado['turno'] ?? '';
    final double progreso = meta > 0 ? (pasajeros / meta).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: cumplida ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: cumplida ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (cumplida ? const Color(0xFF10B981) : const Color(0xFF1E3A8A)).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: (cumplida ? const Color(0xFF10B981) : const Color(0xFF1E3A8A)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  cumplida ? Icons.check_circle : Icons.schedule,
                  color: cumplida ? const Color(0xFF10B981) : const Color(0xFF1E3A8A),
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turno $turno',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      '$pasajeros de ${meta.toInt()} pasajeros',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: cumplida ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  cumplida ? 'Completada' : 'En Progreso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          
          Container(
            height: 8.h,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progreso,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cumplida 
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${(progreso * 100).toInt()}% completado',
            style: TextStyle(
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(MetasController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de Metas',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        SizedBox(height: 16.h),
        FutureBuilder<QuerySnapshot>(
          future: controller.obtenerTodasMetas(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard();
            }
            if (snapshot.hasError) {
              return _buildErrorCard('Error: ${snapshot.error}');
            }
            final metas = snapshot.data?.docs ?? [];
            if (metas.isEmpty) {
              return _buildEmptyCard('No hay metas registradas');
            }
            return Column(
              children: metas.map((doc) => _buildHistoryCard(doc, controller)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryCard(QueryDocumentSnapshot doc, MetasController controller) {
    final meta = doc.data() as Map<String, dynamic>;
    final turno = TurnoType.values.firstWhere((t) => t.name == meta['turno']);
    final inicio = (meta['fechaInicio'] as Timestamp).toDate();
    final fin = (meta['fechaFin'] as Timestamp).toDate();
    final numeroMeta = meta['numeroMeta'] as double;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<bool>(
        future: controller.verificarMetaPorRango(numeroMeta, turno, inicio, fin),
        builder: (context, snapCumplida) {
          final cumplida = snapCumplida.data ?? false;
          return Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: (cumplida ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  cumplida ? Icons.check_circle : Icons.cancel,
                  color: cumplida ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 20.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meta: ${numeroMeta.toInt()} pasajeros',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'Turno: ${turno.label}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      '${inicio.day}/${inicio.month}/${inicio.year} - ${fin.day}/${fin.month}/${fin.year}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: cumplida ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  cumplida ? 'Completada' : 'No completada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: Icon(Icons.delete_outline, color: const Color(0xFFEF4444), size: 20.w),
                onPressed: () => _eliminarMeta(doc.id, controller),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(40.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 32.w,
              height: 32.w,
              child: const CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Cargando datos...',
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEF4444)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: const Color(0xFFEF4444), size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: const Color(0xFFEF4444),
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: EdgeInsets.all(40.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: const Color(0xFF94A3B8), size: 48.w),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyle(
                color: const Color(0xFF64748B),
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _obtenerEstadoSemanaActual(MetasController controller) async {
    final estados = <Map<String, dynamic>>[];
    for (final turno in TurnoType.values) {
      try {
        final cumplida = await controller.verificarMetaSemanal(turno);
        final pasajeros = await controller.obtenerSumaPasajerosSemanaActual(turno);
        final meta = await controller.obtenerMetaSemanaActual(turno);
        estados.add({
          'turno': turno.label,
          'pasajeros': pasajeros,
          'meta': meta ?? 0,
          'cumplida': cumplida,
        });
      } catch (e) {
        debugPrint('Error obteniendo estado para $turno: $e');
      }
    }
    debugPrint('Estados obtenidos: $estados');
    return estados;
  }

  Future<void> _eliminarMeta(String id, MetasController controller) async {
    try {
      await controller.eliminarMeta(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check, color: Colors.white, size: 16.w),
              SizedBox(width: 12.w),
              const Text('Meta eliminada exitosamente'),
            ],
          ),
          backgroundColor: const Color(0xFF1E3A8A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20.w),
              SizedBox(width: 12.w),
              Text('Error: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
    }
  }
}
