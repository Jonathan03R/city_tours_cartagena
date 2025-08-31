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
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationHandler {
  /// Método para ser llamado desde AuthController o main cuando el usuario esté listo
  static void processPendingNotificationIfAny({int attempt = 0}) {
    debugPrint(
      '[NotificationHandler] processPendingNotificationIfAny called (attempt=$attempt)',
    );
    if (_pendingNotificationData == null) {
      debugPrint(
        '[NotificationHandler] No hay notificación pendiente en memoria',
      );
      // Fallback: en el primer intento, intentar leer getInitialMessage nuevamente por si hubo race
      if (attempt == 0) {
        FirebaseMessaging.instance.getInitialMessage().then((msg) {
          if (msg != null) {
            _pendingNotificationData = msg.data;
            debugPrint(
              '[NotificationHandler] Fallback getInitialMessage obtuvo datos: ${msg.data}',
            );
            // reintentar inmediatamente con attempt+1
            processPendingNotificationIfAny(attempt: attempt + 1);
          } else {
            debugPrint(
              '[NotificationHandler] Fallback getInitialMessage sin datos',
            );
          }
        });
      }
      return;
    }
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      if (attempt < 20) {
        debugPrint(
          '[NotificationHandler] Contexto de navegación no listo. Reintentando...',
        );
        Future.delayed(const Duration(milliseconds: 100), () {
          processPendingNotificationIfAny(attempt: attempt + 1);
        });
      } else {
        debugPrint(
          '[NotificationHandler] Contexto no disponible tras reintentos. Abortando.',
        );
      }
      return;
    }

    if (_canDisplayNotification()) {
      debugPrint(
        '[NotificationHandler] Permisos OK. Procesando navegación de notificación pendiente',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationNavigation(_pendingNotificationData!);
        // limpiar sólo después de intentar navegar
        _pendingNotificationData = null;
      });
      return;
    }

    // Si aún no se pueden mostrar (p. ej., permisos/usuario no listos), reintentar
    if (attempt < 20) {
      Future.delayed(const Duration(milliseconds: 100), () {
        processPendingNotificationIfAny(attempt: attempt + 1);
      });
    } else {
      debugPrint(
        '[NotificationHandler] No se pudo procesar la notificación pendiente: permisos/usuario no listos',
      );
    }
  }

  // Variable para guardar datos de notificación en cold start
  static Map<String, dynamic>? _pendingNotificationData;
  // Reusable check: permisos y rol de agencia
  static bool _canDisplayNotification() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    final authC = Provider.of<AuthController>(ctx, listen: false);
    final appUser = authC.appUser;
    final hasPerm = authC.hasPermission(Permission.recibir_notificaciones);
    final isAgency =
        appUser?.agenciaId != null ||
        appUser?.roles.contains(Roles.agencia) == true;
    debugPrint(
      '[NotificationHandler] Permiso=$hasPerm, esAgencia=$isAgency -> mostrar=${hasPerm && !isAgency}',
    );
    return hasPerm && !isAgency;
  }

  static Future<void> initialize() async {
    if (!kIsWeb) {
      // Desactivar presentación automática en foreground
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
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
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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
            debugPrint(
              '[NotificationHandler] Error al desglosar el payload: $e',
            );
          }
        }
      },
    );

    // Cold start por notificación local: recuperar payload que lanzó la app
    try {
      final details = await flutterLocalNotificationsPlugin
          .getNotificationAppLaunchDetails();
      final didLaunch = details?.didNotificationLaunchApp ?? false;
      final response = details?.notificationResponse;
      final launchPayload = response?.payload; // null si no aplica
      if (didLaunch && launchPayload != null) {
        debugPrint(
          '[NotificationHandler] App lanzada por notificación local, payload=$launchPayload',
        );
        try {
          _pendingNotificationData =
              jsonDecode(launchPayload) as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
            '[NotificationHandler] Error parseando payload de launch: $e',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[NotificationHandler] Error getNotificationAppLaunchDetails: $e',
      );
    }
  }

  static Future<void> _setupNotificationListeners() async {
    // Interceptar notificaciones en primer plano para evitar duplicados
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_canDisplayNotification()) {
        debugPrint(
          '[NotificationHandler] Notificación en primer plano ignorada',
        );
        return;
      }
      debugPrint(
        '🔔 Notificación interceptada en primer plano: ${message.notification?.title}',
      );

      // Mostrar notificación local personalizada
      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'canal_reservas',
              'Reservas',
              channelDescription: 'Notificaciones de nuevas reservas',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Tap explícito del usuario: no bloquear por permisos aquí
      debugPrint(
        '🔔 App abierta desde notificación (background): ${message.notification?.title}',
      );
      _pendingNotificationData = message.data;
      processPendingNotificationIfAny();
    });

    final RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();
    if (initialMessage != null) {
      // Guardar los datos de la notificación para procesarlos después
      _pendingNotificationData = initialMessage.data;
      debugPrint(
        '[NotificationHandler] Cold start: guardando datos de notificación -> ${initialMessage.data}',
      );
    } else {
      debugPrint('[NotificationHandler] Cold start: sin mensaje inicial');
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

  static Future<void> _handleNotificationNavigation(
    Map<String, dynamic> data,
  ) async {
    debugPrint(
      '[NotificationHandler] _handleNotificationNavigation data=$data',
    );
    final reservaIdNotificada = data['reservaId'] as String?;
    final fechaReservaStr = data['fechaReserva'] as String?;
    DateTime? customDate;
    // Cuando llegamos desde una notificación, queremos mostrar TODAS las reservas por defecto
    // para que el usuario vea la reserva recién creada aunque no sea del día actual.
    // Si en el payload viene forceShowAll, lo respetamos, pero por defecto forzamos true.
    // final payloadForce = data['forceShowAll'];
    // final forceShowAll = payloadForce is bool ? (payloadForce || true) : true;

    if (fechaReservaStr != null) {
      try {
        // Intentar parsear como ISO
        customDate = DateTime.tryParse(fechaReservaStr);
        // Si falla, intentar con formato español
        if (customDate == null) {
          final formato = DateFormat("EEE, d MMM. yyyy", "es_ES");
          customDate = formato.parse(fechaReservaStr);
        }
      } catch (e) {
        debugPrint('[NotificationHandler] Error al parsear fechaReserva: $e');
      }
    }

    if (reservaIdNotificada != null) {
      final exists = await validateReservaExists(reservaIdNotificada);

      if (exists) {
        if (navigatorKey.currentState == null) {
          debugPrint(
            '[NotificationHandler] navigatorKey.currentState es null. Reintentando navegación...',
          );
          // Reintentar brevemente si el navigator aún no está listo
          await Future.delayed(const Duration(milliseconds: 100));
        }
        debugPrint(
          '[NotificationHandler] Navegando a /reservas con reservaId=$reservaIdNotificada y customDate=$customDate',
        );
        navigatorKey.currentState?.pushNamed(
          '/reservas',
          arguments: {
            'reservaIdNotificada': reservaIdNotificada,
            'customDate': customDate, // Pasar la fecha específica
          },
        );
      } else {
        debugPrint(
          '[NotificationHandler] La reserva $reservaIdNotificada no existe',
        );
        if (navigatorKey.currentState == null) {
          debugPrint(
            '[NotificationHandler] navigatorKey.currentState es null. Reintentando navegación...',
          );
          await Future.delayed(const Duration(milliseconds: 100));
        }
        debugPrint(
          '[NotificationHandler] Navegando a /reservas mostrando todas',
        );
        navigatorKey.currentState?.pushNamed(
          '/reservas',
          arguments: {'customDate': customDate},
        );

        // Mostrar error al usuario
        final context = navigatorKey.currentContext;
        if (context != null) {
          showErrorSnackBar(
            context,
            'La reserva de la notificación ya no existe',
          );
        }
      }
    } else {
      debugPrint(
        '[NotificationHandler] data no contiene reservaId. Navegando a /reservas(forceShowAll=$customDate)',
      );
      if (navigatorKey.currentState == null) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      navigatorKey.currentState?.pushNamed(
        '/reservas',
        // Sin reservaId, igualmente mostrar todas para el flujo de notificaciones
        arguments: {'customDate': customDate},
      );
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
