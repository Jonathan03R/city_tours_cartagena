import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart' hide AgenciaConReservas;
import 'package:citytourscartagena/core/mvvc/agencias_controller.dart'; // Importar el nuevo AgenciasController
import 'package:citytourscartagena/core/mvvc/reservas_controller.dart'; // Importar ReservasController
import 'package:citytourscartagena/core/utils/formatters.dart'; // Importar Formatters
import 'package:citytourscartagena/core/widgets/crear_agencia_form.dart';
import 'package:citytourscartagena/screens/reservas_view.dart';
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

  @override
  void initState() {
    super.initState();
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
    final agenciasController = Provider.of<AgenciasController>(context, listen: false);
    await agenciasController.softDeleteAgencias(_selectedIds); // Delegar al controlador
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final agenciasController = context.watch<AgenciasController>();
    final reservasController = context.watch<ReservasController>(); // Observar ReservasController

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
        backgroundColor: Colors.green.shade600,
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
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: StreamBuilder<List<AgenciaConReservas>>(
                      stream: agenciasController.agenciasConReservasStream,
                      builder: (context, snapshot) {
                        final agencias = snapshot.data ?? [];
                        return Text(
                          '${agencias.length} agencia${agencias.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.green.shade700,
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
                if (agenciasSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (agenciasSnapshot.hasError) {
                  return Center(child: Text('Error: ${agenciasSnapshot.error}'));
                }
                final agencias = agenciasSnapshot.data ?? [];

                if (agencias.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
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
                    if (allReservasSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (allReservasSnapshot.hasError) {
                      return Center(child: Text('Error cargando todas las reservas: ${allReservasSnapshot.error}'));
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
                      itemCount: agencias.length,
                      itemBuilder: (context, index) {
                        final agencia = agencias[index];
                        final selected = _selectedIds.contains(agencia.id);

                        // Calcular la deuda de la agencia usando TODAS las reservas
                        final totalDeuda = allReservas
                            .where((reservaConAgencia) => reservaConAgencia.agencia.id == agencia.id)
                            .fold<double>(0.0, (sum, reservaConAgencia) => sum + reservaConAgencia.reserva.deuda);

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
                            color: selected ? Colors.blue.shade50 : Colors.white,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (agencia.imagenUrl != null &&
                                            agencia.imagenUrl!.isNotEmpty)
                                          CircleAvatar(
                                            radius: 50,
                                            backgroundColor: Colors.grey.shade200,
                                            backgroundImage: NetworkImage(
                                              agencia.imagenUrl!,
                                            ),
                                          )
                                        else
                                          CircleAvatar(
                                            radius: 50,
                                            backgroundColor: Colors.green.shade100,
                                            child: Icon(
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
                                            color: totalDeuda > 0 ? Colors.red.shade50 : Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Deuda: ${Formatters.formatCurrency(totalDeuda)}',
                                            style: TextStyle(
                                              color: totalDeuda > 0 ? Colors.red.shade700 : Colors.green.shade700,
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
        onCrear: (nombre, imagenFile, precioPorAsiento) async {
          final agenciasController = Provider.of<AgenciasController>(context, listen: false);
          await agenciasController.addAgencia(nombre, imagenFile?.path, precioPorAsiento: precioPorAsiento);
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
