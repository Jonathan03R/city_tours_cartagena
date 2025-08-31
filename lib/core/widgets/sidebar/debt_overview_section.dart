import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class DebtOverviewSection extends StatelessWidget {
  final bool isVisible;

  const DebtOverviewSection({
    super.key,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ReservasController>(
      builder: (_, resCtrl, __) {
        return StreamBuilder<List<ReservaConAgencia>>(
          stream: resCtrl.getAllReservasConAgenciaStream(),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            
            final all = snap.data!;
            final unpaid = all.where((ra) => ra.reserva.estado != EstadoReserva.pagada).toList();
            final totalDebt = unpaid.fold<double>(0.0, (sum, ra) => sum + ra.reserva.deuda); // Incluye futuro

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final unpaidUntilToday = unpaid.where((ra) => ra.reserva.fecha.isBefore(today.add(const Duration(days: 1)))).toList();
            final totalDebtUntilToday = unpaidUntilToday.fold<double>(0.0, (sum, ra) => sum + ra.reserva.deuda);

            final currentMonthStart = DateTime(now.year, now.month, 1);
            final currentMonthEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
            final unpaidThisMonth = unpaid.where((ra) => ra.reserva.fecha.isAfter(currentMonthStart.subtract(const Duration(days: 1))) && ra.reserva.fecha.isBefore(currentMonthEnd.add(const Duration(days: 1)))).toList();
            final totalDebtThisMonth = unpaidThisMonth.fold<double>(0.0, (sum, ra) => sum + ra.reserva.deuda);


            final Map<String, double> agencyDebtMap = {};
            final Map<String, Agencia> agencyById = {};
            
            for (var ra in unpaid) {
              agencyById[ra.agencia.id] = ra.agencia;
              agencyDebtMap.update(
                ra.agencia.id,
                (prev) => prev + ra.reserva.deuda,
                ifAbsent: () => ra.reserva.deuda,
              );
            }
            
            final filteredAgencies = agencyDebtMap.entries
                .where((e) => e.value != 0)
                .map((e) => MapEntry(agencyById[e.key]!, e.value))
                .toList();
            filteredAgencies.sort((a, b) => b.value.compareTo(a.value));

            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
              height: isVisible ? null : 0,
              child: AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFD32F2F).withOpacity(0.08),
                        const Color(0xFFE57373).withOpacity(0.12),
                        const Color(0xFFFF8A65).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE57373).withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD32F2F).withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header de deuda total
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Deuda Total - Lo más prominente
                                Container(
                                  margin: EdgeInsets.only(bottom: 16.h),
                                  padding: EdgeInsets.all(20.r),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [const Color(0xFFD32F2F), const Color(0xFFE57373)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD32F2F).withOpacity(0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet, // Movido aquí para mejor diseño
                                        color: Colors.white,
                                        size: 32.sp,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Deuda Total',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                color: Colors.white.withOpacity(0.9),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              Formatters.formatCurrency(totalDebt),
                                              style: TextStyle(
                                                fontSize: 24.sp,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Otras deudas en fila, más pequeñas y discretas
                                Row(
                                  children: [
                                    // Deuda Hasta Hoy
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(right: 8.w),
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFE57373).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.today,
                                              color: const Color(0xFFE57373),
                                              size: 20.sp,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Hasta Hoy',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: const Color(0xFF37474F),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              Formatters.formatCurrency(totalDebtUntilToday),
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFE57373),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Deuda Este Mes
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(left: 8.w),
                                        padding: EdgeInsets.all(12.r),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: const Color(0xFFFF8A65).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.calendar_month,
                                              color: const Color(0xFFFF8A65),
                                              size: 20.sp,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Este Mes',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: const Color(0xFF37474F),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              Formatters.formatCurrency(totalDebtThisMonth),
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFFFF8A65),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (filteredAgencies.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        // Título de desglose
                        Row(
                          children: [
                            Container(
                              width: 4.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Desglose por Agencia',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF37474F),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 8.h),
                        // Lista de agencias
                        
                          SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: filteredAgencies.map((entry) {
                                final Agencia agencia = entry.key;
                                final double deuda = entry.value;
                                final badgeColor = deuda > 0 ? const Color(0xFFD32F2F) : const Color(0xFF388E3C);
                                
                                return InkWell(
                                  onTap: () {
                                    // Navegar a ReservasView con el modelo AgenciaConReservas
                                    final agenciaCon = Provider.of<AgenciasController>(context, listen: false)
                                        .agencias
                                        .firstWhere((ar) => ar.agencia.id == agencia.id);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ReservasView(
                                          agencia: agenciaCon,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  padding: EdgeInsets.all(12.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: badgeColor.withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: badgeColor.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Avatar de agencia
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: badgeColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundImage: agencia.imagenUrl != null
                                              ? NetworkImage(agencia.imagenUrl!)
                                              : null,
                                          backgroundColor: badgeColor,
                                          child: agencia.imagenUrl == null
                                              ? Text(
                                                  agencia.nombre[0].toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 16.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      
                                      const SizedBox(width: 16),
                                      
                                      // Información de agencia
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              agencia.nombre,
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF37474F),
                                                letterSpacing: 0.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '\$${Formatters.formatCurrency(deuda)}',
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w800,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Indicador de estado
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          deuda > 0 ? Icons.trending_up : Icons.trending_down,
                                          color: badgeColor,
                                          size: 16.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ), // close Container
                              ); // close InkWell
                              }).toList(),
                            ),
                          ),
                        
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
