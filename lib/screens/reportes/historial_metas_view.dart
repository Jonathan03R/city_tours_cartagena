// import 'package:citytourscartagena/core/controller/reportes_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class HistorialMetasView extends StatefulWidget {
//   const HistorialMetasView({Key? key}) : super(key: key);

//   @override
//   State<HistorialMetasView> createState() => _HistorialMetasViewState();
// }

// class _HistorialMetasViewState extends State<HistorialMetasView> {
//   @override
//   Widget build(BuildContext context) {
//     final controller = Provider.of<ReportesController>(context);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Historial de Metas'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () => _mostrarDialogoMeta(context),
//           ),
//         ],
//       ),
//       body: FutureBuilder<Map<String, dynamic>?>(
//         future: controller.obtenerMetaSemanalActual(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error al cargar la meta semanal'));
//           }

//           final metaActual = snapshot.data;
//           if (metaActual == null) {
//             return const Center(child: Text('No hay metas registradas.'));
//           }

//           return Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildMetaSemanal(metaActual, controller),
//               const SizedBox(height: 16),
//               Expanded(child: _buildHistorialMetas(controller)),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildMetaSemanal(Map<String, dynamic> meta, ReportesController controller) {
//     final metaPasajeros = meta['goal'] ?? 0;
//     final pasajerosActuales = meta['current'] ?? 0;
//     final progreso = controller.calcularProgresoMetaSemanal(
//       meta: metaPasajeros,
//       pasajerosActuales: pasajerosActuales,
//     );

//     return Card(
//       margin: const EdgeInsets.all(16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Meta Semanal',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text('Meta: $metaPasajeros pasajeros'),
//             Text('Alcanzados: $pasajerosActuales pasajeros'),
//             const SizedBox(height: 8),
//             LinearProgressIndicator(
//               value: progreso,
//               backgroundColor: Colors.grey[300],
//               valueColor: AlwaysStoppedAnimation<Color>(
//                 progreso >= 1.0 ? Colors.green : Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               progreso >= 1.0
//                   ? '¡Meta cumplida! 🎉'
//                   : 'Progreso: ${(progreso * 100).toStringAsFixed(1)}%',
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHistorialMetas(ReportesController controller) {
//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: controller.obtenerHistorialMetas(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (snapshot.hasError) {
//           return const Center(child: Text('Error al cargar el historial de metas'));
//         }

//         final metas = snapshot.data ?? [];
//         if (metas.isEmpty) {
//           return const Center(child: Text('No hay historial de metas.'));
//         }

//         return ListView.builder(
//           itemCount: metas.length,
//           itemBuilder: (context, index) {
//             final meta = metas[index];
//             return ListTile(
//               title: Text('Semana ${meta['week']}'),
//               subtitle: Text('Meta: ${meta['goal']} pasajeros'),
//               trailing: Text(
//                 meta['completed'] ? 'Cumplida' : 'Pendiente',
//                 style: TextStyle(
//                   color: meta['completed'] ? Colors.green : Colors.red,
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Future<void> _mostrarDialogoMeta(BuildContext context) async {
//     final controller = Provider.of<ReportesController>(context, listen: false);
//     final metaController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: const Text('Nueva Meta Semanal'),
//           content: TextField(
//             controller: metaController,
//             keyboardType: TextInputType.number,
//             decoration: const InputDecoration(
//               labelText: 'Número de pasajeros',
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancelar'),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 final meta = int.tryParse(metaController.text);
//                 if (meta != null && meta > 0) {
//                   await controller.agregarMetaSemanalPasajeros(
//                     meta: meta,
//                     fecha: DateTime.now(),
//                   );
//                   Navigator.of(context).pop();
//                   setState(() {}); // Refrescar la vista
//                 }
//               },
//               child: const Text('Guardar'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }