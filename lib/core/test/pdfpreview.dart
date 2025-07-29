import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/enum/tipo_documento.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/pdf_export_service.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pdfSvc = PdfExportService();

    final testAgencia = Agencia(
      id: 'i8f43rcPQhK0AO2WzZU8',
      nombre: 'Agencia Cartagena',
      imagenUrl: 'https://res.cloudinary.com/dtjscibjc/image/upload/v1753394045/ym0owl2ww00nhem5hwgh.jpg', // o la URL real
      eliminada: false,
      precioPorAsientoTurnoManana: 50.0,
      precioPorAsientoTurnoTarde:  75.0,
      tipoDocumento: TipoDocumento.cc,
      numeroDocumento: '123456789',
      nombreBeneficiario: 'Nombre de prueba lorend input',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Vista previa PDF')),
      body: PdfPreview(
        maxPageWidth: 700,
        build: (PdfPageFormat format) async {
          // Pasa una lista real o vacía, no "[...]"
          final doc = await pdfSvc.generateDocument(
            reservasConAgencia: <ReservaConAgencia>[], // <-- Lista vacía
            filtroFecha: DateFilterType.today,
            fechaPersonalizada: DateTime.now(),
            turnoFiltrado: null,
            agenciaEspecifica: testAgencia,
          );
          return doc.save();
        },
      ),
    );
  }
}