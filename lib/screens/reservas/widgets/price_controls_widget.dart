import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart' hide AgenciaConReservas;
import 'package:citytourscartagena/core/services/pdf_export_service.dart';
import 'package:citytourscartagena/screens/reservas/widgets/price_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class PriceControlsWidget extends StatefulWidget {
  final AgenciaConReservas? currentAgencia;
  final Configuracion? configuracion;
  final ReservasController reservasController;

  const PriceControlsWidget({
    super.key,
    this.currentAgencia,
    this.configuracion,
    required this.reservasController,
  });

  @override
  State<PriceControlsWidget> createState() => _PriceControlsWidgetState();
}

class _PriceControlsWidgetState extends State<PriceControlsWidget> {
  bool _editandoPrecio = false;
  String? _editingTurno;
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _precioMananaController = TextEditingController();
  final TextEditingController _precioTardeController = TextEditingController();

  @override
  void dispose() {
    _precioController.dispose();
    _precioMananaController.dispose();
    _precioTardeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReservaConAgencia>>(
      stream: widget.reservasController.filteredReservasStream,
      builder: (context, snapshot) {
        final currentReservas = snapshot.data ?? [];
        return _buildRightControls(currentReservas);
      },
    );
  }

  Widget _buildRightControls(List<ReservaConAgencia> currentReservas) {
    final authController = context.read<AuthController>();
    final turnoFilter = widget.reservasController.turnoFilter;
    
    final hasSelections = widget.reservasController.isSelectionMode &&
        widget.reservasController.selectedCount > 0;

    String reservasText = hasSelections
        ? '${widget.reservasController.selectedCount} seleccionada${widget.reservasController.selectedCount != 1 ? 's' : ''}'
        : '${currentReservas.length} reserva${currentReservas.length != 1 ? 's' : ''}';

    String buttonText = hasSelections ? "Exportar Seleccionadas" : "Exportar";

    return Container(
      padding: EdgeInsets.all(12.h),
      margin: EdgeInsets.symmetric(horizontal: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(reservasText, buttonText, hasSelections, authController),
          SizedBox(height: 12.h),
          PriceSectionWidget(
            currentAgencia: widget.currentAgencia,
            configuracion: widget.configuracion,
            turnoFilter: turnoFilter,
            editandoPrecio: _editandoPrecio,
            editingTurno: _editingTurno,
            precioController: _precioController,
            precioMananaController: _precioMananaController,
            precioTardeController: _precioTardeController,
            onStartEditing: _startEditing,
            onSavePrice: _guardarNuevoPrecio,
            onSaveGlobalPrice: _guardarNuevoPrecioGlobal,
            onCancelEditing: _cancelEditing,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(
    String reservasText,
    String buttonText,
    bool hasSelections,
    AuthController authController,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          reservasText,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: hasSelections ? Colors.blue.shade700 : Colors.black,
          ),
        ),
        if (authController.hasPermission(Permission.export_reservas))
          ElevatedButton.icon(
            onPressed: () => _exportReservas(hasSelections),
            icon: Icon(
              hasSelections ? Icons.file_download_outlined : Icons.file_download,
              size: 24.w,
            ),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSelections ? Colors.blue.shade600 : Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  void _startEditing() {
    setState(() {
      if (widget.currentAgencia != null) {
        final ag = widget.currentAgencia!.agencia;
        _precioMananaController.text = ag.precioPorAsientoTurnoManana?.toStringAsFixed(2) ?? '';
        _precioTardeController.text = ag.precioPorAsientoTurnoTarde?.toStringAsFixed(2) ?? '';
      }
      _editandoPrecio = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editandoPrecio = false;
      _editingTurno = null;
      _precioController.clear();
      _precioMananaController.clear();
      _precioTardeController.clear();
    });
  }

  void _startGlobalEditing(String turno, double? currentPrice) {
    setState(() {
      _precioController.text = currentPrice?.toStringAsFixed(2) ?? '0.00';
      _editandoPrecio = true;
      _editingTurno = turno;
    });
  }

  Future<void> _exportReservas(bool hasSelections) async {
    List<ReservaConAgencia> reservasParaExportar;
    
    if (hasSelections) {
      reservasParaExportar = widget.reservasController.selectedReservas;
    } else {
      reservasParaExportar = await widget.reservasController.getAllFilteredReservasSinPaginacion();
    }

    if (!mounted) return;

    final authController = context.read<AuthController>();
    final bool canViewDeuda = authController.hasPermission(Permission.ver_deuda_reservas);
    final pdfService = PdfExportService();
    
    await pdfService.exportarReservasConAgencia(
      reservasConAgencia: reservasParaExportar,
      context: context,
      filtroFecha: widget.reservasController.selectedFilter,
      fechaPersonalizada: widget.reservasController.customDate,
      turnoFiltrado: widget.reservasController.turnoFilter,
      agenciaEspecifica: widget.currentAgencia?.agencia,
      canViewDeuda: canViewDeuda,
    );
  }

  Future<void> _guardarNuevoPrecio() async {
    if (widget.currentAgencia == null) return;

    final agenciasController = Provider.of<AgenciasController>(context, listen: false);
    final mText = _precioMananaController.text.trim();
    final tText = _precioTardeController.text.trim();
    final double? manana = mText.isEmpty ? null : double.tryParse(mText);
    final double? tarde = tText.isEmpty ? null : double.tryParse(tText);

    if ((mText.isNotEmpty && (manana == null || manana <= 0)) ||
        (tText.isNotEmpty && (tarde == null || tarde <= 0))) {
      _showErrorSnackBar('Ingresa precios válidos o deja vacío para usar global');
      return;
    }

    try {
      await agenciasController.updateAgencia(
        widget.currentAgencia!.id,
        widget.currentAgencia!.nombre,
        null,
        widget.currentAgencia!.imagenUrl,
        newPrecioPorAsientoTurnoManana: manana,
        newPrecioPorAsientoTurnoTarde: tarde,
        tipoDocumento: widget.currentAgencia!.tipoDocumento,
        numeroDocumento: widget.currentAgencia!.numeroDocumento,
        nombreBeneficiario: widget.currentAgencia!.nombreBeneficiario,
      );

      _showSuccessSnackBar('Precio de agencia actualizado correctamente');
      _cancelEditing();
    } catch (e) {
      _showErrorSnackBar('Error actualizando precio de agencia: $e');
    }
  }

  Future<void> _guardarNuevoPrecioGlobal(String turno) async {
    final input = _precioController.text.trim();
    final nuevoPrecio = double.tryParse(input);
    
    if (nuevoPrecio == null || nuevoPrecio <= 0) {
      _showErrorSnackBar('Por favor ingresa un precio válido (p.ej. 55.50)');
      return;
    }

    try {
      final configController = Provider.of<ConfiguracionController>(context, listen: false);
      
      if (turno == 'manana') {
        await configController.actualizarPrecioManana(nuevoPrecio);
      } else {
        await configController.actualizarPrecioTarde(nuevoPrecio);
      }

      _showSuccessSnackBar('Precio global de $turno actualizado correctamente');
      _cancelEditing();
    } catch (e) {
      _showErrorSnackBar('Error actualizando precio global: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
