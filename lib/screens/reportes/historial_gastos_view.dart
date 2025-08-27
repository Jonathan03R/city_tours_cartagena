import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/controller/gastos_controller.dart';

class HistorialGastosView extends StatefulWidget {
  const HistorialGastosView({super.key});

  @override
  State<HistorialGastosView> createState() => _HistorialGastosViewState();
}

class _HistorialGastosViewState extends State<HistorialGastosView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Cargar más datos cuando se llega al final de la lista
      Provider.of<GastosController>(context, listen: false).cargarMasGastos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<GastosController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Gastos'),
      ),
      body: controller.cargando && controller.gastos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: controller.gastos.length + (controller.cargando ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == controller.gastos.length) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final gasto = controller.gastos[index];
                      final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(gasto['fecha']));

                      return ListTile(
                        title: Text(gasto['descripcion']),
                        subtitle: Text('Monto: \$${gasto['monto']} - Fecha: $fecha'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await _confirmarEliminacion(context);
                            if (confirm) {
                              await controller.eliminarGasto(gasto['id']);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (!controller.cargando && controller.gastos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay gastos registrados.'),
                  ),
              ],
            ),
    );
  }

  Future<bool> _confirmarEliminacion(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text('¿Estás seguro de que deseas eliminar este gasto?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }
}