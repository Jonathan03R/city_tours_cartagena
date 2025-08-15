import 'package:citytourscartagena/app.dart';
import 'package:citytourscartagena/core/controller/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/controller/configuracion_controller.dart';
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

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
  }

  // // Inicializar Firebase
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // print(
  //   '📝 apps en este isolate: ${Firebase.apps.map((a) => a.name).toList()}',
  // );

  // if (!kIsWeb) {
  //   // Configuración de Firebase Messaging solo para Android/iOS
  //   FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  //   // Crear canal de notificaciones para Android 8+
  //   const AndroidNotificationChannel channel = AndroidNotificationChannel(
  //     'canal_reservas',
  //     'Reservas',
  //     description: 'Notificaciones de nuevas reservas',
  //     importance: Importance.max,
  //   );

  //   await flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin
  //       >()
  //       ?.createNotificationChannel(channel);

  //   // Pedir permisos de notificación (iOS/Android 13+)
  //   await FirebaseMessaging.instance.requestPermission();

  //   const AndroidInitializationSettings initializationSettingsAndroid =
  //       AndroidInitializationSettings('@mipmap/ic_launcher');
  //   const InitializationSettings initializationSettings =
  //       InitializationSettings(android: initializationSettingsAndroid);
    
  //   /// Inicializar notificaciones locales
  //   await flutterLocalNotificationsPlugin.initialize(
  //     initializationSettings,
  //     onDidReceiveNotificationResponse: (NotificationResponse response) {
  //       final payload = response.payload;
  //       if (payload != null) {
  //         debugPrint('Notificación local tocada, payload: $payload');

  //         // Desglosar el payload (asumiendo que es un JSON string)
  //         try {
  //           final Map<String, dynamic> data = jsonDecode(payload);
  //           _handleNotificationNavigation(data);
  //         } catch (e) {
  //           debugPrint('[v0] Error al desglosar el payload: $e');
  //         }
  //       }
  //     },
  //   );

  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     debugPrint('🔔 Notificación recibida en primer plano: ${message.notification?.title}');
      
  //     // Mostrar notificación local solo si la app está en primer plano
  //     if (message.notification != null) {
  //       flutterLocalNotificationsPlugin.show(
  //         message.hashCode,
  //         message.notification!.title,
  //         message.notification!.body,
  //         const NotificationDetails(
  //           android: AndroidNotificationDetails(
  //             'canal_reservas',
  //             'Reservas',
  //             channelDescription: 'Notificaciones de nuevas reservas',
  //             importance: Importance.max,
  //             priority: Priority.high,
  //           ),
  //         ),
  //         payload: jsonEncode(message.data),
  //       );
  //     }
  //   });

  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     debugPrint('🔔 App abierta desde notificación: ${message.notification?.title}');
  //     _handleNotificationNavigation(message.data);
  //   });

  //   final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  //   if (initialMessage != null) {
  //     debugPrint('🔔 App iniciada desde notificación: ${initialMessage.notification?.title}');
  //     // Esperar a que la app esté completamente inicializada
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       _handleNotificationNavigation(initialMessage.data);
  //     });
  //   }

  //   final fcmToken = await FirebaseMessaging.instance.getToken();
  //   debugPrint('🔑 FCM Token: $fcmToken');
  //   if (fcmToken != null) {
  //     final uid = FirebaseAuth.instance.currentUser?.uid;
  //     if (uid != null) {
  //       await FirebaseFirestore.instance.collection('usuarios').doc(uid).update(
  //         {'fcmToken': fcmToken},
  //       );
  //     }
  //   }
  // }

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
      ],
      child: const MyApp(),
    ),
  );
}
