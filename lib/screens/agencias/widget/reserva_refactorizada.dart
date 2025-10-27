import 'package:citytourscartagena/core/controller/agencias/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/filtros/servicios_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/controller/reservas/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia/contacto_agencia.dart';
import 'package:citytourscartagena/core/models/agencia/perfil_agencia.dart';
import 'package:citytourscartagena/core/models/reservas/crear_reserva_dto.dart';
import 'package:citytourscartagena/core/models/reservas/precio_servicio.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_contacto.dart';
import 'package:citytourscartagena/core/models/reservas/reserva_resumen.dart';
import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:citytourscartagena/core/services/agencias/agencias_services.dart';
import 'package:citytourscartagena/core/services/filtros/servicios/servicios_service.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/screens/agencias/detalle_agencia.dart';
import 'package:citytourscartagena/screens/agencias/widget/control_precios_widget.dart';
import 'package:citytourscartagena/screens/agencias/widget/encabezado_agencia_widget.dart';
import 'package:citytourscartagena/screens/agencias/widget/filtros.dart';
import 'package:citytourscartagena/screens/agencias/widget/tabla_reservas_widget.dart';
import 'package:citytourscartagena/screens/reservas/crear_reservas_form.dart';
import 'package:citytourscartagena/screens/reservas/crear_reservas_pro_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  int? _selectedTurno;
  int? _selectedEstadoCodigo;
  bool _isTableView = true;
  String? _currentReservaIdNotificada;
  int _paginaActual = 1;
  int _totalReservas = 0;
  bool _hasContact = false;
  List<ContactoAgencia> _contactosAgencia = [];

  late Future<Agenciaperfil?> _futureAgencia;
  late final Future<List<ContactoAgencia>> _contactosFuture;

  final ValueNotifier<List<ReservaResumen>> _reservasPaginadas = ValueNotifier(
    [],
  );

  List<PrecioServicio>? _preciosCargados;
  bool _loadingPrecios = false;

  late ServiciosController _serviciosController;

  @override
  void initState() {
    super.initState();
    _serviciosController = ServiciosController(
      ServiciosService(),
      Provider.of<OperadoresController>(context, listen: false),
      AgenciasService(),
    );
    _serviciosController.cargarTiposServicios(1); // operadorId
    _serviciosController.cargarEstadosReservas();

    // Obtener contactos usando el controlador
    if (widget.codigoAgencia != null) {
      final agenciasController = Provider.of<AgenciasControllerSupabase>(
        context,
        listen: false,
      );
      _contactosFuture = agenciasController.obtenerContactosAgencia(
        widget.codigoAgencia!,
      );

      // Resolver el futuro y actualizar el estado
      _contactosFuture
          .then((contactos) {
            if (!mounted) return;
            setState(() {
              _contactosAgencia = contactos;
              _hasContact = contactos.isNotEmpty;
            });
          })
          .catchError((_) {
            // Si falla, simplemente no mostramos el botón
            if (!mounted) return;
            setState(() {
              _hasContact = false;
            });
          });
    } else {
      _contactosFuture = Future.value([]);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReservas();
      _loadPreciosIfNeeded();
      context.read<OperadoresController>().obtenerAgenciasDeOperador();
    });
    if (widget.codigoAgencia != null) {
      _futureAgencia = Provider.of<ControladorDeltaReservas>(
        context,
        listen: false,
      ).cargarAgenciaPorId(widget.codigoAgencia!);
    }
  }

  Future<void> _loadPreciosIfNeeded() async {
    if (widget.preciosCargados != null) {
      setState(() => _preciosCargados = widget.preciosCargados);
      return;
    }
    if (_preciosCargados != null) return;

    setState(() => _loadingPrecios = true);
    try {
      final operadoresCtrl = context.read<OperadoresController>();
      final operador = await operadoresCtrl.obtenerOperador();

      if (operador == null) {
        debugPrint('No hay operador cargado todavía');
        return;
      }

      final controller = context.read<ControladorDeltaReservas>();
      final precios = await controller.obtenerPreciosServiciosConFallback(
        agenciaCodigo: widget.codigoAgencia ?? 0,
      );

      if (!mounted) return;
      setState(() => _preciosCargados = precios);
    } catch (e) {
      debugPrint('Error al cargar precios: $e');
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

    // Calcular fechas solo cuando el usuario selecciona una fecha específica
    DateTime? fechaInicio;
    DateTime? fechaFin;
    final now = DateTime.now();
    switch (_selectedFilter) {
      case DateFilterType.today:
        fechaInicio = DateTime(now.year, now.month, now.day);
        fechaFin = fechaInicio;
        break;
      case DateFilterType.yesterday:
        fechaInicio = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));
        fechaFin = fechaInicio;
        break;
      case DateFilterType.tomorrow:
        fechaInicio = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));
        fechaFin = fechaInicio;
        break;
      case DateFilterType.lastWeek:
        fechaFin = DateTime(now.year, now.month, now.day);
        fechaInicio = fechaFin.subtract(const Duration(days: 7));
        break;
      case DateFilterType.custom:
        if (_customDate != null) {
          fechaInicio = DateTime(
            _customDate!.year,
            _customDate!.month,
            _customDate!.day,
          );
          fechaFin = fechaInicio;
        }
        break;
      case DateFilterType.all:
        break;
    }
    _totalReservas = await controller.contarReservas(
      operadorId: 1,
      agenciaId: widget.codigoAgencia,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipoServicioCodigo: _selectedTurno,
      estadoCodigo: _selectedEstadoCodigo,
    );

    final reservas = await controller.obtenerReservasPaginadas(
      operadorId: 1,
      agenciaId: widget.codigoAgencia,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      tipoServicioCodigo: _selectedTurno,
      estadoCodigo: _selectedEstadoCodigo,
      pagina: _paginaActual,
      tamanoPagina: 10,
    );

    _reservasPaginadas.value = reservas;
  }

  Future<void> _crearReserva({
    required CrearReservaDto dto,
    required List<ReservaContacto> contactos,
  }) async {
    try {
      final controller = Provider.of<ControladorDeltaReservas>(
        context,
        listen: false,
      );

      final reservaId = await controller.crearReservaCompleta(
        dto: dto,
        contactos: contactos,
      );

      debugPrint('✅ Reserva creada con ID: $reservaId');

      // Opcional: recargar la tabla o lista
      await _cargarReservas();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reserva creada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al crear reserva: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear reserva: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

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

  Future<void> _abrirContactoAgencia() async {
    if (_contactosAgencia.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay contactos disponibles para esta agencia'),
        ),
      );
      return;
    }

    // Si hay solo un contacto, abrirlo directamente
    if (_contactosAgencia.length == 1) {
      final contacto = _contactosAgencia.first;
      await _abrirContactoEspecifico(contacto);
      return;
    }

    // Si hay múltiples contactos, mostrar diálogo para seleccionar
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Contacto'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _contactosAgencia.length,
            itemBuilder: (context, index) {
              final contacto = _contactosAgencia[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.contact_phone, color: Colors.green),
                ),
                title: Text(contacto.tipoContacto.descripcion),
                subtitle: Text(contacto.descripcion),
                onTap: () {
                  Navigator.of(context).pop();
                  _abrirContactoEspecifico(contacto);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirContactoEspecifico(ContactoAgencia contacto) async {
    final descripcion = contacto.descripcion;

    // Intentar como link primero
    if (descripcion.contains('http') || descripcion.contains('www')) {
      final uri = Uri.parse(
        descripcion.startsWith('http') ? descripcion : 'https://$descripcion',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    // Intentar como teléfono/WhatsApp
    var tel = descripcion.replaceAll(RegExp(r'[^0-9+]'), '');
    if (tel.isNotEmpty) {
      if (!tel.startsWith('+')) tel = '+51$tel'; // Prefijo del país
      final uri = Uri.parse('https://wa.me/$tel');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el contacto')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ControladorDeltaReservas>(context);
    // Simulación de roles y permisos (ajusta según tu lógica real)
    final bool puedeAgregarReserva = true;
    final bool puedeAgregarManual = true;
    final String? nombreAgencia = widget.nombreAgencia;

    return StreamBuilder<List<ReservaResumen>>(
      stream: controller.reservasStream,
      builder: (context, snapshot) {
        String titulo = nombreAgencia ?? 'Reservas';
        final reservas = snapshot.data ?? [];
        if (reservas.isNotEmpty && widget.codigoAgencia != null) {
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
              if (widget.codigoAgencia != null)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetalleAgenciaScreen(
                          agenciaId: widget.codigoAgencia!,
                        ),
                      ),
                    );
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
                      _paginaActual = 1; // Resetear página al cambiar filtro
                    });
                    _cargarReservas(); // Cargar reservas en tiempo real al cambiar filtro
                  },
                  selectedTurno: _selectedTurno,
                  onTurnoChanged: (turno) {
                    setState(() {
                      _selectedTurno = turno;
                      _paginaActual = 1; // Resetear página al cambiar turno
                    });
                    _cargarReservas(); // Cargar reservas en tiempo real al cambiar turno
                  },
                  tiposServicios: _serviciosController.tiposServicios,
                  selectedEstadoCodigo: _selectedEstadoCodigo,
                  onEstadoChanged: (codigo) {
                    setState(() {
                      _selectedEstadoCodigo = codigo;
                      _paginaActual = 1; // Resetear página al cambiar estado
                    });
                    _cargarReservas(); // Cargar reservas en tiempo real al cambiar estado
                  },
                  estadosReservas: _serviciosController.estadosReservas,
                ),
                if (widget.codigoAgencia != null)
                  FutureBuilder<Agenciaperfil?>(
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
                      // Sincroniza con el estado para que el SpeedDial lo use

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
                    filtroTurno: _selectedTurno != null
                        ? _serviciosController.tiposServicios
                              .firstWhere(
                                (t) => t.codigo == _selectedTurno,
                                orElse: () => TipoServicio(
                                  codigo: -1,
                                  descripcion: 'Desconocido',
                                ),
                              )
                              .descripcion
                        : null,
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
          floatingActionButton: SpeedDial(
            icon: Icons.more_vert,
            activeIcon: Icons.close,
            spacing: 12,
            spaceBetweenChildren: 12,
            children: [
              // WhatsApp
              SpeedDialChild(
                visible: _hasContact, // ← no cambia la cantidad de children
                label: 'Contactar agencia',
                child: const Icon(Icons.chat),
                backgroundColor: Colors.green.shade600,
                onTap: _hasContact ? _abrirContactoAgencia : null,
              ),

              if (puedeAgregarReserva)
                SpeedDialChild(
                  label: 'Registro rápido',
                  child: const Icon(Icons.auto_awesome),
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('Crear Reserva')),
                          body: const CrearReservasProForm(),
                        ),
                      ),
                    );
                  },
                ),
              if (puedeAgregarManual)
                SpeedDialChild(
                  label: 'Agregar Reserva',
                  child: const Icon(Icons.add),
                  /*
                FloatingActionButton.extended(
                  heroTag: "manual_btn",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider<ServiciosController>.value(
                              value: _serviciosController,
                            ),
                            ChangeNotifierProvider<OperadoresController>.value(
                              value: Provider.of<OperadoresController>(context, listen: false),
                            ),
                          ],
                          child: const CrearReservasForm(),
                        ),
                      ),
                    );
                  },
*/
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MultiProvider(
                          providers: [
                            ChangeNotifierProvider<ServiciosController>.value(
                              value: _serviciosController,
                            ),
                            ChangeNotifierProvider<OperadoresController>.value(
                              value: Provider.of<OperadoresController>(
                                context,
                                listen: false,
                              ),
                            ),
                          ],
                          child: const CrearReservasForm(),
                        ),
                      ),
                    );
                  },
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
    // Mostrar columna de fecha solo si no es filtro específico de fecha
    final mostrarFecha =
        _selectedFilter != DateFilterType.today &&
        _selectedFilter != DateFilterType.custom;
    // Mostrar columna de servicio solo si no está filtrando por turno específico
    final mostrarServicio = _selectedTurno == null;
    return ValueListenableBuilder<List<ReservaResumen>>(
      valueListenable: _reservasPaginadas,
      builder: (context, listaReservas, _) {
        return TablaReservasWidget(
          listaReservas: listaReservas,
          mostrarColumnaFecha: mostrarFecha,
          mostrarColumnaServicio: mostrarServicio,
          mostrarColumnaObservaciones: true,
          onActualizarObservaciones: (reserva, obs) async {
            final controller = Provider.of<ControladorDeltaReservas>(
              context,
              listen: false,
            );
            final authController = Provider.of<AuthController>(
              context,
              listen: false,
            );
            await controller.actualizarObservaciones(
              reservaId: reserva.reservaCodigo,
              observaciones: obs,
              usuarioId: authController.appUser?.id as int? ?? 1,
            );
            // Actualizar la lista local para reflejar el cambio en tiempo real
            final reservasActuales = _reservasPaginadas.value;
            final index = reservasActuales.indexWhere(
              (r) => r.reservaCodigo == reserva.reservaCodigo,
            );
            if (index != -1) {
              reservasActuales[index] = reservasActuales[index].copyWith(
                observaciones: obs,
              );
              _reservasPaginadas.value = List.from(reservasActuales);
            }
          },
          onProcesarPago: (reserva) async {
            final controller = Provider.of<ControladorDeltaReservas>(
              context,
              listen: false,
            );
            final authController = Provider.of<AuthController>(
              context,
              listen: false,
            );
            final result = await controller.procesarPago(
              reserva: reserva,
              pagadoPor: authController.appUser?.id as int?,
            );
            // Recargar las reservas para actualizar el estado
            await _cargarReservas();
            return result;
          },
          onObtenerColores: () => Provider.of<ControladorDeltaReservas>(
            context,
            listen: false,
          ).obtenerColores(),
          onActualizarColor: (reservaId, colorCodigo, usuarioId) =>
              Provider.of<ControladorDeltaReservas>(
                context,
                listen: false,
              ).actualizarColorReserva(
                reservaId: reservaId,
                colorCodigo: colorCodigo,
                usuarioId: usuarioId,
              ),
          onReload: () => _cargarReservas(),
          usuarioId:
              Provider.of<AuthController>(context, listen: false).appUser?.id
                  as int?,
        );
      },
    );
  }
}
