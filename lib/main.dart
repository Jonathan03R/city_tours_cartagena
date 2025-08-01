import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
import 'package:citytourscartagena/core/controller/reservas_controller.dart';
import 'package:citytourscartagena/core/services/auth_service.dart';
import 'package:citytourscartagena/core/services/user_service.dart' show UserService;
import 'package:citytourscartagena/firebase_options.dart';
import 'package:citytourscartagena/main_dev.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

/// Plugin para mostrar notificaciones locales
// top-level
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Handler de notificaciones cuando la app está en segundo plano o cerrada
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('🔔 Notificación en segundo plano: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Crear canal de notificaciones para Android 8+
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'canal_reservas',
    'Reservas',
    description: 'Notificaciones de nuevas reservas',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Configurar handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Pedir permisos de notificación (iOS/Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  // Suscribirse al topic de nuevas reservas
  await FirebaseMessaging.instance.subscribeToTopic('nuevas-reservas');

  // Mostrar notificaciones cuando la app está en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android.smallIcon,
          ),
        ),
      );
    }
  });

  // Obtener y guardar token FCM (opcional si usa topics)
  final fcmToken = await FirebaseMessaging.instance.getToken();
  debugPrint('🔑 FCM Token: $fcmToken');
  if (fcmToken != null) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update({'fcmToken': fcmToken});
    }
  }

  // Imprimir debug info personalizada
  ReservasController.printDebugInfo();

  // Ejecutar app con providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService(), UserService()),
        ),
        ChangeNotifierProvider(
          create: (_) => ConfiguracionController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReservasController(),
        ),
        ChangeNotifierProvider(
          create: (_) => AgenciasController(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
