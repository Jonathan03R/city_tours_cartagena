import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reservas/precio_servicio.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/screens/agencias/widget/control_precios_widget.dart';
import 'package:citytourscartagena/screens/agencias/widget/encabezado_agencia_widget.dart';
import 'package:citytourscartagena/screens/agencias/widget/tabla_reservas_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'filtros.dart';

class ReservaVista extends StatefulWidget {
  final int? codigoAgencia;
  final String? nombreAgencia;
  final List<PrecioServicio>? preciosCargados;

  const ReservaVista({
    super.key,
    this.codigoAgencia,
    this.nombreAgencia,
    this.preciosCargados,
  });
  @override
  State<ReservaVista> createState() => _ReservaVistaState();
}

class _ReservaVistaState extends State<ReservaVista> {
  DateFilterType _selectedFilter = DateFilterType.today;
  DateTime? _customDate;
  TurnoType? _selectedTurno;
  EstadoReserva? _selectedEstado;
  bool _isTableView = true;
  String? _currentReservaIdNotificada;

  int _paginaActual = 1;
  int _totalReservas = 0;
  late Future<AgenciaSupabase?> _futureAgencia;

  final ValueNotifier<List<ReservaResumen>> _reservasPaginadas = ValueNotifier(
    [],
  );

  List<PrecioServicio>? _preciosCargados;
  bool _loadingPrecios = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReservas();
      _loadPreciosIfNeeded();
    });
    if (widget.codigoAgencia != null) {
      _futureAgencia = Provider.of<ControladorDeltaReservas>(
        context,
        listen: false,
      ).cargarAgenciaPorId(widget.codigoAgencia!);
    }
  }

  Future<void> _loadPreciosIfNeeded() async {
    // si ya vienen por constructor, úsalos y no hagas petición
    if (widget.preciosCargados != null) {
      setState(() => _preciosCargados = widget.preciosCargados);
      return;
    }
    if (_preciosCargados != null) return; // ya cargado
    setState(() => _loadingPrecios = true);
    try {
      final controller = Provider.of<ControladorDeltaReservas>(
        context,
        listen: false,
      );
      final precios = await controller.obtenerPreciosServiciosConFallback(
        operadorCodigo: 1,
        agenciaCodigo: widget.codigoAgencia ?? 0,
      );
      if (!mounted) return;
      setState(() => _preciosCargados = precios);
    } catch (e) {
      // falla al cargar precios: dejamos _preciosCargados en null y la UI lo indica
    } finally {
      if (!mounted) return;
      setState(() => _loadingPrecios = false);
    }
  }

  Future<void> _cargarReservas() async {
    final controller = Provider.of<ControladorDeltaReservas>(
      context,
      listen: false,
    );
    _totalReservas = await controller.contarReservas(
      operadorId: 1,
      agenciaId: widget.codigoAgencia,
    );
    final reservas = await controller.obtenerReservasPaginadas(
      operadorId: 1,
      agenciaId: widget.codigoAgencia,
      pagina: _paginaActual,
      tamanoPagina: 10,
    );

    _reservasPaginadas.value = reservas;
  }

  // @Deprecated('Ya no se utiliza.')
  // void _iniciarEscuchaReservas() {
  //   if (widget.codigoAgencia != null) {
  //     final controller = Provider.of<ControladorDeltaReservas>(
  //       context,
  //       listen: false,
  //     );
  //     controller.escucharReservas(widget.codigoAgencia!, 1);
  //   }
  // }

  void _clearNotificatedReserva() {
    if (_currentReservaIdNotificada != null && mounted) {
      setState(() {
        _currentReservaIdNotificada = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Resaltado de notificación limpiado'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ControladorDeltaReservas>(context);
    // Simulación de roles y permisos (ajusta según tu lógica real)
    final bool puedeEditarAgencia = true;
    final bool puedeAgregarReserva = true;
    final bool puedeAgregarManual = true;
    final bool puedeWhatsapp = true;
    final String? contactoAgencia = null;
    final String? linkContactoAgencia = null;
    final String? nombreAgencia = widget.nombreAgencia;

    return StreamBuilder<List<ReservaResumen>>(
      stream: controller.reservasStream,
      builder: (context, snapshot) {
        String titulo = nombreAgencia ?? 'Reservas';
        final reservas = snapshot.data ?? [];
        if (reservas.isNotEmpty) {
          titulo = "Reservas de ${reservas.first.agenciaNombre}";
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          titulo = "Cargando reservas...";
        } else if (snapshot.connectionState == ConnectionState.active &&
            reservas.isEmpty) {
          titulo = "No hay reservas";
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(titulo, overflow: TextOverflow.ellipsis),
            backgroundColor: AppColors.lightPrimary,
            foregroundColor: AppColors.lightSurface,
            actions: [
              if (_currentReservaIdNotificada != null)
                IconButton(
                  icon: const Icon(Icons.notifications_off),
                  onPressed: _clearNotificatedReserva,
                  tooltip: 'Limpiar resaltado de notificación',
                ),
              IconButton(
                icon: Icon(_isTableView ? Icons.view_list : Icons.table_chart),
                onPressed: () {
                  setState(() => _isTableView = !_isTableView);
                },
                tooltip: _isTableView ? 'Vista de lista' : 'Vista de tabla',
              ),
              if (puedeEditarAgencia)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    /* abrir dialog editar agencia */
                  },
                  tooltip: 'Editar agencia',
                ),
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  /* mostrar solo tabla */
                },
                tooltip: 'Ver tabla completa',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  /* recargar reservas */
                },
                tooltip: 'Recargar',
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                if (_currentReservaIdNotificada != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade100, Colors.orange.shade50],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notification_important,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reserva de notificación',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'ID: ${_currentReservaIdNotificada}',
                                style: TextStyle(
                                  color: Colors.orange.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _clearNotificatedReserva,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Limpiar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Header de filtros y controles (simula ReservasHeaderWidget)
                FiltrosView(
                  selectedFilter: _selectedFilter,
                  customDate: _customDate,
                  onFilterChanged: (filter, date, {turno}) {
                    setState(() {
                      _selectedFilter = filter;
                      _customDate = date;
                      if (turno != null) _selectedTurno = turno;
                    });
                  },
                  selectedTurno: _selectedTurno,
                  onTurnoChanged: (turno) {
                    setState(() => _selectedTurno = turno);
                  },
                  selectedEstado: _selectedEstado,
                  onEstadoChanged: (estado) {
                    setState(() => _selectedEstado = estado);
                  },
                ),
                if (widget.codigoAgencia != null)
                  FutureBuilder<AgenciaSupabase?>(
                    future: _futureAgencia, // Usa el Future almacenado
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No se encontró la agencia'),
                        );
                      }
                      final agencia = snapshot.data!;
                      return EncabezadoAgenciaWidget(
                        nombreAgencia: agencia.nombre,
                        imagenUrlAgencia: agencia.logoUrl,
                        agenciaId: agencia.codigo,
                        operadorId: 1,
                        totalReservas: reservas.length,
                        totalPasajeros: 0,
                        deuda: 0.0,
                      );
                    },
                  ),

                if (_preciosCargados == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: _loadingPrecios
                          ? const CircularProgressIndicator()
                          : const Text('No se pudieron cargar los precios'),
                    ),
                  )
                else
                  WidgetControlesPrecios(
                    reservasActuales: const [],
                    textoReservas: 'Reservas actuales',
                    textoBotonExportar: 'Exportar',
                    tieneSelecciones: false,
                    puedeExportar: false,
                    precioManana: _preciosCargados!
                        .firstWhere(
                          (p) => p.descripcion.toLowerCase().contains('mañana'),
                          orElse: () => PrecioServicio(
                            codigo: 0,
                            precio: 0.0,
                            descripcion: '',
                            origen: '',
                          ),
                        )
                        .precio,
                    origenManana: _preciosCargados!
                        .firstWhere(
                          (p) => p.descripcion.toLowerCase().contains('mañana'),
                          orElse: () => PrecioServicio(
                            codigo: 0,
                            precio: 0.0,
                            descripcion: '',
                            origen: '',
                          ),
                        )
                        .origen,
                    precioTarde: _preciosCargados!
                        .firstWhere(
                          (p) => p.descripcion.toLowerCase().contains('tarde'),
                          orElse: () => PrecioServicio(
                            codigo: 0,
                            precio: 0.0,
                            descripcion: '',
                            origen: '',
                          ),
                        )
                        .precio,
                    origenTarde: _preciosCargados!
                        .firstWhere(
                          (p) => p.descripcion.toLowerCase().contains('tarde'),
                          orElse: () => PrecioServicio(
                            codigo: 0,
                            precio: 0.0,
                            descripcion: '',
                            origen: '',
                          ),
                        )
                        .origen,
                    filtroTurno: _selectedTurno?.name,
                    puedeEditarPrecios: false,
                  ),
                SizedBox(
                  height: 400,
                  child: _buildReservasBody(snapshot, reservas),
                ),
                const SizedBox(height: 100),
                _buildPaginacion(),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (puedeWhatsapp)
                FloatingActionButton(
                  heroTag: "wa_btn",
                  onPressed: () {
                    /* abrir whatsapp */
                  },
                  backgroundColor: Colors.green.shade600,
                  child: const Icon(Icons.abc),
                  tooltip: 'Contactar agencia',
                ),
              const SizedBox(height: 16),
              if (puedeAgregarReserva)
                FloatingActionButton.extended(
                  heroTag: "pro_btn",
                  onPressed: () {
                    /* registro rápido */
                  },
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Registro rápido'),
                ),
              const SizedBox(height: 16),
              if (puedeAgregarManual)
                FloatingActionButton.extended(
                  heroTag: "manual_btn",
                  onPressed: () {
                    /* agregar reserva manual */
                  },
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Reserva'),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginacion() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _paginaActual > 1
              ? () {
                  _paginaActual--;
                  _cargarReservas();
                }
              : null,
          child: const Text('Anterior'),
        ),
        const SizedBox(width: 16),
        Text(
          '${((_paginaActual - 1) * 10) + 1}-${((_paginaActual - 1) * 10) + (_reservasPaginadas.value.length)} de $_totalReservas',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: _paginaActual < (_totalReservas / 10).ceil()
              ? () {
                  _paginaActual++;
                  _cargarReservas();
                }
              : null,
          child: const Text('Siguiente'),
        ),
      ],
    );
  }

  Widget _buildReservasBody(
    AsyncSnapshot<List<ReservaResumen>> snapshot,
    List<ReservaResumen> reservas,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reservas.isEmpty) {
      return const Center(child: Text('No hay reservas disponibles'));
    }
    return ValueListenableBuilder<List<ReservaResumen>>(
      valueListenable: _reservasPaginadas,
      builder: (context, listaReservas, _) {
        if (listaReservas.isEmpty) {
          return const Center(child: Text('No hay reservas disponibles'));
        }
        return TablaReservasWidget(
          listaReservas: listaReservas,
          mostrarColumnaFecha: true,
          mostrarColumnaObservaciones: true,
        );
      },
    );
  }
}
