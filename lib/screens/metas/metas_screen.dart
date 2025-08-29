import 'package:citytourscartagena/core/controller/metas_controller.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MetasScreen extends StatefulWidget {
  const MetasScreen({super.key});

  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  final _numeroMetaController = TextEditingController();
  TurnoType? _selectedTurno;
  bool _isLoading = false;

  @override
  void dispose() {
    _numeroMetaController.dispose();
    super.dispose();
  }

  Future<void> _agregarMeta() async {
    if (_numeroMetaController.text.isEmpty || _selectedTurno == null) return;

    setState(() => _isLoading = true);
    try {
      final numeroMeta = double.parse(_numeroMetaController.text);
      await context.read<MetasController>().agregarMeta(
        numeroMeta: numeroMeta,
        turno: _selectedTurno!,
      );
      _numeroMetaController.clear();
      setState(() => _selectedTurno = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta agregada exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metasController = context.watch<MetasController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Metas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Agregar Meta
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Agregar Meta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _numeroMetaController,
                      decoration: const InputDecoration(labelText: 'Número de Meta'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TurnoType>(
                      value: _selectedTurno,
                      items: TurnoType.values.map((turno) {
                        return DropdownMenuItem(
                          value: turno,
                          child: Text(turno.label), // Usar label para mostrar bonito
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedTurno = value),
                      decoration: const InputDecoration(labelText: 'Turno'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _agregarMeta,
                      child: _isLoading ? const CircularProgressIndicator() : const Text('Agregar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Semana Actual
            const Text('Semana Actual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _obtenerEstadoSemanaActual(metasController),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final estados = snapshot.data ?? [];
                return Column(
                  children: estados.map((estado) {
                    return Card(
                      child: ListTile(
                        title: Text('Turno: ${estado['turno']}'),
                        subtitle: Text('Pasajeros: ${estado['pasajeros']} / Meta: ${estado['meta']}'),
                        trailing: Icon(
                          estado['cumplida'] ? Icons.check_circle : Icons.cancel,
                          color: estado['cumplida'] ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 20),

            // Historial de Metas
            const Text('Historial de Metas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<QuerySnapshot>(
              future: metasController.obtenerTodasMetas(), // Cambiado para obtener todas
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                final metas = snapshot.data?.docs ?? [];
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: metas.length,
                  itemBuilder: (context, index) {
                    final meta = metas[index].data() as Map<String, dynamic>;
                    final turno = TurnoType.values.firstWhere((t) => t.name == meta['turno']);
                    final inicio = (meta['fechaInicio'] as Timestamp).toDate();
                    final fin = (meta['fechaFin'] as Timestamp).toDate();
                    final numeroMeta = meta['numeroMeta'] as double;

                    return FutureBuilder<bool>(
                      future: metasController.verificarMetaPorRango(numeroMeta, turno, inicio, fin),
                      builder: (context, snapCumplida) {
                        final cumplida = snapCumplida.data ?? false;
                        return Card(
                          child: ListTile(
                            title: Text('Meta: $numeroMeta'),
                            subtitle: Text('Turno: ${turno.label} | Inicio: ${inicio.toLocal()} | ${cumplida ? 'Completada' : 'No completada'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _eliminarMeta(metas[index].id, metasController),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _obtenerEstadoSemanaActual(MetasController controller) async {
    final estados = <Map<String, dynamic>>[];
    for (final turno in TurnoType.values) {
      try {
        final cumplida = await controller.verificarMetaSemanal(turno);
        final pasajeros = await controller.obtenerSumaPasajerosSemanaActual(turno);
        final meta = await controller.obtenerMetaSemanaActual(turno);
        estados.add({
          'turno': turno.label, // Usar label para mostrar bonito
          'pasajeros': pasajeros,
          'meta': meta ?? 0,
          'cumplida': cumplida,
        });
      } catch (e) {
        // Ignorar errores por turno
      }
    }
    return estados;
  }

  Future<void> _eliminarMeta(String id, MetasController controller) async {
    try {
      await controller.eliminarMeta(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meta eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}