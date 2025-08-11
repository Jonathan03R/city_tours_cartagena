import 'dart:io';

import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/reserva.dart'; // Ensure EstadoReserva is imported
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/configuracion_service.dart';
import 'package:citytourscartagena/core/utils/formatters.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart'; // Ensure DateFilterType and TurnoType are imported
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

class PdfExportService {
  /// Exporta las reservas con agencia a un archivo PDF
  Future<void> exportarReservasConAgencia({
    required List<ReservaConAgencia> reservasConAgencia,
    BuildContext? context,
    // NUEVOS PARÁMETROS PARA FILTROS
    DateFilterType? filtroFecha,
    DateTime? fechaPersonalizada,
    TurnoType? turnoFiltrado,
    Agencia? agenciaEspecifica, // Si hay una agencia específica
    required bool canViewDeuda, // Nuevo parámetro para permisos
  }) async {
    Uint8List? agenciaLogoBytes;
    debugPrint('▶ reservasConAgencia: $reservasConAgencia');
    debugPrint(
      '▶ filtroFecha: $filtroFecha, fechaPersonalizada: $fechaPersonalizada',
    );
    debugPrint('▶ turnoFiltrado: $turnoFiltrado');
    debugPrint('▶ agenciaEspecifica: $agenciaEspecifica');
    final Configuracion? cfg = await ConfiguracionService.getConfiguracion();
    debugPrint('▶ cfg: $cfg');
    try {
      final byteData = await rootBundle.load('assets/images/logo.png');
      debugPrint('▶ logo asset cargado, bytes=${byteData.lengthInBytes}');
      debugPrint(
        '▶ agenciaEspecifica.imagenUrl: ${agenciaEspecifica?.imagenUrl}',
      );

      final Uint8List companyLogoBytes = byteData.buffer.asUint8List();

      // Solicitar permisos de almacenamiento
      var status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso denegado. No se puede guardar el archivo'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      // Crear el documento PDF
      final pdf = pw.Document();
      // CALCULAR TOTALES SEGÚN LA LÓGICA DE LA TABLA
      int totalPax = 0;
      double totalSaldo = 0.0;
      double totalDeuda = 0.0;
      final unpaid = reservasConAgencia
          .where((ra) => ra.reserva.estado != EstadoReserva.pagada)
          .toList();
      if (agenciaEspecifica != null) {
        // LÓGICA PARA AGENCIA ESPECÍFICA: solo reservas no pagadas
        totalPax = unpaid.fold<int>(0, (sum, ra) => sum + ra.reserva.pax);
        totalSaldo = unpaid.fold<double>(
          0.0,
          (sum, ra) => sum + ra.reserva.saldo,
        );
        totalDeuda = unpaid.fold<double>(
          0.0,
          (sum, ra) => sum + ra.reserva.deuda,
        );
      } else {
        // LÓGICA PARA VISTA GENERAL
        totalPax = reservasConAgencia.fold<int>(
          0,
          (sum, ra) => sum + ra.reserva.pax,
        );
        totalSaldo = reservasConAgencia.fold<double>(
          0.0,
          (sum, ra) => sum + ra.reserva.saldo,
        );
        totalDeuda = unpaid.fold<double>(
          0.0,
          (sum, ra) => sum + ra.reserva.deuda,
        );
      }
      Uint8List? agenciaLogoBytes;
      if (agenciaEspecifica?.imagenUrl != null) {
        final resp = await http.get(Uri.parse(agenciaEspecifica!.imagenUrl!));
        if (resp.statusCode == 200) {
          agenciaLogoBytes = resp.bodyBytes;
        }
      }
      // Agregar página al PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          header: (context) => _buildHeader(
            filtroFecha: filtroFecha,
            fechaPersonalizada: fechaPersonalizada,
            turnoFiltrado: turnoFiltrado,
            agenciaEspecifica: agenciaEspecifica,
            companyLogoBytes: companyLogoBytes,
          ),
          footer: (context) => _buildFooter(context, companyLogoBytes),
          build: (context) => [
            if (agenciaEspecifica != null) ...[
              _buildAgenciaInfo(
                agenciaEspecifica,
                logoBytes: agenciaLogoBytes,
                config: cfg,
              ), // pasamos el buffer
              pw.SizedBox(height: 20),
            ],
            _buildReservasTable(
              reservasConAgencia,
              canViewDeuda,
            ), // Pasa el permiso
            pw.SizedBox(height: 20),
            _buildTotalesSection(
              totalPax,
              totalSaldo,
              totalDeuda,
              agenciaEspecifica !=
                  null, // Indicar si es vista de agencia específica
              canViewDeuda, // Pasa el permiso
            ),
          ],
        ),
      );
      // Generar bytes del PDF
      final Uint8List pdfBytes = await pdf.save();
      // Guardar archivo en el dispositivo
      await _guardarArchivoPdf(pdfBytes, context, agenciaEspecifica);
    } catch (e) {
      debugPrint('Error generando PDF: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Construye el encabezado del PDF con información de filtros
  pw.Widget _buildHeader({
    DateFilterType? filtroFecha,
    DateTime? fechaPersonalizada,
    TurnoType? turnoFiltrado,
    Agencia? agenciaEspecifica,
    Uint8List? companyLogoBytes,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.blue),
        ),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (companyLogoBytes != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      margin: const pw.EdgeInsets.only(right: 10),
                      decoration: const pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(
                          pw.MemoryImage(companyLogoBytes),
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                    ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CITY TOURS CLIMATIZADO',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.Text(
                        agenciaEspecifica != null
                            ? 'Reporte de Reservas - ${agenciaEspecifica.nombre}'
                            : 'Reporte General de Reservas',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Fecha: ${_formatearFecha(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Hora: ${_formatearHora(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Filtros aplicados: ',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    _construirTextoFiltros(
                      filtroFecha,
                      fechaPersonalizada,
                      turnoFiltrado,
                    ),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la información de la agencia específica
  pw.Widget _buildAgenciaInfo(
    Agencia agencia, {
    Uint8List? logoBytes,
    Configuracion? config,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        // border: pw.Border.all(color: PdfColors.green200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          // Placeholder para imagen con inicial de la agencia
          if (logoBytes != null)
            pw.Container(
              width: 60,
              height: 60,
              decoration: pw.BoxDecoration(
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(30)),
                border: pw.Border.all(color: PdfColors.green300),
              ),
              child: pw.ClipOval(
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            )
          else
            pw.Container(
              width: 60,
              height: 60,
              decoration: pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(30)),
                border: pw.Border.all(color: PdfColors.green300),
              ),
              child: pw.Center(
                child: pw.Text(
                  agencia.nombre.isNotEmpty
                      ? agencia.nombre[0].toUpperCase()
                      : 'A',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
              ),
            ),
          pw.SizedBox(width: 20),

          /// primera columna con nombre y reporte
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  agencia.nombre,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Reporte específico de esta agencia',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 8),
                // Mostrar precios específicos de la agencia
                pw.Row(
                  children: [
                    if (agencia.precioPorAsientoTurnoManana != null) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.orange100,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Text(
                          'Mañana: \$${agencia.precioPorAsientoTurnoManana!.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                    ],
                    if (agencia.precioPorAsientoTurnoTarde != null)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue100,
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Text(
                          'Tarde: \$${agencia.precioPorAsientoTurnoTarde!.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
                if (agencia.precioPorAsientoTurnoManana == null &&
                    agencia.precioPorAsientoTurnoTarde == null)
                  pw.Text(
                    'Usa precios globales del sistema',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey500,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.end, // texto alineado a la izquierda
              mainAxisAlignment:
                  pw.MainAxisAlignment.start, // contenido al tope
              children: [
                if (agencia.tipoDocumento != null &&
                    agencia.numeroDocumento != null) ...[
                  pw.Text(
                    'Cuenta de cobro',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  if (agencia.nombreBeneficiario != null)
                    pw.Text(
                      agencia.nombreBeneficiario!,
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  pw.Text(
                    '${agencia.tipoDocumento!.name.toUpperCase()} : ${agencia.numeroDocumento!}',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 4),
                ],
                if (config != null &&
                    config.tipoDocumento != null &&
                    config.numeroDocumento != null) ...[
                  pw.Text(
                    'Debe a',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    config.nombreBeneficiario ?? '',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                  pw.Text(
                    '${config.tipoDocumento!.name.toUpperCase()} : ${config.numeroDocumento!}',
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el texto de filtros aplicados
  String _construirTextoFiltros(
    DateFilterType? filtroFecha,
    DateTime? fechaPersonalizada,
    TurnoType? turnoFiltrado,
  ) {
    List<String> filtros = [];
    // Filtro de fecha
    if (filtroFecha != null) {
      switch (filtroFecha) {
        case DateFilterType.all:
          filtros.add('Todas las fechas');
          break;
        case DateFilterType.today:
          filtros.add('Hoy (${_formatearFecha(DateTime.now())})');
          break;
        case DateFilterType.yesterday:
          final ayer = DateTime.now().subtract(const Duration(days: 1));
          filtros.add('Ayer (${_formatearFecha(ayer)})');
          break;
        case DateFilterType.tomorrow:
          final manana = DateTime.now().add(const Duration(days: 1));
          filtros.add('Mañana (${_formatearFecha(manana)})');
          break;
        case DateFilterType.lastWeek:
          filtros.add('Última semana');
          break;
        case DateFilterType.custom:
          if (fechaPersonalizada != null) {
            filtros.add(
              'Fecha específica: ${_formatearFecha(fechaPersonalizada)}',
            );
          } else {
            filtros.add('Fecha personalizada');
          }
          break;
      }
    } else {
      filtros.add('Sin filtro de fecha');
    }
    // Filtro de turno
    if (turnoFiltrado != null) {
      final turnoTexto = turnoFiltrado == TurnoType.manana ? 'Mañana' : 'Tarde';
      filtros.add('Turno: $turnoTexto');
    } else {
      filtros.add('Todos los turnos');
    }
    return filtros.join(' • ');
  }

  /// Construye la sección de totales con información contextual
  pw.Widget _buildTotalesSection(
    int totalPax,
    double totalSaldo,
    double totalDeuda,
    bool esAgenciaEspecifica,
    bool canViewDeuda,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildTotalItem('TOTAL PAX', '$totalPax', PdfColors.blue),
              _buildTotalItem(
                'TOTAL SALDO',
                Formatters.formatCurrency(totalSaldo),
                PdfColors.green,
              ),
              if (canViewDeuda) ...[
                _buildTotalItem(
                  'TOTAL DEUDA',
                  Formatters.formatCurrency(totalDeuda),
                  PdfColors.red,
                ),
              ],
            ],
          ),
          if (esAgenciaEspecifica) ...[
            pw.SizedBox(height: 10),
            pw.Text(
              '* Para agencias específicas: PAX y SALDO incluyen solo reservas pendientes',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Construye la tabla de reservas
  pw.Widget _buildReservasTable(
    List<ReservaConAgencia> reservasConAgencia,
    bool canViewDeuda,
  ) {
    final List<pw.Widget> headerCells = [];
    final Map<int, pw.TableColumnWidth> columnWidths = {};
    int columnIndex = 0;

    // Define columns and their widths dynamically
    headerCells.add(_buildTableHeader('TURNO'));
    columnWidths[columnIndex++] = const pw.FlexColumnWidth(1.5);

    headerCells.add(_buildTableHeader('TELEFONO'));
    columnWidths[columnIndex++] = const pw.FlexColumnWidth(2);

    headerCells.add(_buildTableHeader('HOTEL'));
    columnWidths[columnIndex++] = const pw.FlexColumnWidth(2);

    headerCells.add(_buildTableHeader('CLIENTE'));
    columnWidths[columnIndex++] = const pw.FlexColumnWidth(2.5);

    headerCells.add(_buildTableHeader('FECHA'));
    columnWidths[columnIndex++] = const pw.FlexColumnWidth(1.5);

    headerCells.add(_buildTableHeader('PAX'));
    columnWidths[columnIndex++] = const pw.FlexColumnWidth(1);

    headerCells.add(_buildTableHeader('SALDO'));
    columnWidths[columnIndex++] = const pw.FlexColumnWidth(1.5);

    headerCells.add(_buildTableHeader('AGENCIA'));
    columnWidths[columnIndex++] = const pw.FlexColumnWidth(2);

    if (canViewDeuda) {
      headerCells.add(_buildTableHeader('DEUDA'));
      columnWidths[columnIndex++] = const pw.FlexColumnWidth(1.5);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: columnWidths,
      children: [
        // Encabezado de la tabla
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: headerCells,
        ),
        // Filas de datos
        ...reservasConAgencia.map(
          (reserva) => _buildTableRow(reserva, canViewDeuda),
        ), // Pasa el permiso
      ],
    );
  }

  /// Construye una celda de encabezado de tabla
  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Construye una fila de datos de la tabla
  pw.TableRow _buildTableRow(ReservaConAgencia reserva, bool canViewDeuda) {
    final List<pw.Widget> dataCells = [];

    dataCells.add(_buildTableCell(_getTurnoText(reserva.reserva.turno)));
    dataCells.add(
      _buildTableCell(
        reserva.telefono.isEmpty ? 'Sin teléfono' : reserva.telefono,
      ),
    );
    dataCells.add(
      _buildTableCell(reserva.hotel.isEmpty ? 'Sin hotel' : reserva.hotel),
    );
    dataCells.add(_buildTableCell(reserva.nombreCliente));
    dataCells.add(_buildTableCell(Formatters.formatDate(reserva.fecha)));
    dataCells.add(
      _buildTableCell('${reserva.pax}', align: pw.TextAlign.center),
    );
    dataCells.add(
      _buildTableCell(
        Formatters.formatCurrency(reserva.saldo),
        align: pw.TextAlign.right,
      ),
    );
    dataCells.add(_buildTableCell(reserva.nombreAgencia));

    // Conditionally add 'DEUDA' cell
    if (canViewDeuda) {
      dataCells.add(
        _buildTableCell(
          Formatters.formatCurrency(reserva.deuda),
          align: pw.TextAlign.right,
          color: reserva.deuda > 0 ? PdfColors.red : PdfColors.green,
        ),
      );
    }

    // dataCells.add(
    //   _buildTableCell(
    //     Formatters.getEstadoText(reserva.estado),
    //     color: _getEstadoColor(reserva.estado),
    //   ),
    // );

    return pw.TableRow(children: dataCells);
  }

  /// Construye una celda de datos de tabla
  pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, color: color ?? PdfColors.black),
        textAlign: align,
      ),
    );
  }

  /// Construye un item de total
  pw.Widget _buildTotalItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Construye el pie de página del PDF
  pw.Widget _buildFooter(pw.Context context, Uint8List? logoBytes) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.grey)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logoBytes != null)
                pw.Container(
                  width: 20,
                  height: 20,
                  margin: const pw.EdgeInsets.only(right: 5),
                  child: pw.Image(
                    pw.MemoryImage(logoBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              pw.Text(
                'CITY TOURS CLIMATIZADO',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  /// Guarda el archivo PDF en el dispositivo
  Future<void> _guardarArchivoPdf(
    Uint8List pdfBytes,
    BuildContext? context,
    Agencia? agenciaEspecifica,
  ) async {
    try {
      final directory = Directory('/storage/emulated/0/Download');
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final agenciaPrefix = agenciaEspecifica != null
          ? '${agenciaEspecifica.nombre.replaceAll(' ', '_')}_'
          : '';
      final fileName = 'reservas_${agenciaPrefix}city_tours_$timestamp.pdf';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('PDF guardado en Descargas: $fileName')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      debugPrint('✅ PDF guardado exitosamente en: $filePath');
    } catch (e) {
      debugPrint('❌ Error guardando PDF: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Obtiene el texto del turno
  String _getTurnoText(dynamic turno) {
    if (turno == null) return 'Sin turno';
    if (turno is TurnoType) return turno.label;
    return turno.toString();
  }

  /// Obtiene el color según el estado de la reserva
  PdfColor _getEstadoColor(dynamic estado) {
    final estadoStr = estado.toString().split('.').last;
    switch (estadoStr) {
      case 'pagada':
        return PdfColors.green;
      case 'cancelada':
        return PdfColors.red;
      default:
        return PdfColors.orange;
    }
  }

  /// Formatea la fecha para el PDF
  String _formatearFecha(DateTime fecha) {
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
    return '${fecha.day} de ${meses[fecha.month - 1]} del ${fecha.year}';
  }

  /// Formatea la hora para el PDF
  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  Future<pw.Document> generateDocument({
    required List<ReservaConAgencia> reservasConAgencia,
    DateFilterType? filtroFecha,
    DateTime? fechaPersonalizada,
    TurnoType? turnoFiltrado,
    Agencia? agenciaEspecifica,
    required bool canViewDeuda, // Nuevo parámetro para permisos
  }) async {
    // 1) Crear doc
    final byteData = await rootBundle.load('assets/images/logo.png');
    final Uint8List companyLogoBytes = byteData.buffer.asUint8List();
    final pdf = pw.Document();
    // 2) Calcular totales (idéntico a exportarReservasConAgencia)
    int totalPax = 0;
    double totalSaldo = 0.0;
    double totalDeuda = 0.0;
    final unpaid = reservasConAgencia
        .where((ra) => ra.reserva.estado != EstadoReserva.pagada)
        .toList();
    if (agenciaEspecifica != null) {
      totalPax = unpaid.fold<int>(0, (sum, ra) => sum + ra.reserva.pax);
      totalSaldo = unpaid.fold<double>(
        0.0,
        (sum, ra) => sum + ra.reserva.saldo,
      );
      totalDeuda = unpaid.fold<double>(
        0.0,
        (sum, ra) => sum + ra.reserva.deuda,
      );
    } else {
      totalPax = reservasConAgencia.fold<int>(
        0,
        (sum, ra) => sum + ra.reserva.pax,
      );
      totalSaldo = reservasConAgencia.fold<double>(
        0.0,
        (sum, ra) => sum + ra.reserva.saldo,
      );
      totalDeuda = unpaid.fold<double>(
        0.0,
        (sum, ra) => sum + ra.reserva.deuda,
      );
    }
    // 3) Descargar logo si hay URL
    Uint8List? agenciaLogoBytes;
    if (agenciaEspecifica?.imagenUrl != null) {
      final resp = await http.get(Uri.parse(agenciaEspecifica!.imagenUrl!));
      if (resp.statusCode == 200) {
        agenciaLogoBytes = resp.bodyBytes;
      }
    }
    // 4) Construir páginas
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (ctx) => _buildHeader(
          filtroFecha: filtroFecha,
          fechaPersonalizada: fechaPersonalizada,
          turnoFiltrado: turnoFiltrado,
          agenciaEspecifica: agenciaEspecifica,
          companyLogoBytes: companyLogoBytes,
        ),
        footer: (ctx) => _buildFooter(ctx, companyLogoBytes),
        build: (ctx) => [
          if (agenciaEspecifica != null) ...[
            _buildAgenciaInfo(agenciaEspecifica, logoBytes: agenciaLogoBytes),
            pw.SizedBox(height: 20),
          ],
          _buildReservasTable(
            reservasConAgencia,
            canViewDeuda,
          ), // Pasa el permiso
          pw.SizedBox(height: 20),
          _buildTotalesSection(
            totalPax,
            totalSaldo,
            totalDeuda,
            agenciaEspecifica != null,
            canViewDeuda, // Pasa el permiso
          ),
        ],
      ),
    );
    return pdf;
  }
}
