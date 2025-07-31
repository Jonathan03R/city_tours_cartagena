import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart'
    hide AgenciaConReservas;
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/crear_agencia_form.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgenciasView extends StatefulWidget {
  final String searchTerm; // Recibir el término de búsqueda desde MainScreen
  
  const AgenciasView({super.key, this.searchTerm = ''});

  @override
  State<AgenciasView> createState() => _AgenciasViewState();
}

class _AgenciasViewState extends State<AgenciasView> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      _selectionMode = _selectedIds.isNotEmpty;
    });
  }

  Future<void> _deleteSelected() async {
    final agenciasController = Provider.of<AgenciasController>(
      context,
      listen: false,
    );
    await agenciasController.softDeleteAgencias(_selectedIds);
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agenciasController = context.watch<AgenciasController>();
    final reservasController = context.watch<ReservasController>();
    final authController = context.read<AuthController>();

    return Scaffold(
      body: Column(
        children: [
          // Header solo para modo selección
          if (_selectionMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
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
                    onPressed: _deleteSelected,
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: StreamBuilder<List<AgenciaConReservas>>(
              stream: agenciasController.agenciasConReservasStream,
              builder: (context, agenciasSnapshot) {
                if (agenciasSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (agenciasSnapshot.hasError) {
                  return Center(
                    child: Text('Error: ${agenciasSnapshot.error}'),
                  );
                }
                final agencias = agenciasSnapshot.data ?? [];
                
                // Filtrar agencias según término de búsqueda desde MainScreen
                final filteredAgencias = widget.searchTerm.isEmpty
                    ? agencias
                    : agencias
                        .where((a) => a.nombre
                            .toLowerCase()
                            .contains(widget.searchTerm.toLowerCase()))
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
                  return const Center(
                    child: Text(
                      'No se encontraron agencias',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return StreamBuilder<List<ReservaConAgencia>>(
                  stream: reservasController.getAllReservasConAgenciaStream(),
                  builder: (context, allReservasSnapshot) {
                    if (allReservasSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (allReservasSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error cargando todas las reservas: ${allReservasSnapshot.error}',
                        ),
                      );
                    }
                    final allReservas = allReservasSnapshot.data ?? [];

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.83,
                      ),
                      itemCount: filteredAgencias.length,
                      itemBuilder: (context, index) {
                        final agencia = filteredAgencias[index];
                        final selected = _selectedIds.contains(agencia.id);
                        
                        final totalDeuda = allReservas
                            .where(
                              (rca) =>
                                  rca.agencia.id == agencia.id &&
                                  rca.reserva.estado != EstadoReserva.pagada,
                            )
                            .fold<double>(
                              0.0,
                              (sum, rca) => sum + rca.reserva.deuda,
                            );

                        return GestureDetector(
                          onLongPress: () => _toggleSelection(agencia.id),
                          onTap: () {
                            if (_selectionMode) {
                              _toggleSelection(agencia.id);
                            } else {
                              _navigateToAgenciaReservas(agencia);
                            }
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: selected
                                  ? BorderSide(
                                      color: Colors.blue.shade400,
                                      width: 2,
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
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors.grey.shade200,
                                          child: (agencia.imagenUrl != null &&
                                              agencia.imagenUrl!.isNotEmpty)
                                              ? ClipOval(
                                                  child: Image.network(
                                                    agencia.imagenUrl!,
                                                    fit: BoxFit.cover,
                                                    width: 100,
                                                    height: 100,
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
                                                        size: 50,
                                                        color: Colors.green.shade600,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.business,
                                                  size: 50,
                                                  color: Colors.green.shade600,
                                                ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          agencia.nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
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
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${agencia.totalReservas} reservas',
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 8,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        authController.hasPermission(Permission.ver_deuda_agencia)
                                            ? Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: totalDeuda > 0
                                                      ? Colors.red.shade50
                                                      : Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  'Deuda: ${Formatters.formatCurrency(totalDeuda)}',
                                                  style: TextStyle(
                                                    color: totalDeuda > 0
                                                        ? Colors.red.shade700
                                                        : Colors.green.shade700,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 8,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                        // Container(
                                        //   padding: const EdgeInsets.symmetric(
                                        //     horizontal: 12,
                                        //     vertical: 6,
                                        //   ),
                                        //   decoration: BoxDecoration(
                                        //     color: totalDeuda > 0
                                        //         ? Colors.red.shade50
                                        //         : Colors.green.shade50,
                                        //     borderRadius: BorderRadius.circular(20),
                                        //   ),
                                        //   child: Text(
                                        //     'Deuda: ${Formatters.formatCurrency(totalDeuda)}',
                                        //     style: TextStyle(
                                        //       color: totalDeuda > 0
                                        //           ? Colors.red.shade700
                                        //           : Colors.green.shade700,
                                        //       fontWeight: FontWeight.w600,
                                        //       fontSize: 8,
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (selected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: authController.hasPermission(Permission.crear_agencias)
          ? FloatingActionButton(
              onPressed: _mostrarFormularioAgregarAgencia,
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _mostrarFormularioAgregarAgencia() {
    showDialog(
      context: context,
      builder: (_) => CrearAgenciaForm(
        onCrear: (nombre, imagenFile, precioManana, precioTarde, tipoDocumento, numeroDocumento, nombreBeneficiario) async {
          final agenciasController = Provider.of<AgenciasController>(
            context,
            listen: false,
          );
          await agenciasController.addAgencia(
            nombre,
            imagenFile?.path,
            precioPorAsientoTurnoManana: precioManana,
            precioPorAsientoTurnoTarde: precioTarde,
            tipoDocumento: tipoDocumento,
            numeroDocumento: numeroDocumento,
            nombreBeneficiario: nombreBeneficiario,
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _navigateToAgenciaReservas(AgenciaConReservas agencia) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReservasView(agencia: agencia),
      ),
    );
  }
}
