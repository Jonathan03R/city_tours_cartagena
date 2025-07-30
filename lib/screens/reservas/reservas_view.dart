import 'dart:async';

import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart'
    hide AgenciaConReservas;
import 'package:citytourscartagena/core/services/pdf_export_service.dart';
import 'package:citytourscartagena/core/widgets/crear_agencia_form.dart';
import 'package:citytourscartagena/core/widgets/estado_filter_button.dart';
import 'package:citytourscartagena/core/widgets/table_only_view_screen.dart';
import 'package:citytourscartagena/core/widgets/turno_filter_button.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/controller/reservas_controller.dart';
import '../../core/widgets/add_reserva_pro_form.dart';
import '../../core/widgets/date_filter_buttons.dart';
import '../../core/widgets/reserva_card_item.dart';
import '../../core/widgets/reserva_details.dart';
import '../../core/widgets/reservas_table.dart';

class ReservasView extends StatefulWidget {
  final TurnoType? turno;
  final AgenciaConReservas? agencia;
  final VoidCallback? onBack;
  const ReservasView({super.key, this.turno, this.agencia, this.onBack});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  bool _isTableView = true;
  bool _editandoPrecio = false;
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _precioMananaController = TextEditingController();
  final TextEditingController _precioTardeController = TextEditingController();

  String? _editingTurno; // 'manana' o 'tarde'

  AgenciaConReservas? _currentAgencia;
  StreamSubscription<List<AgenciaConReservas>>? _agenciasSub;

