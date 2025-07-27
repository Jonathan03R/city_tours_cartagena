import 'dart:async'; // Importar para StreamSubscription

import 'package:citytourscartagena/core/controller/agencias_controller.dart'; // Importar el nuevo AgenciasController
import 'package:citytourscartagena/core/controller/reservas_controller.dart'; // Importar ReservasController
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart'
    hide AgenciaConReservas;
import 'package:citytourscartagena/core/utils/formatters.dart'; // Importar Formatters
import 'package:citytourscartagena/core/widgets/crear_agencia_form.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Necesario para consumir el controlador

class AgenciasView extends StatefulWidget {
  const AgenciasView({super.key});

  @override
  State<AgenciasView> createState() => _AgenciasViewState();
}

class _AgenciasViewState extends State<AgenciasView> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  // Eliminado: StreamSubscription<List<AgenciaConReservas>>? _agenciasSubscription; // Suscripción para precarga

  @override
  void initState() {
    super.initState();
    // Eliminado: WidgetsBinding.instance.addPostFrameCallback((_) {
    // Eliminado:   _setupImagePreloading();
    // Eliminado: });
  }

  @override
  void dispose() {
    // Eliminado: _agenciasSubscription?.cancel(); // Cancelar la suscripción al salir
    super.dispose();
  }

  // Eliminado: void _setupImagePreloading() {
  // Eliminado:   final agenciasController = Provider.of<AgenciasController>(context, listen: false);
  // Eliminado:   _agenciasSubscription = agenciasController.agenciasConReservasStream.listen((agencias) {
  // Eliminado:     _precacheAgencyImages(agencias);
  // Eliminado:   }, onError: (error) {
  // Eliminado:     debugPrint('Error en el stream de agencias para precarga: $error');
  // Eliminado:   });
  // Eliminado: }

  // Eliminado: void _precacheAgencyImages(List<AgenciaConReservas> agencias) {
  // Eliminado:   for (var agencia in agencias) {
  // Eliminado:     if (agencia.imagenUrl != null && agencia.imagenUrl!.isNotEmpty) {
  // Eliminado:       try {
  // Eliminado:         precacheImage(NetworkImage(agencia.imagenUrl!), context);
  // Eliminado:         debugPrint('✅ Precargando imagen de agencia: ${agencia.nombre}');
  // Eliminado:       } catch (e) {
  // Eliminado:         debugPrint('❌ Error precargando imagen de ${agencia.nombre}: $e');
  // Eliminado:       }
  // Eliminado:     }
  // Eliminado:   }
  // Eliminado: }

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
    await agenciasController.softDeleteAgencias(
      _selectedIds,
    ); // Delegar al controlador
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agenciasController = context.watch<AgenciasController>();
    final reservasController = context
        .watch<ReservasController>(); // Observar ReservasController

    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectionMode = false;
                    _selectedIds.clear();
                  });
                },
              )
            : null,
        title: Text(
          _selectionMode
              ? '${_selectedIds.length} seleccionada(s)'
              : 'Agencias',
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
        ],
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total de Agencias',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: StreamBuilder<List<AgenciaConReservas>>(
                      stream: agenciasController.agenciasConReservasStream,
                      builder: (context, snapshot) {
                        final agencias = snapshot.data ?? [];
                        return Text(
                          '${agencias.length} agencia${agencias.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AgenciaConReservas>>(
              stream: agenciasController.agenciasConReservasStream,
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

                // NUEVO: StreamBuilder anidado para obtener TODAS las reservas
                return StreamBuilder<List<ReservaConAgencia>>(
                  stream: reservasController.getAllReservasConAgenciaStream(),
                  builder: (context, allReservasSnapshot) {
                    if (allReservasSnapshot.connectionState ==
                        ConnectionState.waiting) {
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.83,
                          ),
                      itemCount: agencias.length,
                      itemBuilder: (context, index) {
                        final agencia = agencias[index];
                        final selected = _selectedIds.contains(agencia.id);

                        // Calcular la deuda de la agencia usando TODAS las reservas
                        final totalDeuda = allReservas
                            .where(
                              (rca) =>
                                  rca.agencia.id == agencia.id &&
                                  rca.reserva.estado !=
                                      EstadoReserva.pagada, // ← excluye pagadas
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // MODIFICADO: Usar Image.network con loadingBuilder y errorBuilder
                                        CircleAvatar(
                                          radius: 50,
                                          backgroundColor: Colors
                                              .grey
                                              .shade200, // Fondo mientras carga
                                          child:
                                              (agencia.imagenUrl != null &&
                                                  agencia.imagenUrl!.isNotEmpty)
                                              ? ClipOval(
                                                  // Asegura que la imagen sea circular
                                                  child: Image.network(
                                                    agencia.imagenUrl!,
                                                    fit: BoxFit.cover,
                                                    width: 100, // 2 * radius
                                                    height: 100, // 2 * radius
                                                    loadingBuilder:
                                                        (
                                                          BuildContext context,
                                                          Widget child,
                                                          ImageChunkEvent?
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null) {
                                                            return child; // La imagen ya cargó
                                                          }
                                                          return Center(
                                                            child: CircularProgressIndicator(
                                                              value:
                                                                  loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                            .cumulativeBytesLoaded /
                                                                        loadingProgress
                                                                            .expectedTotalBytes!
                                                                  : null,
                                                              color: Colors
                                                                  .green
                                                                  .shade600, // Color del indicador
                                                            ),
                                                          );
                                                        },
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          // En caso de error al cargar la imagen, muestra el icono de negocio
                                                          return Icon(
                                                            Icons.business,
                                                            size: 50,
                                                            color: Colors
                                                                .green
                                                                .shade600,
                                                          );
                                                        },
                                                  ),
                                                )
                                              : Icon(
                                                  // Si no hay URL de imagen, muestra el icono de negocio
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                                            // if (agencia.precioPorAsiento != null) ...[
                                            //   const SizedBox(width: 8),
                                            //   Container(
                                            //     padding: const EdgeInsets.symmetric(
                                            //       horizontal: 10,
                                            //       vertical: 5,
                                            //     ),
                                            //     decoration: BoxDecoration(
                                            //       color: Colors.green.shade50,
                                            //       borderRadius: BorderRadius.circular(20),
                                            //     ),
                                            //     // child: Text(
                                            //     //   'Precio: ${Formatters.formatCurrency(agencia.precioPorAsiento!)}',
                                            //     //   style: TextStyle(
                                            //     //     fontSize: 13,
                                            //     //     color: Colors.green.shade700,
                                            //     //     fontWeight: FontWeight.w600,
                                            //     //   ),
                                            //     // ),
                                            //   ),
                                            // ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Mostrar total de deuda calculado al momento
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: totalDeuda > 0
                                                ? Colors.red.shade50
                                                : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
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
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (selected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Icon(
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
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioAgregarAgencia,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarFormularioAgregarAgencia() {
  showDialog(
    context: context,
    builder: (_) => CrearAgenciaForm(
      onCrear: (nombre, imagenFile, precioManana, precioTarde) async {
        final agenciasController = Provider.of<AgenciasController>(
          context,
          listen: false,
        );
        await agenciasController.addAgencia(
          nombre,
          imagenFile?.path,
          precioPorAsientoTurnoManana: precioManana,
          precioPorAsientoTurnoTarde: precioTarde,
        );
        Navigator.of(context).pop(); // Cerrar el diálogo
      },
    ),
  );
}

  void _navigateToAgenciaReservas(AgenciaConReservas agencia) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ReservasView(agencia: agencia)));
  }
}
