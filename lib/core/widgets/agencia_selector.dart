import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:flutter/material.dart';

import '../mvvc/reservas_controller.dart';

class AgenciaSelector extends StatefulWidget {
  final String? selectedAgenciaId;
  final Function(String) onAgenciaSelected;

  const AgenciaSelector({
    Key? key,
    this.selectedAgenciaId,
    required this.onAgenciaSelected,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _loadAgencias();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newAgenciaController.dispose();
    super.dispose();
  }

  Future<void> _loadAgencias() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _allAgencias = ReservasController.getAllAgencias();
      _filteredAgencias = List.from(_allAgencias);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error cargando agencias: $e');
    }
  }

  void _filterAgencias(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAgencias = List.from(_allAgencias);
      } else {
        _filteredAgencias = _allAgencias
            .where((agencia) => 
                agencia.nombre.toLowerCase().contains(query.toLowerCase()))
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
      final newAgencia = await ReservasController.addAgencia(_newAgenciaController.text.trim());
      widget.onAgenciaSelected(newAgencia.id);
      _newAgenciaController.clear();
      
      // Recargar agencias
      await _loadAgencias();
      
      setState(() {
        _showAddForm = false;
        _isAddingAgencia = false;
      });
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Agencia "${newAgencia.nombre}" agregada exitosamente'),
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
    final selectedAgencia = widget.selectedAgenciaId != null
        ? _allAgencias.firstWhere(
            (a) => a.id == widget.selectedAgenciaId,
            orElse: () => AgenciaConReservas(id: '', nombre: 'Agencia no encontrada', totalReservas: 0),
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
                    color: selectedAgencia != null ? Colors.blue.shade600 : Colors.grey.shade600,
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
                            color: selectedAgencia != null ? Colors.black : Colors.grey.shade600,
                            fontWeight: selectedAgencia != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        if (selectedAgencia != null && selectedAgencia.totalReservas > 0)
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
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _showAgenciaDialog() {
    // Resetear búsqueda al abrir
    _searchController.clear();
    _filteredAgencias = List.from(_allAgencias);
    _showAddForm = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.business, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Seleccionar Agencia'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // Barra de búsqueda
                TextField(
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
                const SizedBox(height: 16),
                
                // Formulario para agregar nueva agencia
                if (_showAddForm) ...[
                  Container(
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
                            Icon(Icons.add_business, color: Colors.blue.shade600, size: 20),
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
                                onPressed: _isAddingAgencia ? null : _addNewAgencia,
                                icon: _isAddingAgencia
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add, size: 16),
                                label: Text(_isAddingAgencia ? 'Agregando...' : 'Agregar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isAddingAgencia ? null : () {
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
                  const SizedBox(height: 16),
                ],
                
                // Lista de agencias
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredAgencias.isEmpty
                          ? _buildEmptyState(setDialogState)
                          : ListView.builder(
                              itemCount: _filteredAgencias.length,
                              itemBuilder: (context, index) {
                                final agencia = _filteredAgencias[index];
                                final isSelected = agencia.id == widget.selectedAgenciaId;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  color: isSelected ? Colors.blue.shade50 : null,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected 
                                          ? Colors.blue.shade600 
                                          : Colors.grey.shade300,
                                      child: Icon(
                                        Icons.business,
                                        color: isSelected ? Colors.white : Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      agencia.nombre,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                                        ? Icon(Icons.check_circle, color: Colors.blue.shade600)
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(StateSetter setDialogState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          _searchController.text.isNotEmpty
              ? 'No se encontró "${_searchController.text}"'
              : 'No hay agencias registradas',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
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
