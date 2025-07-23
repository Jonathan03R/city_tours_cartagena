import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/mvvc/reservas_controller.dart';
import 'package:citytourscartagena/core/services/cloudinaryService.dart';
import 'package:citytourscartagena/core/services/firestore_service.dart';
import 'package:citytourscartagena/core/widgets/crear_agencia_form.dart';
import 'package:citytourscartagena/screens/reservas_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AgenciasView extends StatefulWidget {
  const AgenciasView({super.key});

  @override
  State<AgenciasView> createState() => _AgenciasViewState();
}

class _AgenciasViewState extends State<AgenciasView> {
  List<AgenciaConReservas> _agencias = [];
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadAgencias();
  }

  void _loadAgencias() {
    setState(() {
      _agencias = ReservasController.getAllAgencias();
    });
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
    for (var id in _selectedIds) {
      await FirebaseFirestore.instance.collection('agencias').doc(id).update({
        'eliminada': true,
      });
    }
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: StreamBuilder<List<AgenciaConReservas>>(
                    stream: ReservasController.getAgenciasStream(),
                    builder: (context, snapshot) {
                      final agencias = snapshot.data ?? [];
                      return Text(
                        '${agencias.length} agencia${agencias.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AgenciaConReservas>>(
              stream: ReservasController.getAgenciasStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final agencias = snapshot.data ?? [];
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

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio:
                        0.83, // Mantenemos el aspecto para consistencia
                  ),
                  itemCount: agencias.length,
                  itemBuilder: (context, index) {
                    final agencia = agencias[index];
                    final selected = _selectedIds.contains(agencia.id);
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
                            // Rejilla centrada con avatar, nombre y total de reservas
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
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
        onCrear: (nombre, imagen) async {
          String? imagenUrl;
          if (imagen != null) {
            imagenUrl = await CloudinaryService.uploadImage(imagen);
          }
          final nuevaAgencia = Agencia(
            id: '',
            nombre: nombre,
            imagenUrl: imagenUrl,
          );
          await FirestoreService().addAgencia(nuevaAgencia);
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
