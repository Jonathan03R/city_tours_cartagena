import 'package:citytourscartagena/app.dart';
import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/services/auth_service.dart';
import 'package:citytourscartagena/core/services/user_service.dart'
    show UserService;
import 'package:citytourscartagena/core/utils/notification_handler.dart';
import 'package:citytourscartagena/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

/// Plugin para mostrar notificaciones locales
// top-level
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await NotificationHandler.initialize();
  }  // Ejecutar la app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService(), UserService()),
        ),
        ChangeNotifierProvider(create: (_) => ConfiguracionController()),
        ChangeNotifierProvider(create: (_) => ReservasController()),
        ChangeNotifierProvider(create: (_) => AgenciasController()),
      ],
      child: const MyApp(),
    ),
  );
}