  @override
  void initState() {
    super.initState();
    _currentAgencia = widget.agencia;

    final agenciasCtrl = context.read<AgenciasController>();
    _agenciasSub = agenciasCtrl.agenciasConReservasStream.listen((lista) {
      if (widget.agencia != null) {
        final updated = lista.firstWhereOrNull(
          (ar) => ar.agencia.id == widget.agencia!.agencia.id,
        );
        if (updated != null && mounted) {
          setState(() {
            _currentAgencia = updated;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = Provider.of<ReservasController>(context, listen: false);
      ctrl.updateFilter(
        DateFilterType.today,
        agenciaId: widget.agencia?.id,
        turno: widget.turno,
      );
    });
  }

  @override
  void dispose() {
    _agenciasSub?.cancel();
    _precioController.dispose();
    _precioMananaController.dispose();
    _precioTardeController.dispose();
    super.dispose();
  }

  void _onFilterChanged(
    DateFilterType filter,
    DateTime? date, {
    TurnoType? turno,
  }) {
    final ctrl = Provider.of<ReservasController>(context, listen: false);
    ctrl.updateFilter(
      filter,
      date: date,
      agenciaId: widget.agencia?.id,
      turno: turno ?? ctrl.turnoFilter,
    );
  }

  void _showTableOnlyView() {
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TableOnlyViewScreen(
          turno: reservasController.turnoFilter,
          selectedFilter: reservasController.selectedFilter,
          customDate: reservasController.customDate,
          agenciaId: widget.agencia?.id,
          onUpdate: () {
            reservasController.updateFilter(
              reservasController.selectedFilter,
              date: reservasController.customDate,
              agenciaId: widget.agencia?.id,
              turno: widget.turno,
            );
          },
        ),
      ),
    );
  }

  void _editarAgencia() {
    // final agencia = widget.agencia!;
    final agencia = _currentAgencia!;
    final parentCtx = context;
    showDialog(
      context: context,
      builder: (_) => CrearAgenciaForm(
        initialNombre: agencia.nombre,
        initialImagenUrl: agencia.imagenUrl,
        initialPrecioPorAsientoTurnoManana: agencia.precioPorAsientoTurnoManana,
        initialPrecioPorAsientoTurnoTarde: agencia.precioPorAsientoTurnoTarde,
        initialTipoDocumento: agencia.tipoDocumento,
        initialNumeroDocumento: agencia.numeroDocumento,
        initialNombreBeneficiario: agencia.nombreBeneficiario,
        onCrear:
            (
              nuevoNombre,
              nuevaImagenFile,
              nuevoPrecioManana,
              nuevoPrecioTarde,
              nuevoTipoDocumento,
              nuevoNumeroDocumento,
              nuevoNombreBeneficiario,
            ) async {
              final agenciasController = Provider.of<AgenciasController>(
                parentCtx,
                listen: false,
              );
              await agenciasController.updateAgencia(
                agencia.id,
                nuevoNombre,
                nuevaImagenFile?.path,
                agencia.imagenUrl,
                newPrecioPorAsientoTurnoManana: nuevoPrecioManana,
                newPrecioPorAsientoTurnoTarde: nuevoPrecioTarde,
                tipoDocumento: nuevoTipoDocumento,
                numeroDocumento: nuevoNumeroDocumento,
                nombreBeneficiario: nuevoNombreBeneficiario,
              );
              Navigator.of(parentCtx).pop();
              ScaffoldMessenger.of(parentCtx).showSnackBar(
                const SnackBar(
                  content: Text('Agencia actualizada correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reservasController = context.watch<ReservasController>();
    final configuracionController = context.watch<ConfiguracionController>();
    final configuracion = configuracionController.configuracion;
    final authRole = context.read<AuthController>();

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null && widget.agencia == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        automaticallyImplyLeading: widget.onBack == null,
        title: _currentAgencia != null
            ? Text(
                'Reservas de ${_currentAgencia!.nombre}',
                overflow: TextOverflow.ellipsis,
              )
            : const Text('Reservas'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTableView ? Icons.view_list : Icons.table_chart),
            onPressed: () {
              setState(() {
                _isTableView = !_isTableView;
              });
            },
            tooltip: _isTableView ? 'Vista de lista' : 'Vista de tabla',
          ),
          if (widget.agencia != null) ...[
            if (authRole.hasPermission(Permission.edit_agencias))
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _editarAgencia,
                tooltip: 'Editar agencia',
              ),
          ],
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _showTableOnlyView,
            tooltip: 'Ver tabla completa',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              reservasController.updateFilter(
                reservasController.selectedFilter,
                date: reservasController.customDate,
                agenciaId: widget.agencia?.id,
                turno: reservasController.turnoFilter,
              );
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TurnoFilterButtons(
                  selectedTurno: reservasController.turnoFilter,
                  onTurnoChanged: (nuevoTurno) {
                    reservasController.updateFilter(
                      reservasController.selectedFilter,
                      date: reservasController.customDate,
                      agenciaId: widget.agencia?.id,
                      turno: nuevoTurno,
                    );
                  },
                ),
                const SizedBox(width: 8),
                EstadoFilterButtons(
                  selectedEstado: reservasController.estadoFilter,
                  onEstadoChanged: (nuevoEstado) {
                    reservasController.updateFilter(
                      reservasController.selectedFilter,
                      date: reservasController.customDate,
                      agenciaId: widget.agencia?.id,
                      turno: reservasController.turnoFilter,
                      estado: nuevoEstado,
                    );
                  },
                ),
              ],
            ),
            CompactDateFilterButtons(
              selectedFilter: reservasController.selectedFilter,
              customDate: reservasController.customDate,
              selectedTurno: reservasController.turnoFilter,
              onFilterChanged: _onFilterChanged,
            ),
            if (_currentAgencia != null) _buildAgencyHeader(_currentAgencia!),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return isWide
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _getFilterTitle(
                                  reservasController.selectedFilter,
                                  reservasController.customDate,
                                  reservasController.turnoFilter,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            _buildRightControls(
                              reservasController.currentReservas,
                              configuracion,
                              reservasController
                                  .turnoFilter, // NUEVO: Pasar turno filtrado
                              reservasController,
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRightControls(
                              reservasController.currentReservas,
                              configuracion,
                              reservasController
                                  .turnoFilter, // NUEVO: Pasar turno filtrado
                              reservasController,
                            ),
                            Text(
                              _getFilterTitle(
                                reservasController.selectedFilter,
                                reservasController.customDate,
                                reservasController.turnoFilter,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                },
              ),
            ),
            StreamBuilder<List<ReservaConAgencia>>(
              stream: reservasController.filteredReservasStream,
              builder: (context, snapshot) {
                if (reservasController.isFetchingPage) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final currentReservas = snapshot.data ?? [];

                if (currentReservas.isEmpty &&
                    !reservasController.isFetchingPage) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_chart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay reservas para mostrar',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    _isTableView
                        ? ReservasTable(
                            turno: reservasController.turnoFilter,
                            reservas: currentReservas,
                            agenciaId: widget.agencia?.id,
                            onUpdate: () {
                              reservasController.updateFilter(
                                reservasController.selectedFilter,
                                date: reservasController.customDate,
                                agenciaId: widget.agencia?.id,
                                turno: reservasController.turnoFilter,
                              );
                            },
                            currentFilter: reservasController.selectedFilter,
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: currentReservas.length,
                            itemBuilder: (ctx, i) {
                              return ReservaCardItem(
                                reserva: currentReservas[i],
                                onTap: () =>
                                    _showReservaDetails(currentReservas[i]),
                              );
                            },
                          ),
                    // Controles de paginación (mantener igual)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed:
                                reservasController.canGoPrevious &&
                                    !reservasController.isFetchingPage
                                ? reservasController.previousPage
                                : null,
                            child:
                                reservasController.isFetchingPage &&
                                    reservasController.canGoPrevious
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Anterior'),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Página ${reservasController.currentPage}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed:
                                reservasController.canGoNext &&
                                    !reservasController.isFetchingPage
                                ? reservasController.nextPage
                                : null,
                            child:
                                reservasController.isFetchingPage &&
                                    reservasController.canGoNext
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Siguiente'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Elementos por página:'),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: reservasController.itemsPerPage,
                            items: const [10, 20, 50].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                reservasController.setItemsPerPage(newValue);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      // floatingActionButton: widget.agencia == null
      //     ? Column(
      //         mainAxisAlignment: MainAxisAlignment.end,
      //         children: [
      //           FloatingActionButton.extended(
      //             onPressed: _showAddReservaProForm,
      //             backgroundColor: Colors.purple.shade600,
      //             foregroundColor: Colors.white,
      //             icon: const Icon(Icons.auto_awesome),
      //             label: const Text('registro rapido'),
      //             heroTag: "pro_button",
      //           ),
      //           const SizedBox(height: 16),
      //         ],
      //       )
      //     : null,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _showAddReservaProForm,
            backgroundColor: Colors.purple.shade600,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('registro rapido'),
            heroTag: "pro_button",
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAgencyHeader(AgenciaConReservas agencia) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (agencia.imagenUrl != null && agencia.imagenUrl!.isNotEmpty)
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(agencia.imagenUrl!),
              backgroundColor: Colors.grey.shade200,
            )
          else
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.shade100,
              child: Icon(
                Icons.business,
                size: 50,
                color: Colors.green.shade600,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agencia.nombre,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${agencia.totalReservas} reserva${agencia.totalReservas != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterTitle(
    DateFilterType selectedFilter,
    DateTime? customDate,
    TurnoType? selectedTurno,
  ) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    String formatearFecha(DateTime fecha) {
      return '${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}';
    }

    String dateText;
    switch (selectedFilter) {
      case DateFilterType.all:
        dateText = 'Todas las reservas';
        break;
      case DateFilterType.lastWeek:
        dateText = 'Reservas de la última semana';
        break;
      case DateFilterType.today:
        dateText = formatearFecha(DateTime.now());
        break;
      case DateFilterType.yesterday:
        dateText = formatearFecha(
          DateTime.now().subtract(const Duration(days: 1)),
        );
        break;
      case DateFilterType.tomorrow:
        dateText = formatearFecha(DateTime.now().add(const Duration(days: 1)));
        break;
      case DateFilterType.custom:
        dateText = customDate != null
            ? formatearFecha(customDate)
            : 'Fecha personalizada';
        break;
    }

    String turnoText = '';
    if (selectedTurno != null) {
      turnoText = selectedTurno == TurnoType.manana
          ? ' 🌅 (Mañana)'
          : ' 🌆 (Tarde)';
    }
    return '$dateText$turnoText';
  }

  void _showReservaDetails(ReservaConAgencia reserva) {
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReservaDetails(
        reserva: reserva,
        onUpdate: () {
          reservasController.updateFilter(
            reservasController.selectedFilter,
            date: reservasController.customDate,
            agenciaId: widget.agencia?.id,
            turno: reservasController.turnoFilter,
          );
        },
      ),
    );
  }

  void _showAddReservaProForm() {
    final reservasController = Provider.of<ReservasController>(
      context,
      listen: false,
    );

    debugPrint('la agencia es ${widget.agencia?.agencia.nombre}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReservaProForm(
        agencia: widget.agencia?.agencia,
        turno: reservasController.turnoFilter,
        onAdd: () {
          reservasController.updateFilter(
            reservasController.selectedFilter,
            date: reservasController.customDate,
            agenciaId: widget.agencia?.id,
            turno: reservasController.turnoFilter,
          );
        },
      ),
    );
  }

  // Future<void> _exportToExcel(List<ReservaConAgencia> reservas) async {
  //   try {
  //     var status = await Permission.manageExternalStorage.request();
  //     if (!status.isGranted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Permiso denegado. No se puede guardar el archivo'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       return;
  //     }
  //     final excel = xls.Excel.createExcel();
  //     final sheet = excel['Reservas'];
  //     sheet.appendRow([
  //       xls.TextCellValue('HOTEL'),
  //       xls.TextCellValue('CLIENTE'),
  //       xls.TextCellValue('FECHA'),
  //       xls.TextCellValue('PAX'),
  //       xls.TextCellValue('SALDO'),
  //       xls.TextCellValue('AGENCIA'),
  //       xls.TextCellValue('OBSERVACIONES'),
  //       xls.TextCellValue('ESTADO'),
  //     ]);
  //     for (var r in reservas) {
  //       sheet.appendRow([
  //         xls.TextCellValue(r.hotel.isEmpty ? 'Sin hotel' : r.hotel),
  //         xls.TextCellValue(r.nombreCliente),
  //         xls.TextCellValue(Formatters.formatDate(r.fecha)),
  //         xls.IntCellValue(r.pax),
  //         xls.DoubleCellValue(r.saldo),
  //         xls.TextCellValue(r.nombreAgencia),
  //         xls.TextCellValue(
  //           r.observacion.isEmpty ? 'Sin observaciones' : r.observacion,
  //         ),
  //         xls.TextCellValue(Formatters.getEstadoText(r.estado)),
  //       ]);
  //     }
  //     final bytes = excel.encode();
  //     if (bytes == null) return;
  //     final directory = Directory('/storage/emulated/0/Download');
  //     if (!directory.existsSync()) {
  //       directory.createSync(recursive: true);
  //     }
  //     final filePath =
  //         '${directory.path}/reservas_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  //     final file = File(filePath);
  //     await file.writeAsBytes(bytes);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Archivo guardado en Descargas')),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text('Error exportando: $e')));
  //     }
  //   }
  // }

  void _guardarNuevoPrecio(Configuracion? configuracion) async {
    if (widget.agencia != null) {
      final agenciasController = Provider.of<AgenciasController>(
        context,
        listen: false,
      );
      final mText = _precioMananaController.text.trim();
      final tText = _precioTardeController.text.trim();
      final double? manana = mText.isEmpty ? null : double.tryParse(mText);
      final double? tarde = tText.isEmpty ? null : double.tryParse(tText);

      if ((mText.isNotEmpty && (manana == null || manana <= 0)) ||
          (tText.isNotEmpty && (tarde == null || tarde <= 0))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ingresa precios válidos o deja vacío para usar global',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        await agenciasController.updateAgencia(
          widget.agencia!.id,
          widget.agencia!.nombre,
          null,
          widget.agencia!.imagenUrl,
          newPrecioPorAsientoTurnoManana: manana,
          newPrecioPorAsientoTurnoTarde: tarde,
          tipoDocumento: widget.agencia!.tipoDocumento,
          numeroDocumento: widget.agencia!.numeroDocumento,
          nombreBeneficiario: widget.agencia!.nombreBeneficiario,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Precio de agencia actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          final old = _currentAgencia ?? widget.agencia!;
          final updatedAg = old.agencia.copyWith(
            precioPorAsientoTurnoManana: manana,
            precioPorAsientoTurnoTarde: tarde,
          );
          _currentAgencia = AgenciaConReservas(
            agencia: updatedAg,
            totalReservas: old.totalReservas,
          );
          _editandoPrecio = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando precio de agencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
  }

  void _guardarNuevoPrecioGlobal(
    String turno,
    Configuracion? configuracion,
  ) async {
    final input = _precioController.text.trim();
    final nuevoPrecio = double.tryParse(input);

    if (nuevoPrecio == null || nuevoPrecio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un precio válido (p.ej. 55.50)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final configController = Provider.of<ConfiguracionController>(
        context,
        listen: false,
      );

      if (turno == 'manana') {
        await configController.actualizarPrecioManana(nuevoPrecio);
      } else {
        await configController.actualizarPrecioTarde(nuevoPrecio);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Precio global de $turno actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _editandoPrecio = false;
        _editingTurno = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando precio global: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // MÉTODO ARREGLADO: Ahora respeta el filtro de turno
  Widget _buildRightControls(
    List<ReservaConAgencia> currentReservas,
    Configuracion? configuracion,
    TurnoType? turnoFilter,
    ReservasController
    reservasController, // NUEVO: Recibir el controlador completo
  ) {
    final authController = context.read<AuthController>();
    // final isColaborador = authController.appUser?.roles.contains(Roles.colaborador) ?? false;
    // final isAdmin = authController.appUser?.roles.contains(Roles.admin) ?? false;
    // final isAgencia = authController.appUser?.roles.contains(Roles.agencia) ?? false;
    // final isTrabajador = authController.appUser?.roles.contains(Roles.trabajador) ?? false;

    final ac = _currentAgencia ?? widget.agencia;
    final ag = ac?.agencia;

    final showManana =
        ag != null && (turnoFilter == null || turnoFilter == TurnoType.manana);
    final showTarde =
        ag != null && (turnoFilter == null || turnoFilter == TurnoType.tarde);

    final double? globalPriceManana =
        configuracion?.precioGeneralAsientoTemprano;
    final double? globalPriceTarde = configuracion?.precioGeneralAsientoTarde;

    // NUEVO: Determinar si hay selecciones activas
    final hasSelections =
        reservasController.isSelectionMode &&
        reservasController.selectedCount > 0;

    // NUEVO: Determinar qué texto mostrar en el contador
    String reservasText;
    if (hasSelections) {
      reservasText =
          '${reservasController.selectedCount} seleccionada${reservasController.selectedCount != 1 ? 's' : ''}';
    } else {
      reservasText =
          '${currentReservas.length} reserva${currentReservas.length != 1 ? 's' : ''}';
    }

    // NUEVO: Determinar qué texto mostrar en el botón
    String buttonText;
    if (hasSelections) {
      buttonText = "Exportar Seleccionadas";
    } else {
      buttonText = "Exportar";
    }

    debugPrint(
      '🔍 Filtro turno: $turnoFilter, showManana: $showManana, showTarde: $showTarde',
    );
    debugPrint(
      '💰 Precios globales - Mañana: $globalPriceManana, Tarde: $globalPriceTarde',
    );

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reservas y botón export - ACTUALIZADO
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reservasText, // NUEVO: Texto dinámico
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasSelections
                      ? Colors.blue.shade700
                      : Colors.black, // NUEVO: Color dinámico
                ),
              ),
              if (authController.hasPermission(Permission.export_reservas))
                /// boton para exportar reservas
                ElevatedButton.icon(
                  onPressed: () async {
                    List<ReservaConAgencia> reservasParaExportar;

                    // NUEVA LÓGICA: Decidir qué reservas exportar
                    if (hasSelections) {
                      // Si hay selecciones, usar solo las seleccionadas
                      reservasParaExportar =
                          reservasController.selectedReservas;
                      debugPrint(
                        '📄 Exportando ${reservasParaExportar.length} reservas SELECCIONADAS',
                      );
                    } else {
                      // Si no hay selecciones, usar todas las filtradas (comportamiento original)
                      reservasParaExportar = await reservasController
                          .getAllFilteredReservasSinPaginacion();
                      debugPrint(
                        '📄 Exportando ${reservasParaExportar.length} reservas FILTRADAS',
                      );
                    }

                    if (!mounted) return;

                    final pdfService = PdfExportService();
                    await pdfService.exportarReservasConAgencia(
                      reservasConAgencia:
                          reservasParaExportar, // NUEVO: Lista dinámica
                      context: context,
                      filtroFecha: reservasController.selectedFilter,
                      fechaPersonalizada: reservasController.customDate,
                      turnoFiltrado: reservasController.turnoFilter,
                      agenciaEspecifica: _currentAgencia?.agencia,
                    );
                  },
                  icon: Icon(
                    hasSelections
                        ? Icons.file_download_outlined
                        : Icons.file_download, // NUEVO: Ícono dinámico
                    size: 20,
                  ),
                  label: Text(buttonText), // NUEVO: Texto dinámico
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSelections
                        ? Colors.blue.shade600
                        : Colors.green.shade600, // NUEVO: Color dinámico
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Resto del código sin cambios...
          if (ag != null) ...[
            if (showManana)
              _buildPriceRow(
                'Mañana',
                ag.precioPorAsientoTurnoManana ?? globalPriceManana ?? 0.0,
                ag.precioPorAsientoTurnoManana == null,
                Icons.wb_sunny,
                Colors.orange,
              ),
            if (showTarde)
              _buildPriceRow(
                'Tarde',
                ag.precioPorAsientoTurnoTarde ?? globalPriceTarde ?? 0.0,
                ag.precioPorAsientoTurnoTarde == null,
                Icons.wb_twilight,
                Colors.blue,
              ),

            if (_editandoPrecio) ...[
              const SizedBox(height: 12),
              if (showManana) ...[
                TextField(
                  controller: _precioMananaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Precio mañana',
                    hintText:
                        'Vacío = usar global (${globalPriceManana?.toStringAsFixed(2) ?? '0.00'})',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.wb_sunny,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (showTarde) ...[
                TextField(
                  controller: _precioTardeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Precio tarde',
                    hintText:
                        'Vacío = usar global (${globalPriceTarde?.toStringAsFixed(2) ?? '0.00'})',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.wb_twilight,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ],
            ],
            if (authController.hasPermission(Permission.edit_agencias))
              Align(
                alignment: Alignment.centerRight,
                child: _editandoPrecio
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade600,
                            ),
                            tooltip: 'Cancelar',
                            onPressed: () {
                              setState(() {
                                _editandoPrecio = false;
                                _precioMananaController.clear();
                                _precioTardeController.clear();
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.check,
                              color: Colors.green.shade600,
                            ),
                            tooltip: 'Guardar',
                            onPressed: () => _guardarNuevoPrecio(configuracion),
                          ),
                        ],
                      )
                    : IconButton(
                        icon: Icon(Icons.edit, color: Colors.grey.shade800),
                        tooltip: 'Editar precios',
                        onPressed: () {
                          setState(() {
                            _precioMananaController.text =
                                ag.precioPorAsientoTurnoManana?.toStringAsFixed(
                                  2,
                                ) ??
                                '';
                            _precioTardeController.text =
                                ag.precioPorAsientoTurnoTarde?.toStringAsFixed(
                                  2,
                                ) ??
                                '';
                            _editandoPrecio = true;
                          });
                        },
                      ),
              ),
          ] else ...[
            _buildGlobalPriceSection(
              configuracion,
              globalPriceManana,
              globalPriceTarde,
              turnoFilter,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String turno,
    double precio,
    bool esHeredado,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$turno: \$${precio.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: esHeredado ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
          ),
          if (esHeredado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Global',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  // MÉTODO ARREGLADO: Respeta el filtro de turno para precios globales
  Widget _buildGlobalPriceSection(
    Configuracion? configuracion,
    double? globalPriceManana,
    double? globalPriceTarde,
    TurnoType? turnoFilter, // NUEVO: Recibir filtro de turno
  ) {
    final authController = context.read<AuthController>();
    // final isColaborador = authController.appUser?.roles.contains(Roles.colaborador) ?? false;
    // final isAdmin = authController.appUser?.roles.contains(Roles.admin) ?? false;
    // final isAgencia = authController.appUser?.roles.contains(Roles.agencia) ?? false;
    // final isTrabajador = authController.appUser?.roles.contains(Roles.trabajador) ?? false;
    // ARREGLADO: Solo mostrar el precio del turno filtrado, o ambos si no hay filtro
    final showManana = turnoFilter == null || turnoFilter == TurnoType.manana;
    final showTarde = turnoFilter == null || turnoFilter == TurnoType.tarde;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Precios Globales:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Precio Mañana Global - Solo si debe mostrarse
        if (showManana)
          Row(
            children: [
              Icon(Icons.wb_sunny, color: Colors.orange.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: _editandoPrecio && _editingTurno == 'manana'
                    ? TextField(
                        controller: _precioController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) =>
                            _guardarNuevoPrecioGlobal('manana', configuracion),
                      )
                    : Text(
                        'Mañana: \$${globalPriceManana?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              if (authController.hasPermission(Permission.edit_configuracion))
                IconButton(
                  icon: Icon(
                    _editandoPrecio && _editingTurno == 'manana'
                        ? Icons.check
                        : Icons.edit,
                    color: Colors.grey.shade800,
                    size: 18,
                  ),
                  onPressed: () {
                    if (_editandoPrecio && _editingTurno == 'manana') {
                      _guardarNuevoPrecioGlobal('manana', configuracion);
                    } else {
                      setState(() {
                        _precioController.text =
                            globalPriceManana?.toStringAsFixed(2) ?? '0.00';
                        _editandoPrecio = true;
                        _editingTurno = 'manana';
                      });
                    }
                  },
                ),
            ],
          ),

        // Espaciado solo si ambos se muestran
        if (showManana && showTarde) const SizedBox(height: 8),

        // Precio Tarde Global - Solo si debe mostrarse
        if (showTarde)
          Row(
            children: [
              Icon(Icons.wb_twilight, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: _editandoPrecio && _editingTurno == 'tarde'
                    ? TextField(
                        controller: _precioController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) =>
                            _guardarNuevoPrecioGlobal('tarde', configuracion),
                      )
                    : Text(
                        'Tarde: \$${globalPriceTarde?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              if (authController.hasPermission(Permission.edit_configuracion))
                IconButton(
                  icon: Icon(
                    _editandoPrecio && _editingTurno == 'tarde'
                        ? Icons.check
                        : Icons.edit,
                    color: Colors.grey.shade800,
                    size: 18,
                  ),
                  onPressed: () {
                    if (_editandoPrecio && _editingTurno == 'tarde') {
                      _guardarNuevoPrecioGlobal('tarde', configuracion);
                    } else {
                      setState(() {
                        _precioController.text =
                            globalPriceTarde?.toStringAsFixed(2) ?? '0.00';
                        _editandoPrecio = true;
                        _editingTurno = 'tarde';
                      });
                    }
                  },
                ),
            ],
          ),
      ],
    );
  }
}

// CompactDateFilterButtons permanece igual...
enum MoreFilterOption { yesterday, tomorrow, lastWeek }

class CompactDateFilterButtons extends StatelessWidget {
  final DateFilterType selectedFilter;
  final DateTime? customDate;
  final TurnoType? selectedTurno;
  final Function(DateFilterType, DateTime?, {TurnoType? turno}) onFilterChanged;

  const CompactDateFilterButtons({
    super.key,
    required this.selectedFilter,
    this.customDate,
    this.selectedTurno,
    required this.onFilterChanged,
  });

  String _getButtonText(DateFilterType filter, DateTime? date) {
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    String formatearFecha(DateTime fecha) {
      return '${fecha.day} de ${meses[fecha.month - 1]}';
    }

    switch (filter) {
      case DateFilterType.all:
        return 'Todas';
      case DateFilterType.today:
        return 'Hoy';
      case DateFilterType.yesterday:
        return 'Ayer';
      case DateFilterType.tomorrow:
        return 'Mañana';
      case DateFilterType.lastWeek:
        return 'Última Semana';
      case DateFilterType.custom:
        return date != null ? formatearFecha(date) : 'Fecha Específica';
    }
  }

  String _getMoreFilterOptionText(MoreFilterOption option) {
    switch (option) {
      case MoreFilterOption.yesterday:
        return 'Ayer';
      case MoreFilterOption.tomorrow:
        return 'Mañana';
      case MoreFilterOption.lastWeek:
        return 'Última Semana';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMoreFiltersSelected =
        selectedFilter == DateFilterType.yesterday ||
        selectedFilter == DateFilterType.tomorrow ||
        selectedFilter == DateFilterType.lastWeek;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton(
            context,
            DateFilterType.today,
            _getButtonText(DateFilterType.today, null),
            selectedFilter == DateFilterType.today,
            onPressed: () =>
                onFilterChanged(DateFilterType.today, null, turno: null),
          ),
          _buildFilterButton(
            context,
            DateFilterType.all,
            _getButtonText(DateFilterType.all, null),
            selectedFilter == DateFilterType.all,
            onPressed: () =>
                onFilterChanged(DateFilterType.all, null, turno: null),
          ),
          _buildFilterButton(
            context,
            DateFilterType.custom,
            customDate != null
                ? _getButtonText(DateFilterType.custom, customDate)
                : 'Fecha Específica',
            selectedFilter == DateFilterType.custom,
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: customDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                onFilterChanged(DateFilterType.custom, pickedDate, turno: null);
              }
            },
          ),
          PopupMenuButton<MoreFilterOption>(
            onSelected: (MoreFilterOption item) {
              switch (item) {
                case MoreFilterOption.yesterday:
                  onFilterChanged(DateFilterType.yesterday, null, turno: null);
                  break;
                case MoreFilterOption.tomorrow:
                  onFilterChanged(DateFilterType.tomorrow, null, turno: null);
                  break;
                case MoreFilterOption.lastWeek:
                  onFilterChanged(DateFilterType.lastWeek, null, turno: null);
                  break;
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<MoreFilterOption>>[
                  PopupMenuItem<MoreFilterOption>(
                    value: MoreFilterOption.yesterday,
                    child: Text(
                      _getMoreFilterOptionText(MoreFilterOption.yesterday),
                    ),
                  ),
                  PopupMenuItem<MoreFilterOption>(
                    value: MoreFilterOption.tomorrow,
                    child: Text(
                      _getMoreFilterOptionText(MoreFilterOption.tomorrow),
                    ),
                  ),
                  PopupMenuItem<MoreFilterOption>(
                    value: MoreFilterOption.lastWeek,
                    child: Text(
                      _getMoreFilterOptionText(MoreFilterOption.lastWeek),
                    ),
                  ),
                ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMoreFiltersSelected
                    ? Colors.blue.shade600
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMoreFiltersSelected
                      ? Colors.blue.shade200
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 18,
                    color: isMoreFiltersSelected ? Colors.white : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Más filtros',
                    style: TextStyle(
                      color: isMoreFiltersSelected ? Colors.white : Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    DateFilterType filterType,
    String text,
    bool isSelected, {
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected
                ? Colors.blue.shade600
                : Colors.grey.shade200,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: isSelected ? 4 : 1,
            minimumSize: const Size(0, 40),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
