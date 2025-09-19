import 'package:citytourscartagena/app.dart';
import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reportes_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/services/auth_service.dart';
import 'package:citytourscartagena/core/services/user_service.dart'
    show UserService;
import 'package:citytourscartagena/core/utils/notification_handler.dart';
import 'package:citytourscartagena/firebase_options_dev.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Plugin para mostrar notificaciones locales
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Handler de notificaciones cuando la app está en segundo plano o cerrada
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint(
    '🔔 Notificación en segundo plano: ${message.notification?.title}',
  );
  print(
    '📝 apps en este isolate: ${Firebase.apps.map((a) => a.name).toList()}',
  );
}

Future<void> probarConexion() async {
  final client = Supabase.instance.client;

  try {
    final response = await client
        .from('tipos_documentos')
        .select()
        .limit(1)
        .single();

    debugPrint('✅ Conexión exitosa, datos: $response');
  } catch (e) {
    debugPrint('❌ Error de conexión: $e');
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  probarConexion();

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await NotificationHandler.initialize();
  }

  // Ejecutar la app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService(), UserService()),
        ),
        ChangeNotifierProvider(create: (_) => ConfiguracionController()),
        ChangeNotifierProvider(create: (_) => ReservasController()),
        ChangeNotifierProvider(create: (_) => AgenciasController()),
        ChangeNotifierProvider(create: (_) => ReportesController()),
        ChangeNotifierProvider(create: (_) => AuthSupabaseController()),
      ],
      child: const MyApp(),
    ),
  );
}
