import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Vista Premium para historial y registro de metas semanales
/// Diseño sofisticado con métricas en tiempo real y visualizaciones elegantes
class HistorialMetasView extends StatefulWidget {
  const HistorialMetasView({Key? key}) : super(key: key);

  @override
  State<HistorialMetasView> createState() => _HistorialMetasViewState();
}

class _HistorialMetasViewState extends State<HistorialMetasView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Paleta de colores premium - Azul noche sofisticado (igual que ReportesView)
  static const Color _primaryNavy = Color(0xFF0A1628);
  static const Color _accentTeal = Color(0xFF14B8A6);
  static const Color _accentAmber = Color(0xFFF59E0B);
  static const Color _surfaceBlue = Color(0xFF1E3A8A);
  static const Color _cardBackground = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportesController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
              ),
            ),
            child: StreamBuilder<List<ReservaConAgencia>>(
              stream: controller.reservasStream,
              builder: (context, reservasSnapshot) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          expandedHeight: 120,
                          floating: false,
                          pinned: true,
                          backgroundColor: _primaryNavy,
                          flexibleSpace: FlexibleSpaceBar(
                            title: const Text(
                              'Metas Semanales',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            background: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryNavy, _surfaceBlue],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _buildCurrentWeekMetrics(controller, reservasSnapshot.data ?? []),
                          ),
                        ),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildGoalsHistory(controller, reservasSnapshot.data ?? []),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentTeal, Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _accentTeal.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () => _mostrarDialogoMeta(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentWeekMetrics(ReportesController controller, List<ReservaConAgencia> reservas) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: controller.obtenerMetaSemanalPasajeros(now),
      builder: (context, metaSnapshot) {
        final metaActual = metaSnapshot.data?['goal'] ?? 0;
        final pasajerosActuales = controller.calcularPasajerosSemanaActual(reservas);
        final progreso = metaActual > 0 ? (pasajerosActuales / metaActual).clamp(0.0, 1.0) : 0.0;
        final metaCumplida = pasajerosActuales >= metaActual;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Semana Actual',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Meta Semanal',
                    value: '$metaActual',
                    subtitle: 'pasajeros objetivo',
                    icon: Icons.flag_rounded,
                    gradient: const LinearGradient(
                      colors: [_accentAmber, Color(0xFFEAB308)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Alcanzados',
                    value: '$pasajerosActuales',
                    subtitle: 'pasajeros actuales',
                    icon: Icons.people_rounded,
                    gradient: LinearGradient(
                      colors: metaCumplida 
                        ? [Colors.green, Color(0xFF16A34A)]
                        : [_accentTeal, Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildProgressCard(progreso, metaCumplida, pasajerosActuales, metaActual),
          ],
        );
      },
    );
  }

  Widget _buildProgressCard(double progreso, bool metaCumplida, int actual, int meta) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso de la Meta',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: metaCumplida ? Colors.green.withOpacity(0.1) : _accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  metaCumplida ? 'CUMPLIDA 🎉' : '${(progreso * 100).toInt()}%',
                  style: TextStyle(
                    color: metaCumplida ? Colors.green : _accentTeal,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso,
              backgroundColor: _textSecondary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                metaCumplida ? Colors.green : _accentTeal,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$actual de $meta pasajeros',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsHistory(ReportesController controller, List<ReservaConAgencia> reservas) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.obtenerHistorialMetas(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        if (snapshot.hasError) {
          return _buildErrorState();
        }
        
        final metas = snapshot.data ?? [];
        if (metas.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _primaryNavy.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryNavy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history, color: _primaryNavy, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Historial de Metas',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...metas.map((meta) => _buildGoalHistoryItem(meta, controller, reservas)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalHistoryItem(Map<String, dynamic> meta, ReportesController controller, List<ReservaConAgencia> reservas) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startOfWeek = meta['startOfWeek'] as DateTime;
    final endOfWeek = meta['endOfWeek'] as DateTime;
    final goal = meta['goal'] as int;

    final pasajerosSemana = controller.calcularPasajerosEnRango(reservas, startOfWeek, endOfWeek);
    final metaCumplida = pasajerosSemana >= goal;
    final progreso = goal > 0 ? (pasajerosSemana / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: metaCumplida ? Colors.green.withOpacity(0.3) : _textSecondary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dateFormat.format(startOfWeek)} - ${dateFormat.format(endOfWeek)}',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Meta: $goal pasajeros • Alcanzados: $pasajerosSemana',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: metaCumplida ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  metaCumplida ? 'CUMPLIDA' : 'PENDIENTE',
                  style: TextStyle(
                    color: metaCumplida ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              backgroundColor: _textSecondary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                metaCumplida ? Colors.green : _accentTeal,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_primaryNavy),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando historial de metas...',
              style: TextStyle(color: _textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el historial',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.flag_outlined,
                size: 64,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay metas registradas',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu primera meta semanal',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _mostrarDialogoMeta(BuildContext context) async {
    final reportesController = Provider.of<ReportesController>(context, listen: false);
    final now = DateTime.now();
    final metaSemanaActual = await reportesController.obtenerMetaSemanalPasajeros(now);
    final existeMetaActual = metaSemanaActual != null && metaSemanaActual['goal'] != null;
    final metaId = existeMetaActual ? metaSemanaActual['id']?.toString() : null;
    final metaValue = (existeMetaActual && metaSemanaActual['goal'] != null)
      ? metaSemanaActual['goal'].toString()
      : '';
    final controller = TextEditingController(text: metaValue);

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            existeMetaActual ? 'Actualizar Meta Semanal' : 'Nueva Meta Semanal',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Número de pasajeros',
              labelStyle: TextStyle(color: _textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _textSecondary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _accentTeal),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final meta = int.tryParse(controller.text);
                if (meta != null && meta > 0) {
                  if (existeMetaActual && metaId != null) {
                    await reportesController.actualizarMetaSemanalPasajeros(metaId, meta);
                  } else {
                    await reportesController.agregarMetaSemanalPasajeros(
                      meta: meta,
                      fecha: now,
                    );
                  }
                  Navigator.of(context).pop(meta);
                  setState(() {}); // Refresh the view
                }
              },
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
