import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/screens/agencias/widget/reserva_prueba.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AgenciasSeccion extends StatefulWidget {
  final Future<List<AgenciaSupabase>> agenciasFuture;
  final String searchTerm;

  const AgenciasSeccion({
    super.key,
    required this.agenciasFuture,
    required this.searchTerm,
  });

  @override
  State<AgenciasSeccion> createState() => _AgenciasSeccionState();
}

class _AgenciasSeccionState extends State<AgenciasSeccion> {
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  final bool _isDark = false;


  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectionMode = _selectedIds.isNotEmpty;
    });
  }


  void _navigateToAgenciaReservas(int codigoAgencia) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservaDetalles(codigoAgencia: codigoAgencia)
      ),
      // MaterialPageRoute(
      //   builder: (_) => ReservasView(codigoAgencia: codigoAgencia),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_selectionMode)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.getAccentColor(_isDark),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightSecondary,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),

              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectionMode = false;
                        _selectedIds.clear();
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      '${_selectedIds.length} seleccionada${_selectedIds.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      //falta logica para eliminar
                    },
                  ),
                ],
              ),
            ),

          Expanded(
            child: FutureBuilder<List<AgenciaSupabase>>(
              future: widget.agenciasFuture,
              builder: (context, agenciasSnapshot) {
                if (agenciasSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (agenciasSnapshot.hasError) {
                  return Center(
                    child: Text('Error: ${agenciasSnapshot.error}'),
                  );
                }
                final agencias = agenciasSnapshot.data ?? [];

                final filteredAgencias = widget.searchTerm.isEmpty
                    ? agencias
                    : agencias
                          .where(
                            (a) => a.nombre.toLowerCase().contains(
                              widget.searchTerm.toLowerCase(),
                            ),
                          )
                          .toList();
                if (agencias.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay agencias registradas',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                if (filteredAgencias.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron agencias',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                    ),
                  );
                }
                // final allReservas = allReservasSnapshot.data ?? [];

                return GridView.builder(
                  padding: EdgeInsets.all(16.sp),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.83,
                  ),
                  itemCount: filteredAgencias.length,
                  itemBuilder: (context, index){
                    final agencia = filteredAgencias[index];
                    final selected = _selectedIds.contains(agencia.codigo);

                    return GestureDetector(
                      onLongPress: () => _toggleSelection(agencia.codigo),
                      onTap: () {
                        if (_selectionMode) {
                          _toggleSelection(agencia.codigo);
                        } else {
                          _navigateToAgenciaReservas(agencia.codigo);
                        }
                      },
                      child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              side: selected
                                  ? BorderSide(
                                      color: Colors.blue.shade400,
                                      width: 2.w,
                                    )
                                  : BorderSide.none,
                            ),
                            color: selected
                                ? Colors.blue.shade50
                                : Colors.white,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.sp),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 40.r,
                                          backgroundColor: Colors.grey.shade200,
                                          child: (agencia.logoUrl != null &&
                                              agencia.logoUrl!.isNotEmpty)
                                              ? ClipOval(
                                                  child: Image.network(
                                                    agencia.logoUrl!,
                                                    fit: BoxFit.cover,
                                                    width: 100.w,
                                                    height: 100.h,
                                                    loadingBuilder: (
                                                      BuildContext context,
                                                      Widget child,
                                                      ImageChunkEvent? loadingProgress,
                                                    ) {
                                                      if (loadingProgress == null) {
                                                        return child;
                                                      }
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                          color: Colors.green.shade600,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Icon(
                                                        Icons.business,
                                                        size: 50.r,
                                                        color: Colors.green.shade600,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.business,
                                                  size: 50.r,
                                                  color: Colors.green.shade600,
                                                ),
                                        ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          agencia.nombre,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10.h,
                                                vertical: 5.w,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${agencia.totalReservas} reservas',
                                                style: TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10.sp,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 4.h),
                                        // authController.hasPermission(Permission.ver_deuda_agencia)
                                            Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10.h,
                                                  vertical: 5.w,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: agencia.deuda > 0
                                                      ? Colors.red.shade50
                                                      : Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'Deuda: ${Formatters.formatCurrency(agencia.deuda)}',
                                                  style: TextStyle(
                                                    color: agencia.totalReservas > 0
                                                        ? Colors.red.shade700
                                                        : Colors.green.shade700,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 10.sp,
                                                  ),
                                                ),
                                              )
                                            // : const SizedBox.shrink(),
                                      ],
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 24.sp,
                                    ),
                                  ),
                              ],
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
