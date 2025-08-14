import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/widgets/agency_header_whatsapp_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class AgencyHeaderWidget extends StatefulWidget {
  final AgenciaConReservas agencia;
  final ReservasController reservasController;

  const AgencyHeaderWidget({
    super.key,
    required this.agencia,
    required this.reservasController,
  });

  @override
  State<AgencyHeaderWidget> createState() => _AgencyHeaderWidgetState();
}

class _AgencyHeaderWidgetState extends State<AgencyHeaderWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shadowPulse; // controla intensidad de sombras

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 380), // más rápido
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 450), // pulso más veloz
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,  // escala de entrada sutil
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack, // golpe rápido con un pequeño overshoot
      ),
    );

    // Fade más ágil (termina al 60% del tiempo de entrada)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 0.985, // escala sutil
      end: 1.015,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic, // pulso fluido
      ),
    );

    _shadowPulse = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _animationController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configuracion = Provider.of<ConfiguracionController>(
      context,
      listen: false,
    ).configuracion;
    
    final turno = widget.reservasController.turnoFilter;
    final hoy = DateTime.now();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.blue.shade50.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildResponsiveContent(constraints, configuracion, turno, hoy);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsiveContent(BoxConstraints constraints, configuracion, turno, hoy) {
    final isSmall = constraints.maxWidth < 400.w;
    
    if (isSmall) {
      return _buildCompactLayout(configuracion, turno, hoy);
    } else {
      return _buildNormalLayout(configuracion, turno, hoy);
    }
  }

  Widget _buildNormalLayout(configuracion, turno, hoy) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          _buildProfessionalAvatar(),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildAgencyInfo(),
          ),
          SizedBox(width: 16.w),
          _buildWhatsAppButton(configuracion, turno, hoy),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(configuracion, turno, hoy) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              _buildProfessionalAvatar(isCompact: true),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildAgencyInfo(isCompact: true),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildWhatsAppButton(configuracion, turno, hoy, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildProfessionalAvatar({bool isCompact = false}) {
    final radius = isCompact ? 32.r : 40.r;
    final iconSize = isCompact ? 32.r : 40.r;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius + 4.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade50,
            Colors.green.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(4.w),
      child: _buildAvatarContent(radius, iconSize),
    );
  }

  Widget _buildAvatarContent(double radius, double iconSize) {
    if (widget.agencia.imagenUrl != null && widget.agencia.imagenUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            widget.agencia.imagenUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(radius, iconSize);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingAvatar(radius);
            },
          ),
        ),
      );
    } else {
      return _buildDefaultAvatar(radius, iconSize);
    }
  }

  Widget _buildDefaultAvatar(double radius, double iconSize) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.green.shade100,
      child: Icon(
        Icons.business,
        size: iconSize,
        color: Colors.green.shade600,
      ),
    );
  }

  Widget _buildLoadingAvatar(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: SizedBox(
        width: radius,
        height: radius,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.green.shade600,
        ),
      ),
    );
  }

  Widget _buildAgencyInfo({bool isCompact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.agencia.nombre,
          style: TextStyle(
            fontSize: isCompact ? 18.sp : 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            height: 1.2,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: isCompact ? 1 : 2,
        ),
        SizedBox(height: 4.h),
        _buildReservasInfo(isCompact),
        if (!isCompact) ...[
          SizedBox(height: 8.h),
          _buildAgencyStats(),
        ],
      ],
    );
  }

  Widget _buildReservasInfo(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_note,
            size: isCompact ? 14.sp : 16.sp,
            color: Colors.blue.shade600,
          ),
          SizedBox(width: 4.w),
          Text(
            '${widget.agencia.totalReservas} reserva${widget.agencia.totalReservas != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: isCompact ? 12.sp : 14.sp,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyStats() {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        SizedBox(width: 8.w),
        _buildStatChip(
          icon: Icons.verified,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, size: 12.sp, color: color),
    );
  }

  Widget _buildWhatsAppButton(configuracion, turno, hoy, {bool isCompact = false}) {
    return FutureBuilder<bool>(
      future: widget.reservasController.shouldShowWhatsAppButton(
        turno: turno,
        fecha: hoy,
      ),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingButton(isCompact);
        }
        
        if (snap.hasData && snap.data == true) {
          final whatsapp = configuracion?.contact_whatsapp ?? '';
          return _buildActiveWhatsAppButton(whatsapp, isCompact);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingButton(bool isCompact) {
    return Container(
      height: isCompact ? 36.h : 42.h,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12.w : 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.red.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 18.r : 21.r),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: isCompact ? 16.w : 20.w,
            height: isCompact ? 16.h : 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Verificando...',
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 11.sp : 13.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWhatsAppButton(String whatsapp, bool isCompact) {
    // Usar el widget que sí ejecuta la acción al hacer click
    return VerifyAvailabilityTag(
      telefonoRaw: whatsapp,
      message: 'Hola, soy de ${widget.agencia.nombre}. ¿Hay disponibilidad para el turno de hoy?',
      tooltip: 'Verificar disponibilidad hoy',
      compact: isCompact,
    );
  }
}
