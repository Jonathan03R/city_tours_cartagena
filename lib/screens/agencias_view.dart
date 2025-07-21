import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/mvvc/reservas_controller.dart';
import 'package:citytourscartagena/screens/reservas_view.dart';
import 'package:flutter/material.dart';

class AgenciasView extends StatefulWidget {
  const AgenciasView({super.key});

  @override
  State<AgenciasView> createState() => _AgenciasViewState();
}

class _AgenciasViewState extends State<AgenciasView> {
  List<AgenciaConReservas> _agencias = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agencias'),
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
                  child: Text(
                    '${_agencias.length} agencia${_agencias.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
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
                final agencias = snapshot.data ?? [];
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
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.01,
                  ),
                  itemCount: agencias.length,
                  itemBuilder: (context, index) {
                    final agencia = agencias[index];
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () => _navigateToAgenciaReservas(agencia),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business,
                                size: 40,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                agencia.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${agencia.totalReservas} reservas',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  void _navigateToAgenciaReservas(AgenciaConReservas agencia) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReservasView(agenciaId: agencia.id)),
    );
  }
}
