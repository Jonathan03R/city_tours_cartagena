import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class EncabezadoAgenciaWidget extends StatelessWidget {
  final String nombreAgencia;
  final String? imagenUrlAgencia;
  final int agenciaId;
  final int operadorId;
  final int totalReservas;
  final int totalPasajeros;
  final double deuda;
  // Puedes agregar más campos si necesitas

  const EncabezadoAgenciaWidget({
    super.key,
    required this.nombreAgencia,
    this.imagenUrlAgencia,
    required this.agenciaId,
    required this.operadorId,
    required this.totalReservas,
    required this.totalPasajeros,
    required this.deuda,
  });

  @override
  Widget build(BuildContext context) {
    final configuracion = Provider.of<ConfiguracionController>(
      context,
      listen: false,
    ).configuracion;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: _construirDecoracionContenedor(),
      child: _construirContenidoResponsivo(configuracion),
    );
  }

  BoxDecoration _construirDecoracionContenedor() {
    return BoxDecoration(
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
    );
  }

  Widget _construirContenidoResponsivo(configuracion) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esCompacto = constraints.maxWidth < 400.w;
        if (esCompacto) {
          return _construirLayoutCompacto(configuracion);
        } else {
          return _construirLayoutNormal(configuracion);
        }
      },
    );
  }

  Widget _construirLayoutNormal(configuracion) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Row(
        children: [
          _construirAvatarProfesional(),
          SizedBox(width: 16.w),
          Expanded(
            child: _construirInformacionAgencia(),
          ),
          SizedBox(width: 16.w),
          _construirBotonWhatsApp(configuracion),
        ],
      ),
    );
  }

  Widget _construirLayoutCompacto(configuracion) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Row(
            children: [
              _construirAvatarProfesional(esCompacto: true),
              SizedBox(width: 12.w),
              Expanded(
                child: _construirInformacionAgencia(esCompacto: true),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _construirEstadisticasReservas(esCompacto: true),
          SizedBox(height: 8.h),
          _construirBotonWhatsApp(configuracion, esCompacto: true),
        ],
      ),
    );
  }

  Widget _construirAvatarProfesional({bool esCompacto = false}) {
    final radio = esCompacto ? 32.r : 40.r;
    final tamanoIcono = esCompacto ? 32.r : 40.r;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio + 4.r),
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
      child: _construirContenidoAvatar(radio, tamanoIcono),
    );
  }

  Widget _construirContenidoAvatar(double radio, double tamanoIcono) {
    if (imagenUrlAgencia != null && imagenUrlAgencia!.isNotEmpty) {
      return CircleAvatar(
        radius: radio,
        backgroundColor: Colors.grey.shade200,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radio),
          child: Image.network(
            imagenUrlAgencia!,
            width: radio * 2,
            height: radio * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _construirAvatarPorDefecto(radio, tamanoIcono);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _construirAvatarCargando(radio);
            },
          ),
        ),
      );
    } else {
      return _construirAvatarPorDefecto(radio, tamanoIcono);
    }
  }

  Widget _construirAvatarPorDefecto(double radio, double tamanoIcono) {
    return CircleAvatar(
      radius: radio,
      backgroundColor: Colors.green.shade100,
      child: Icon(
        Icons.business,
        size: tamanoIcono,
        color: Colors.green.shade600,
      ),
    );
  }

  Widget _construirAvatarCargando(double radio) {
    return CircleAvatar(
      radius: radio,
      backgroundColor: Colors.grey.shade200,
      child: SizedBox(
        width: radio,
        height: radio,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.green.shade600,
        ),
      ),
    );
  }

  Widget _construirInformacionAgencia({bool esCompacto = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombreAgencia,
          style: TextStyle(
            fontSize: esCompacto ? 18.sp : 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            height: 1.2,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: esCompacto ? 1 : 2,
        ),
        SizedBox(height: 4.h),
        _construirInformacionReservas(esCompacto),
        if (!esCompacto) ...[ 
          SizedBox(height: 8.h),
          _construirEstadisticasReservas(),
        ],
      ],
    );
  }

  Widget _construirInformacionReservas(bool esCompacto) {
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
            size: esCompacto ? 14.sp : 16.sp,
            color: Colors.blue.shade600,
          ),
          SizedBox(width: 4.w),
          Text(
            '$totalReservas reserva${totalReservas != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: esCompacto ? 12.sp : 14.sp,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEstadisticasReservas({bool esCompacto = false}) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 4.h,
      children: [
        // _construirChipEstadistica(
        //   icono: Icons.people,
        //   etiqueta: 'Pasajeros',
        //   valor: totalPasajeros.toString(),
        //   color: Colors.blue,
        //   esCompacto: esCompacto,
        // ),
        if (deuda > 0)
          _construirChipEstadistica(
            icono: Icons.warning,
            etiqueta: 'Deuda',
            valor: deuda.toStringAsFixed(2),
            color: Colors.orange,
            esCompacto: esCompacto,
          ),
      ],
    );
  }

  Widget _construirChipEstadistica({
    required IconData icono,
    required String etiqueta,
    required String valor,
    required Color color,
    bool esCompacto = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: esCompacto ? 6.w : 8.w,
        vertical: esCompacto ? 2.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: esCompacto ? 12.sp : 14.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            '$etiqueta: $valor',
            style: TextStyle(
              fontSize: esCompacto ? 10.sp : 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotonWhatsApp(configuracion, {bool esCompacto = false}) {
    final whatsapp = configuracion?.contact_whatsapp ?? '';
    if (whatsapp.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(esCompacto ? 20.r : 25.r),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(esCompacto ? 20.r : 25.r),
          onTap: () => _abrirWhatsApp(whatsapp),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: esCompacto ? 12.w : 16.w,
              vertical: esCompacto ? 8.h : 12.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.message,
                  color: Colors.white,
                  size: esCompacto ? 16.sp : 20.sp,
                ),
                if (!esCompacto) ...[
                  SizedBox(width: 8.w),
                  Text(
                    'Contactar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirWhatsApp(String numeroTelefono) {
    final mensaje = Uri.encodeComponent(
      'Hola, soy de $nombreAgencia. ¿Hay disponibilidad para reservas hoy?'
    );
    // Aquí implementarías la lógica para abrir WhatsApp
    // Por ejemplo, usando url_launcher
    print('Abrir WhatsApp: $numeroTelefono con mensaje: $mensaje');
  }
}
