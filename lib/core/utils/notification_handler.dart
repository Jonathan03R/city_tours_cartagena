import 'dart:convert';

import 'package:citytourscartagena/app.dart';
import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/roles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationHandler {
  // Reusable check: permisos y rol de agencia
  static bool _canDisplayNotification() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    final authC = Provider.of<AuthController>(ctx, listen: false);
    final appUser = authC.appUser;
    final hasPerm = authC.hasPermission(Permission.recibir_notificaciones);
    final isAgency = appUser?.agenciaId != null || appUser?.roles.contains(Roles.agencia) == true;
    debugPrint('[NotificationHandler] Permiso=$hasPerm, esAgencia=$isAgency -> mostrar=${hasPerm && !isAgency}');
    return hasPerm && !isAgency;
  }

  static Future<void> initialize() async {
    if (!kIsWeb) {
      // Desactivar presentación automática en foreground
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false, badge: false, sound: false,
      );
      await _setupNotificationChannels();
      await _setupNotificationListeners();
      await _requestPermissions();
      await _updateFCMToken();
    }
  }

  static Future<void> _setupNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'canal_reservas',
      'Reservas',
      description: 'Notificaciones de nuevas reservas',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null) {
          debugPrint('Notificación local tocada, payload: $payload');
          try {
            final Map<String, dynamic> data = jsonDecode(payload);
            _handleNotificationNavigation(data);
          } catch (e) {
            debugPrint('[NotificationHandler] Error al desglosar el payload: $e');
          }
        }
      },
    );
  }

  static Future<void> _setupNotificationListeners() async {
    // Interceptar notificaciones en primer plano para evitar duplicados
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_canDisplayNotification()) {
        debugPrint('[NotificationHandler] Notificación en primer plano ignorada');
        return;
      }
      debugPrint('🔔 Notificación interceptada en primer plano: ${message.notification?.title}');

      // Mostrar notificación local personalizada
      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'canal_reservas', 'Reservas',
              channelDescription: 'Notificaciones de nuevas reservas',
              importance: Importance.max, priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!_canDisplayNotification()) {
        debugPrint('[NotificationHandler] Notificación abierta ignorada');
        return;
      }
      debugPrint('🔔 App abierta desde notificación: ${message.notification?.title}');
      _handleNotificationNavigation(message.data);
    });

    final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      if (_canDisplayNotification()) {
        debugPrint('🔔 App iniciada desde notificación: ${initialMessage.notification?.title}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationNavigation(initialMessage.data);
        });
      } else {
        debugPrint('[NotificationHandler] Notificación cold-start ignorada');
      }
    }
  }

  static Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  static Future<void> _updateFCMToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint('🔑 FCM Token: $fcmToken');
    if (fcmToken != null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).update(
          {'fcmToken': fcmToken},
        );
      }
    }
  }

  static Future<void> _handleNotificationNavigation(Map<String, dynamic> data) async {
    final reservaIdNotificada = data['reservaId'] as String?;
    final forceShowAll = data['forceShowAll'] as bool? ?? false;

    if (reservaIdNotificada != null) {
      final exists = await validateReservaExists(reservaIdNotificada);
      
      if (exists) {
        navigatorKey.currentState?.pushNamed(
          '/reservas',
          arguments: {
            'reservaIdNotificada': reservaIdNotificada,
            'forceShowAll': forceShowAll,
          },
        );
      } else {
        debugPrint('[NotificationHandler] La reserva $reservaIdNotificada no existe');
        navigatorKey.currentState?.pushNamed(
          '/reservas',
          arguments: {'forceShowAll': true},
        );
        
        // Mostrar error al usuario
        final context = navigatorKey.currentContext;
        if (context != null) {
          showErrorSnackBar(context, 'La reserva de la notificación ya no existe');
        }
      }
    }
  }

  static Future<bool> validateReservaExists(String reservaId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('reservas')
          .doc(reservaId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('[NotificationHandler] Error validating reserva: $e');
      return false;
    }
  }

  static Map<String, dynamic>? parseNotificationPayload(String? payload) {
    if (payload == null) return null;
    
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[NotificationHandler] Error parsing payload: $e');
      return null;
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}