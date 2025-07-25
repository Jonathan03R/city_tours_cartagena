import 'dart:async'; // Importar para StreamSubscription

import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importar Provider

import '../mvvc/agencias_controller.dart'; // Importar AgenciasController

class AgenciaSelector extends StatefulWidget {
  final String? selectedAgenciaId;
  final Function(String) onAgenciaSelected;
  const AgenciaSelector({
    super.key,
    this.selectedAgenciaId,
    required this.onAgenciaSelected,
  });

  @override
  State<AgenciaSelector> createState() => _AgenciaSelectorState();
}

class _AgenciaSelectorState extends State<AgenciaSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<AgenciaConReservas> _filteredAgencias = [];
  List<AgenciaConReservas> _allAgencias = [];
  bool _showAddForm = false;
  bool _isLoading = false;
  bool _isAddingAgencia = false;
  final TextEditingController _newAgenciaController = TextEditingController();

  // Suscripción al stream del controlador
  StreamSubscription<List<AgenciaConReservas>>? _agenciasSubscription;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para asegurar que el contexto esté disponible para Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToAgencias();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newAgenciaController.dispose();
    _agenciasSubscription?.cancel(); // Cancelar la suscripción para evitar fugas de memoria
    super.dispose();
  }

  void _listenToAgencias() {
    setState(() {
      _isLoading = true;
    });
    final agenciasController = Provider.of<AgenciasController>(context, listen: false);

    // Escuchar el stream de agencias del controlador
    _agenciasSubscription = agenciasController.agenciasConReservasStream.listen((data) {
      setState(() {
        _allAgencias = data;
        _filterAgencias(_searchController.text); // Reaplicar filtro con los nuevos datos
        _isLoading = false;
      });
    }, onError: (error) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error cargando agencias en AgenciaSelector: $error');
      // Opcional: mostrar un mensaje de error al usuario
    });
  }

  void _filterAgencias(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAgencias = List.from(_allAgencias);
      } else {
        _filteredAgencias = _allAgencias
            .where(
              (agencia) =>
                  agencia.nombre.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _addNewAgencia() async {
    if (_newAgenciaController.text.trim().isEmpty) return;
    setState(() {
      _isAddingAgencia = true;
    });
    try {
      final agenciasController = Provider.of<AgenciasController>(context, listen: false);
      // Llamar al método addAgencia del AgenciasController
      final newAgencia = await agenciasController.addAgencia(
        _newAgenciaController.text.trim(),
        null, // No se proporciona imagen para la adición rápida aquí
      );
      widget.onAgenciaSelected(newAgencia.id);
      _newAgenciaController.clear();
      // No es necesario llamar a _loadAgencias() aquí, el listener del stream ya actualizará _allAgencias
      setState(() {
        _showAddForm = false;
        _isAddingAgencia = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Agencia "${newAgencia.nombre}" agregada exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAddingAgencia = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error agregando agencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No es necesario observar AgenciasController aquí con context.watch,
    // ya que _allAgencias se actualiza mediante el listener del stream.
    final selectedAgencia = widget.selectedAgenciaId != null
        ? _allAgencias.firstWhere(
            (a) => a.id == widget.selectedAgenciaId,
            orElse: () => AgenciaConReservas(
              agencia: Agencia(
                id: '',
                nombre: 'Agencia no encontrada',
              ),
              totalReservas: 0,
            ), // Manejo de caso no encontrado
          )
        : null;
    return InkWell(
      onTap: () => _showAgenciaDialog(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 20,
                    color: selectedAgencia != null
                        ? Colors.blue.shade600
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedAgencia?.nombre ?? 'Seleccionar agencia...',
                          style: TextStyle(
                            color: selectedAgencia != null
                                ? Colors.black
                                : Colors.grey.shade600,
                            fontWeight: selectedAgencia != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                        if (selectedAgencia != null &&
                            selectedAgencia.totalReservas > 0)
                          Text(
                            '${selectedAgencia.totalReservas} reserva${selectedAgencia.totalReservas != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showAgenciaDialog() {
    // Resetear búsqueda al abrir
    _searchController.clear();
    _filterAgencias(''); // Aplicar filtro vacío para mostrar todas las agencias
    _showAddForm = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que el modal ocupe casi toda la altura
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => DraggableScrollableSheet(
          initialChildSize: 0.8, // Inicia ocupando el 80% de la pantalla
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false, // No expandir a la altura máxima automáticamente
          builder: (_, scrollController) {
            return Column(
              children: [
                // Handle para arrastrar el modal
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text('Seleccionar Agencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar agencia...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterAgencias('');
                                setDialogState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _filterAgencias(value);
                      setDialogState(() {});
                    },
                  ),
                ),
                // Formulario para agregar nueva agencia
                if (_showAddForm)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.add_business,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Nueva Agencia',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _newAgenciaController,
                            decoration: const InputDecoration(
                              hintText: 'Nombre de la nueva agencia',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addNewAgencia(),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isAddingAgencia
                                      ? null
                                      : () async {
                                          await _addNewAgencia();
                                          setDialogState(() {}); // Actualizar el estado del diálogo después de añadir
                                        },
                                  icon: _isAddingAgencia
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.add, size: 16),
                                  label: Text(
                                    _isAddingAgencia ? 'Agregando...' : 'Agregar',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isAddingAgencia
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            _showAddForm = false;
                                            _newAgenciaController.clear();
                                          });
                                        },
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Cancelar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                // Lista de agencias
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredAgencias.isEmpty
                          ? _buildEmptyState(setDialogState)
                          : ListView.builder(
                              controller: scrollController, // Asociar el controlador de scroll
                              itemCount: _filteredAgencias.length,
                              itemBuilder: (context, index) {
                                final agencia = _filteredAgencias[index];
                                final isSelected =
                                    agencia.id == widget.selectedAgenciaId;
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  color: isSelected ? Colors.blue.shade50 : null,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: isSelected
                                          ? Colors.blue.shade600
                                          : Colors.grey.shade300,
                                      backgroundImage:
                                          agencia.imagenUrl != null &&
                                                  agencia.imagenUrl!.isNotEmpty
                                              ? NetworkImage(agencia.imagenUrl!)
                                              : null,
                                      child:
                                          agencia.imagenUrl == null ||
                                                  agencia.imagenUrl!.isEmpty
                                              ? Icon(
                                                  Icons.business,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : Colors.grey.shade600,
                                                  size: 20,
                                                )
                                              : null,
                                    ),
                                    title: Text(
                                      agencia.nombre,
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${agencia.totalReservas} reserva${agencia.totalReservas != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check_circle,
                                            color: Colors.blue.shade600,
                                          )
                                        : null,
                                    onTap: () {
                                      widget.onAgenciaSelected(agencia.id);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(StateSetter setDialogState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(
          _searchController.text.isNotEmpty
              ? 'No se encontró "${_searchController.text}"'
              : 'No hay agencias registradas',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            if (_searchController.text.isNotEmpty) {
              _newAgenciaController.text = _searchController.text;
            }
            setDialogState(() {
              _showAddForm = true;
            });
          },
          icon: const Icon(Icons.add_business),
          label: Text(
            _searchController.text.isNotEmpty
                ? 'Crear "${_searchController.text}"'
                : 'Agregar nueva agencia',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
