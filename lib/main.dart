import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/services/configuracion_service.dart';
import 'package:citytourscartagena/firebase_options.dart';
import 'package:citytourscartagena/main_dev.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es_ES', null);
  // await ReservasController.initialize();
  // <-- Aquí imprimes el debug tras inicializar todo
  // ejecutar una vesta la configuración de Firebase y los controladores
  await ConfiguracionService.inicializarConfiguracion();
  // await _assignDefaultTurno();
  ReservasController.printDebugInfo();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfiguracionController>(
          create: (_) => ConfiguracionController(),
        ),
        ChangeNotifierProvider<ReservasController>(
          create: (_) => ReservasController(),
        ),
        ChangeNotifierProvider<AgenciasController>(
          create: (_) => AgenciasController(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// /// Recorre todas las reservas y asigna "tarde" si no existía el campo turno.
// Future<void> _assignDefaultTurno() async {
//   final db = FirebaseFirestore.instance;
//   final snapshot = await db.collection('reservas').get();
//   var updated = 0;
//   for (final doc in snapshot.docs) {
//     final data = doc.data();
//     // Sólo si no tiene campo turno
//     if (data['turno'] == null) {
//       // guardamos exactamente el string que espera tu modelo
//       await doc.reference.update({'turno': TurnoType.tarde.toString().split('.').last});
//       updated++;
//     }
//   }
//   debugPrint('✅ Turnos por defecto asignados en $updated reservas');
// }
