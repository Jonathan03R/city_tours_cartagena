import 'package:citytourscartagena/core/controller/gastos_controller.dart';
import 'package:flutter/material.dart';

class HistorialGastosView extends StatefulWidget {
  const HistorialGastosView({super.key});

  @override
  State<HistorialGastosView> createState() => _HistorialGastosViewState();
}

class _HistorialGastosViewState extends State<HistorialGastosView> {
  final GastosController _controller = GastosController();
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _controller.inicializar(limite: 5);
    setState(() => _cargando = false);
  }

  Future<void> _siguiente() async {
    await _controller.siguientePagina();
    setState(() {});
  }

  Future<void> _anterior() async {
    await _controller.paginaAnterior();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Gastos"),
      ),
      body: Column(
        children: [
          // Estado (Página 1 de N)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _controller.estadoTexto,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Lista de gastos
          Expanded(
            child: ListView.builder(
              itemCount: _controller.gastosActuales.length,
              itemBuilder: (context, index) {
                final gasto = _controller.gastosActuales[index].data()
                    as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(gasto['descripcion'] ?? ''),
                    subtitle: Text(gasto['fecha']?.toDate().toString() ?? ''),
                    trailing: Text("\$${gasto['monto'] ?? 0}"),
                  ),
                );
              },
            ),
          ),

          // Botones de navegación
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _controller.paginaActual > 1 ? _anterior : null,
                  child: const Text("Anterior"),
                ),
                ElevatedButton(
                  onPressed: _controller.paginaActual < _controller.totalPaginas
                      ? _siguiente
                      : null,
                  child: const Text("Siguiente"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
