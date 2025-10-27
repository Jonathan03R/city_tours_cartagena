import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AgenciaSelector extends StatefulWidget {
  final int? selectedAgenciaId;
  final Function(int) onAgenciaSelected;

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
  final TextEditingController _newAgenciaController = TextEditingController();

  List<AgenciaSupabase> _allAgencias = [];
  List<AgenciaSupabase> _filteredAgencias = [];

  bool _isLoading = false;
  bool _isAdding = false;
  bool _showAddForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAgencias());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newAgenciaController.dispose();
    super.dispose();
  }

  Future<void> _loadAgencias() async {
    setState(() => _isLoading = true);
    try {
      final operadoresCtrl = context.read<OperadoresController>();
      final reservasCtrl = context.read<ControladorDeltaReservas>();

      final operador = await operadoresCtrl.obtenerOperador();
      if (operador == null) throw Exception('Operador no encontrado');

      final agencias = await operadoresCtrl.obtenerAgenciasDeOperador();

      // Calcular reservas en paralelo
      final agenciasConDatos = await Future.wait(
        agencias.map((a) async {
          final count = await reservasCtrl.contarReservas(
            operadorId: operador.id,
            agenciaId: a.codigo,
          );
          return a.copyWith(totalReservas: count);
        }),
      );

      setState(() {
        _allAgencias = agenciasConDatos;
        _filterAgencias('');
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error cargando agencias: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterAgencias(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAgencias = List.from(_allAgencias);
      } else {
        _filteredAgencias = _allAgencias
            .where((a) =>
                a.nombre.toLowerCase().contains(query.toLowerCase().trim()))
            .toList();
      }
    });
  }

  Future<void> _addNewAgencia() async {
    final nombre = _newAgenciaController.text.trim();
    if (nombre.isEmpty) return;

    setState(() => _isAdding = true);

    try {
      final agenciasCtrl = context.read<AgenciasController>();
      final nuevaAgencia = await agenciasCtrl.addAgencia(nombre, null);

      setState(() {
        _isAdding = false;
        _showAddForm = false;
        _newAgenciaController.clear();
      });

      widget.onAgenciaSelected(int.parse(nuevaAgencia.id));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Agencia "${nuevaAgencia.nombre}" agregada'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadAgencias();
    } catch (e) {
      debugPrint('Error agregando agencia: $e');
      setState(() => _isAdding = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar agencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedAgencia = _allAgencias
        .where((a) => a.codigo == widget.selectedAgenciaId)
        .cast<AgenciaSupabase?>()
        .firstOrNull;

    return InkWell(
      onTap: _showAgenciaDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
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
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showAgenciaDialog() {
    _searchController.clear();
    _filterAgencias('');
    _showAddForm = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Header
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Seleccionar Agencia',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Buscar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

                // Formulario para agregar
                if (_showAddForm)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          const Text('Nueva Agencia',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _newAgenciaController,
                            decoration: const InputDecoration(
                              hintText: 'Nombre de la nueva agencia',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) async {
                              await _addNewAgencia();
                              setDialogState(() {});
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isAdding ? null : () async => _addNewAgencia(),
                                  icon: _isAdding
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Icon(Icons.add, size: 16),
                                  label: Text(
                                      _isAdding ? 'Agregando...' : 'Agregar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isAdding
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
                              controller: scrollController,
                              itemCount: _filteredAgencias.length,
                              itemBuilder: (context, index) {
                                final agencia = _filteredAgencias[index];
                                final isSelected =
                                    agencia.codigo == widget.selectedAgenciaId;
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  color: isSelected
                                      ? Colors.blue.shade50
                                      : Colors.white,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isSelected
                                          ? Colors.blue.shade600
                                          : Colors.grey.shade300,
                                      backgroundImage: agencia.logoUrl != null
                                              && agencia.logoUrl!.isNotEmpty
                                          ? NetworkImage(agencia.logoUrl!)
                                          : null,
                                      child: (agencia.logoUrl == null ||
                                              agencia.logoUrl!.isEmpty)
                                          ? Icon(
                                              Icons.business,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey.shade600,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      agencia.nombre,
                                      style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal),
                                    ),
                                    subtitle: Text(
                                      '${agencia.totalReservas} reserva${agencia.totalReservas != 1 ? 's' : ''}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                                    trailing: isSelected
                                        ? Icon(Icons.check_circle,
                                            color: Colors.blue.shade600)
                                        : null,
                                    onTap: () {
                                      widget.onAgenciaSelected(agencia.codigo);
                                      Navigator.pop(context);
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontró "${_searchController.text}"'
                : 'No hay agencias registradas',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
      ),
    );
  }
}
