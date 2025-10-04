import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WidgetControlesPrecios extends StatelessWidget {
  final List<dynamic> reservasActuales;
  final String textoReservas;
  final String textoBotonExportar;
  final bool tieneSelecciones;
  final bool puedeExportar;
  final VoidCallback? alPresionarExportar;

  final double? precioManana;
  final String origenManana; 
  final double? precioTarde;
  final String origenTarde; 
  final String? filtroTurno;
  final bool puedeEditarPrecios;
  final Function(String turno, double precio)? alGuardarPrecioGlobal;
  final Function(double? precioManana, double? precioTarde)? alGuardarPrecioAgencia;

  const WidgetControlesPrecios({
    super.key,
    required this.reservasActuales,
    required this.textoReservas,
    required this.textoBotonExportar,
    required this.tieneSelecciones,
    required this.puedeExportar,
    this.alPresionarExportar,
    required this.precioManana,
    required this.origenManana,
    required this.precioTarde,
    required this.origenTarde,
    this.filtroTurno,
    this.puedeEditarPrecios = false,
    this.alGuardarPrecioGlobal,
    this.alGuardarPrecioAgencia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.h),
      margin: EdgeInsets.symmetric(horizontal: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirFilaEncabezado(),
          SizedBox(height: 12.h),
          _construirSeccionPrecios(),
        ],
      ),
    );
  }

  Widget _construirFilaEncabezado() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          textoReservas,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: tieneSelecciones ? Colors.blue.shade700 : Colors.black,
          ),
        ),
        if (puedeExportar)
          ElevatedButton.icon(
            onPressed: alPresionarExportar,
            icon: Icon(
              tieneSelecciones ? Icons.file_download_outlined : Icons.file_download,
              size: 24.w,
            ),
            label: Text(textoBotonExportar),
            style: ElevatedButton.styleFrom(
              backgroundColor: tieneSelecciones ? Colors.blue.shade600 : Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _construirSeccionPrecios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Precios por Asiento',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 8.h),
        _construirTarjetasPrecios(),
      ],
    );
  }

  Widget _construirTarjetasPrecios() {
    return Row(
      children: [
        Expanded(
          child: _construirTarjetaPrecio(
            'Mañana',
            precioManana,
            origenManana,
            filtroTurno == 'manana',
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _construirTarjetaPrecio(
            'Tarde',
            precioTarde,
            origenTarde,
            filtroTurno == 'tarde',
          ),
        ),
      ],
    );
  }

  Widget _construirTarjetaPrecio(
    String turno,
    double? precio,
    String origen,
    bool esTurnoActivo,
  ) {
    final esEspecial = origen == 'especial';
    final precioMostrar = precio ?? 0.0;
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: esTurnoActivo ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: esTurnoActivo ? Colors.blue.shade300 : Colors.grey.shade300,
          width: esTurnoActivo ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                turno,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: esTurnoActivo ? Colors.blue.shade700 : Colors.grey.shade700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: esEspecial ? Colors.orange.shade100 : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  esEspecial ? 'Especial' : 'Global',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: esEspecial ? Colors.orange.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '\$${precioMostrar.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: esEspecial ? Colors.orange.shade600 : Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
