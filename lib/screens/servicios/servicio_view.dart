// ignore_for_file: use_build_context_synchronously

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/bloqueos_fecha_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart' as agencia_model;
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/fechas_bloquedas.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ServiciosView extends StatefulWidget {
  final String searchTerm;
  const ServiciosView({super.key, this.searchTerm = ''});

  @override
  State<ServiciosView> createState() => _ServiciosViewState();
}

class _ServiciosViewState extends State<ServiciosView> {
  String? _nombreEmpresa;
  late final BloqueosFechaController _bloqueosController;

  @override
  void initState() {
    super.initState();
    _bloqueosController = BloqueosFechaController(fecha: DateTime.now());
  }

  @override
  void dispose() {
    // _bloqueosController.dispose(); // si tu controller lo necesita
    super.dispose();
  }

  bool _isPrivado(TurnoType turno) {
    // Ajusta si tienes TurnoType.privado explícito
    return !(turno == TurnoType.manana || turno == TurnoType.tarde);
  }

  // Abre WhatsApp directo para "servicio privado"
  Future<void> _abrirWhatsAppPrivado(
    BuildContext context,
    String? telefonoRaw,
  ) async {
    final raw = (telefonoRaw ?? '').trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay número de WhatsApp configurado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Obtener el nombre de la agencia logeada
    final authController = context.read<AuthController>();
    final agenciasController = context.read<AgenciasController>();
    final agenciaId = authController.appUser?.agenciaId;

    String nombreAgencia = 'Agencia';
    final lista = agenciasController.agencias;
    final agenciaLogeada = lista.firstWhere(
      (a) => a.agencia.id == agenciaId,
      orElse: () => agencia_model.AgenciaConReservas(
        agencia: agencia_model.Agencia(
          id: agenciaId ?? '',
          nombre: nombreAgencia,
          imagenUrl: null,
          eliminada: false,
        ),
        totalReservas: 0,
      ),
    );
    nombreAgencia = agenciaLogeada.agencia.nombre;

    // Deja solo dígitos
    final telefono = raw.replaceAll(RegExp(r'[^\d]'), '');
    final mensaje = Uri.encodeComponent(
      'Hola, le escribo de la agencia $nombreAgencia ¿Hay disponibilidad para servicio privado hoy?',
    );

    final uriApp = Uri.parse('whatsapp://send?phone=$telefono&text=$mensaje');
    final uriWeb = Uri.parse('https://wa.me/$telefono?text=$mensaje');

    if (await canLaunchUrl(uriApp)) {
      await launchUrl(uriApp, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(uriWeb)) {
      await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir WhatsApp'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final reservasController = context.watch<ReservasController>();
    final configuracion = context.watch<ConfiguracionController>().configuracion;

    final agenciaId = authController.appUser?.agenciaId;
    _nombreEmpresa = configuracion?.nombreEmpresa ?? 'City Tours Climatizado';

    if (agenciaId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No se encontró información de la agencia.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Layout responsivo con Wrap
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16.0;
    final columns = screenWidth >= 1100 ? 4 : screenWidth >= 820 ? 3 : 2;
    final spacing = 16.0;
    final availableWidth = screenWidth - (padding * 2) - (spacing * (columns - 1));
    final itemWidth = availableWidth / columns;

    return Scaffold(
      // appBar: AppBar(
      //   title: null,
      //   backgroundColor: Theme.of(context).colorScheme.surface,
      //   foregroundColor: Theme.of(context).colorScheme.onSurface,
      //   elevation: 0,
      // ),
      // Tiempo real: reservas
      body: StreamBuilder<List<ReservaConAgencia>>(
        stream: reservasController.getAllReservasConAgenciaStream(),
        builder: (context, reservasSnapshot) {
          if (reservasSnapshot.connectionState == ConnectionState.waiting) {
            return const _CenteredLoader();
          }
          if (reservasSnapshot.hasError) {
            return Center(
              child: _ErrorBox(message: 'Error cargando reservas: ${reservasSnapshot.error}'),
            );
          }

          // Tiempo real: bloqueos (solo para disparar rebuild, no para decidir estado del privado)
          return StreamBuilder<List<FechaBloqueada>>(
            stream: _bloqueosController.bloqueosStream,
            builder: (context, _) {
              final today = DateTime.now();

              final children = TurnoType.values.map((turno) {
                // Usamos SIEMPRE getEstadoCupos para todos los turnos
                return FutureBuilder<CuposEstado>(
                  future: reservasController.getEstadoCupos(
                    turno: turno,
                    fecha: today,
                  ),
                  builder: (ctx, snap) {
                    final estadoOriginal = snap.data ?? CuposEstado.disponible;

                    // Para "servicio privado": ignorar solo el "límite alcanzado".
                    final estadoParaMostrar = _isPrivado(turno) && estadoOriginal == CuposEstado.limiteAlcanzado
                        ? CuposEstado.disponible
                        : estadoOriginal;

                    return SizedBox(
                      width: itemWidth,
                      child: _TurnoCard(
                        turno: turno,
                        estado: estadoParaMostrar,
                        empresa: _nombreEmpresa ?? 'Agencia',
                        onTap: () async {
                          HapticFeedback.selectionClick();

                          if (_isPrivado(turno)) {
                            // Abrir WhatsApp directo (sin shouldShow)
                            await _abrirWhatsAppPrivado(
                              context,
                              configuracion?.contact_whatsapp,
                            );
                            return;
                          }

                          // Resto de turnos: flujo normal
                          final agencia = agencia_model.AgenciaConReservas(
                            agencia: agencia_model.Agencia(
                              id: authController.appUser!.agenciaId!,
                              nombre: _nombreEmpresa!,
                              imagenUrl: null,
                              eliminada: false,
                            ),
                            totalReservas: 0,
                          );
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReservasView(agencia: agencia, turno: turno),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: children,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------------- UI Widgets -------------------------------------

class _TurnoCard extends StatelessWidget {
  const _TurnoCard({
    required this.turno,
    required this.estado,
    required this.empresa,
    required this.onTap,
  });

  final TurnoType turno;
  final CuposEstado estado;
  final String empresa;
  final VoidCallback onTap;

  bool get _isPrivado => !(turno == TurnoType.manana || turno == TurnoType.tarde);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradient = _backgroundGradient(estado, _isPrivado);

    return Semantics(
      button: true,
      label: _isPrivado ? 'Servicio privado' : 'Turno ${turno.label}',
      child: InkWell(
        onTap: onTap, // Siempre activo
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPrivado ? 0.10 : 0.06),
                blurRadius: _isPrivado ? 22 : 14,
                spreadRadius: _isPrivado ? 1 : 0,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: _isPrivado ? const Color(0xFFF59E0B).withOpacity(0.8) : cs.outlineVariant.withOpacity(0.15),
              width: _isPrivado ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                _TurnoIcon(turno: turno, isPrivado: _isPrivado),
                const SizedBox(height: 10),
                Text(
                  _isPrivado ? 'Servicio privado' : turno.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16.sp,
                    color: _isPrivado ? Colors.amber.shade50 : Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _AgencyAvatar(),
                const SizedBox(height: 12),
                Text(
                  empresa,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _EstadoBadge(estado: estado), // “… hoy”
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _backgroundGradient(CuposEstado e, bool isPrivado) {
    if (isPrivado) {
      // VIP: negro azulado -> dorado
      return const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF111827), Color(0xFFF59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.6, 1.0],
      );
    }
    if (e == CuposEstado.cerrado) {
      return const LinearGradient(
        colors: [Color(0xFFD8113C), Color.fromARGB(255, 235, 78, 16)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (e == CuposEstado.limiteAlcanzado) {
      return const LinearGradient(
        colors: [Color(0xFFFFC857), Color(0xFFFF8A00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF2DD4BF), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }
}

class _TurnoIcon extends StatelessWidget {
  const _TurnoIcon({required this.turno, required this.isPrivado});
  final TurnoType turno;
  final bool isPrivado;

  @override
  Widget build(BuildContext context) {
    final IconData icono = (turno == TurnoType.manana)
        ? Icons.wb_sunny_rounded
        : (turno == TurnoType.tarde)
            ? Icons.wb_twilight
            : PhosphorIconsFill.crown; // corona SOLO para privado

    final bool esCorona = isPrivado;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: esCorona
            ? const LinearGradient(
                colors: [Color(0xFFFFE08A), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: esCorona ? null : Colors.white.withOpacity(0.20),
        border: Border.all(color: esCorona ? Colors.white.withOpacity(0.65) : Colors.white24, width: esCorona ? 2 : 1.5),
        boxShadow: esCorona
            ? [
                BoxShadow(
                  color: const Color(0xFFFFBF00).withOpacity(0.35),
                  blurRadius: 16.r,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      padding: EdgeInsets.all(esCorona ? 12 : 10),
      child: Icon(
        icono,
        size: esCorona ? 32 : 28,
        color: esCorona ? Colors.black87 : Colors.white,
      ),
    );
  }
}

class _AgencyAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/logo.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});
  final CuposEstado estado;

  @override
  Widget build(BuildContext context) {
    final String mensaje = switch (estado) {
      CuposEstado.cerrado => 'Cerrado hoy',
      CuposEstado.limiteAlcanzado => 'Verificar disponibilidad hoy',
      _ => 'Cupos Disponibles hoy',
    };
    final Color text = switch (estado) {
      CuposEstado.cerrado => const Color(0xFF7F1D1D),
      CuposEstado.limiteAlcanzado => const Color(0xFF7C3E00),
      _ => const Color(0xFF064E3B),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white70, width: 1),
      ),
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
          fontSize: 10.sp,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  const _CenteredLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}