import 'package:citytourscartagena/core/mvvc/agencias_controller.dart';
import 'package:citytourscartagena/core/mvvc/configuracion_controller.dart';
import 'package:citytourscartagena/core/mvvc/reservas_controller.dart';
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
  ReservasController.printDebugInfo();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ConfiguracionController>(
          create: (_) => ConfiguracionController()..cargarConfiguracion(),
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
