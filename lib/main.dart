import 'package:citytourscartagena/core/mvvc/reservas_controller.dart';
import 'package:citytourscartagena/firebase_options.dart';
import 'package:citytourscartagena/main_dev.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('es_ES', null);
  await ReservasController.initialize();
  // <-- Aquí imprimes el debug tras inicializar todo
  ReservasController.printDebugInfo();
  runApp(const MyApp());
}
