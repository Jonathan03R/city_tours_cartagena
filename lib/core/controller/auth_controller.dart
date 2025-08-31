import 'dart:async';

import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/roles.dart';
import 'package:citytourscartagena/core/services/permission_service.dart';
import 'package:citytourscartagena/core/utils/notification_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/usuarios.dart'; // Importa tu modelo Usuarios
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;
  User? user;
  Usuarios? appUser; // Tipo cambiado de AppUser a Usuarios
  bool isLoading = false;
  StreamSubscription<User?>? _fbAuthSub;
  StreamSubscription<Usuarios?>?
  _appUserSub; // Tipo cambiado de AppUser a Usuarios
  final PermissionService _permissionService = PermissionService();

  // FCM listener control
  static bool _fcmListenersInitialized = false;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  bool _gotInitialMessage = false;

  AuthController(this._authService, this._userService) {
    user = FirebaseAuth.instance.currentUser;
    _fbAuthSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
      user = u;
      notifyListeners();

      if (user != null) {
        // Inicializar listeners FCM solo una vez por sesión de usuario
        _subscribeToAppUser();
      } else {
        // DESUSCRIBIRSE SI EL USUARIO SE DESLOGUEA (solo en móviles)
        if (!kIsWeb) {
          FirebaseMessaging.instance.unsubscribeFromTopic('nueva_reserva');
          debugPrint('[AuthController] Desuscrito de topic DESLOGEADO nueva_reserva');
        }
      }
    });

    // Elimina esta llamada temprana:
    // _subscribeToAppUser();
  }

  /// Suscribirse a los cambios del usuario en Firestore
  /// lo que quiere decir que cada vez que el usuario
  /// se loguea o cambia, actualiza el perfil en memoria
  /// y notifica a los listeners.

  void _subscribeToAppUser({User? overrideUser}) {
    _appUserSub?.cancel();
    final currentUser = overrideUser ?? user;

    if (currentUser == null) {
      appUser = null;
      isLoading = false;
      notifyListeners();
      debugPrint(
        '[AuthController] _subscribeToAppUser: NO HAY USUARIO LOGEADO',
      );
      return;
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      _appUserSub = _userService
          .getUserStream(currentUser.uid)
          .listen(
            (u) async {
              debugPrint(
                '[AuthController] Stream ha recibido un _appUserSub: $u',
              );
              if (u != null) {
                debugPrint('[AuthController] Stream appUser.roles: ${u.roles}');
              }

              if (u == null) {
                debugPrint(
                  '[AuthController] Stream: User profile not found in Firestore, creating new one.',
                );
                final correo = user!.email ?? '';
                final soloUsuario = correo.contains('@')
                    ? correo.split('@').first
                    : correo;
                final nuevoUsuario = Usuarios(
                  id: user!.uid,
                  usuario: soloUsuario,
                  nombre: null,
                  email: correo.isNotEmpty ? correo : null,
                  telefono: null,
                  roles: [Roles.verReservas],
                  activo: true,
                );
                await _userService.saveUserData(user!.uid, nuevoUsuario);
                appUser = nuevoUsuario;
              } else if (u.activo == false) {
                debugPrint(
                  '[AuthController] Stream: User is inactive in stream, signing out.',
                );
                await _authService.signOut();
                user = null;
                appUser = null;
                isLoading = false;
                notifyListeners();
                return;
              } else {
                appUser = u;
                debugPrint('[AuthController] Stream: User is active in stream, setting appUser.');

                // Validar si el usuario tiene el permiso recibir_notificaciones
                if (!kIsWeb) {
                  final hasPermission = _permissionService.hasAnyPermission(
                    u.roles,
                    Permission.recibir_notificaciones,
                  );
                  // Depuración: mostrar motivo de suscripción o bloqueo
                  final isAgencyUser = u.agenciaId != null || u.roles.contains(Roles.agencia);
                  final shouldSubscribe = hasPermission && !isAgencyUser;
                  debugPrint('[AuthController][DEBUG] Usuario ${u.usuario} (id=${u.id}) - roles: ${u.roles}, agenciaId: ${u.agenciaId} -> tienePermiso=$hasPermission, esAgencia=$isAgencyUser, suscribir=$shouldSubscribe');
                  if (shouldSubscribe) {
                    await FirebaseMessaging.instance.subscribeToTopic('nueva_reserva');
                    debugPrint('[AuthController] Suscrito al topic "nueva_reserva" para usuario ${u.usuario}');
                  } else {
                    await FirebaseMessaging.instance.unsubscribeFromTopic('nueva_reserva');
                    debugPrint('[AuthController] No se suscribe (bloqueado) al topic "nueva_reserva" para usuario ${u.usuario}');
                  }
                }

                // Procesar notificación pendiente si existe y el usuario está listo
                Future.delayed(const Duration(milliseconds: 500), () {
                  debugPrint('[AuthController] Procesando notificación pendiente tras autenticación');
                  NotificationHandler.processPendingNotificationIfAny();
                });
              }

              isLoading = false;
              notifyListeners();
            },
            onError: (e) {
              debugPrint('[AuthController] Error in userStream: $e');
              appUser = null;
              isLoading = false;
              notifyListeners();
            },
          );
    });
  }

  Future<void> login(String username, String password) async {
    isLoading = true;
    notifyListeners();

    try {
      final cred = await _authService.signIn(username, password);
      final uid = cred.user!.uid;
      debugPrint(
        '[AuthController] Login: Firebase Auth successful for UID: $uid',
      );

      final userData = await _userService.getUserOnce(uid);
      debugPrint('[AuthController] Login: Fetched userData once: $userData');

      if (userData == null) {
        await _authService.signOut();
        throw FirebaseAuthException(
          code: 'user-not-registered',
          message: 'El usuario no está registrado en la base de datos.',
        );
      }

      if (userData.activo == false) {
        await _authService.signOut();
        throw FirebaseAuthException(
          code: 'user-inactive',
          message: 'Tu cuenta ha sido desactivada. Contacta al administrador.',
        );
      }

      debugPrint('[AuthController] Login: User is active. Proceeding.');
      user = cred.user; // asegúrate de actualizarlo manualmente
      //     if (!kIsWeb) {
      //       await FirebaseMessaging.instance.subscribeToTopic('nueva_reserva');
      // // Asegurar que los listeners FCM estén activos para el usuario recién logueado
      //       _initFcmListeners();
      //     }
      _subscribeToAppUser(overrideUser: user);
    } on FirebaseAuthException {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _fbAuthSub?.cancel();
    _appUserSub?.cancel();
    // Cancelar listeners cuando el usuario sale
    // _cancelFcmListeners();
    user = null;
    appUser = null;
    isLoading = false;
    notifyListeners();

    if (!kIsWeb) {
      await FirebaseMessaging.instance.unsubscribeFromTopic('nueva_reserva');
    }
  }

  Future<void> adminCreateUser({
    required String username,
    required String name,
    String? email,
    String? phone,
    String? agenciaId,
    required List<String> roles,
  }) async {
    isLoading = true;
    notifyListeners();
    print('adminCreateUser: agenciaId recibido = $agenciaId');
    try {
      final String password = username;
      // *** CAMBIO CLAVE: Usar adminSignUp para no afectar la sesión actual ***
      final UserCredential userCredential = await _authService.adminSignUp(
        username,
        password,
      );
      final String uid = userCredential.user!.uid;
      final Usuarios newUser = Usuarios(
        // Usando Usuarios
        id: uid,
        usuario: username,
        nombre: name,
        email: email,
        telefono: phone,
        roles: roles,
        activo: true,
        agenciaId: agenciaId,
      );
      await _userService.saveUserData(uid, newUser);
      debugPrint('Usuario $username creado por admin. UID: $uid');
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Error de Firebase Auth al crear usuario: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('Error al crear usuario: ${e.toString()}');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCurrentUserProfile({
    String? username,
    String? name,
    String? email,
    String? phone,
  }) async {
    if (user == null || appUser == null) return;
    isLoading = true;
    notifyListeners();
    try {
      final Map<String, dynamic> dataToUpdate = {};
      if (username != null && username != appUser!.usuario) {
        dataToUpdate['usuario'] = username;
      }
      if (name != null && name != appUser!.nombre) {
        dataToUpdate['nombre'] = name;
      }
      if (email != null && email != appUser!.email) {
        dataToUpdate['email'] = email;
      }
      if (phone != null && phone != appUser!.telefono) {
        dataToUpdate['telefono'] = phone;
      }
      if (dataToUpdate.isNotEmpty) {
        await _userService.updateUserData(user!.uid, dataToUpdate);
      }
      debugPrint('Perfil del usuario actual actualizado.');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCurrentUserPassword(String newPassword) async {
    isLoading = true;
    notifyListeners();
    try {
      await _userService.updateCurrentUserPassword(newPassword);
      debugPrint('Contraseña del usuario actual actualizada.');
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Error de Firebase Auth al actualizar contraseña: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('Error al actualizar contraseña: ${e.toString()}');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUserActiveStatus(String uid, bool isActive) async {
    isLoading = true;
    notifyListeners();
    try {
      await _userService.toggleUserActiveStatus(uid, isActive);
      debugPrint('Estado de usuario $uid cambiado a activo: $isActive');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza datos de cualquier usuario por UID
  Future<void> updateUser(String uid, Map<String, dynamic> dataToUpdate) async {
    isLoading = true;
    notifyListeners();
    try {
      await _userService.updateUserData(uid, dataToUpdate);
      debugPrint('Usuario $uid actualizado con datos: $dataToUpdate');
    } catch (e) {
      debugPrint('Error actualizando usuario $uid: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Verifica si el usuario actual tiene un permiso específico.
  bool hasPermission(Permission permission) {
    if (appUser == null) {
      // Usando appUser
      return false; // Si no hay usuario logueado, no tiene permisos
    }
    return _permissionService.hasAnyPermission(
      appUser!.roles,
      permission,
    ); // Usando appUser
  }

  // void _initFcmListeners() {
  //   if (kIsWeb) return; // no para web
  //   if (_fcmListenersInitialized) return;
  //   _fcmListenersInitialized = true;

  //   debugPrint('[AuthController] Inicializando listeners FCM');

  //   _onMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     debugPrint('[AuthController][onMessage] data=${message.data}');
  //     final reservaId = message.data['reservaId'] as String?;

  //     // Mostrar SnackBar con accion 'Ver' que fuerza mostrar todas
  //     final ctx = navigatorKey.currentContext;
  //     if (ctx != null && reservaId != null) {
  //       ScaffoldMessenger.of(ctx).showSnackBar(
  //         SnackBar(
  //           content: Row(
  //             children: [
  //               const Icon(Icons.notification_important, color: Colors.white),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(message.notification?.title ?? 'Nueva reserva'),
  //               ),
  //             ],
  //           ),
  //           backgroundColor: Colors.blue.shade600,
  //           duration: const Duration(seconds: 6),
  //           action: SnackBarAction(
  //             label: 'Ver',
  //             textColor: Colors.white,
  //             onPressed: () {
  //               final navState = navigatorKey.currentState;
  //               if navState == null return;
  //               WidgetsBinding.instance.addPostFrameCallback((_) {
  //                 if (navState.canPop()) {
  //                   navState.pushNamed(
  //                     '/reservas',
  //                     arguments: {
  //                       'reservaIdNotificada': reservaId,
  //                       'forceShowAll': true,
  //                     },
  //                   );
  //                 } else {
  //                   navState.pushNamed('/', arguments: null);
  //                   WidgetsBinding.instance.addPostFrameCallback((_) {
  //                     navState.pushNamed(
  //                       '/reservas',
  //                       arguments: {
  //                         'reservaIdNotificada': reservaId,
  //                         'forceShowAll': true,
  //                       },
  //                     );
  //                   });
  //                 }
  //               });
  //             },
  //           ),
  //         ),
  //       );
  //     }
  //   });

  //   _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     debugPrint('[AuthController][onMessageOpenedApp] data=${message.data}');
  //     final reservaId = message.data['reservaId'] as String?;
  //     if (reservaId != null) {
  //       final navState = navigatorKey.currentState;
  //       if (navState == null) return;
  //       WidgetsBinding.instance.addPostFrameCallback((_) {
  //         if (navState.canPop()) {
  //           navState.pushNamed(
  //             '/reservas',
  //             arguments: {
  //               'reservaIdNotificada': reservaId,
  //               'forceShowAll': true,
  //             },
  //           );
  //         } else {
  //           navState.pushNamed('/', arguments: null);
  //           WidgetsBinding.instance.addPostFrameCallback((_) {
  //             navState.pushNamed(
  //               '/reservas',
  //               arguments: {
  //                 'reservaIdNotificada': reservaId,
  //                 'forceShowAll': true,
  //               },
  //             );
  //           });
  //         }
  //       });
  //     }
  //   });

  //   // initial message (cold start)
  //   FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
  //     if (_gotInitialMessage) return;
  //     _gotInitialMessage = true;
  //     if (message != null) {
  //       debugPrint('[AuthController][getInitialMessage] data=${message.data}');
  //       final reservaId = message.data['reservaId'] as String?;
  //       if (reservaId != null) {
  //         final navState = navigatorKey.currentState;
  //         if (navState == null) return;
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           if (navState.canPop()) {
  //             navState.pushNamed(
  //               '/reservas',
  //               arguments: {
  //                 'reservaIdNotificada': reservaId,
  //                 'forceShowAll': true,
  //               },
  //             );
  //           } else {
  //             navState.pushNamed('/', arguments: null);
  //             WidgetsBinding.instance.addPostFrameCallback((_) {
  //               navState.pushNamed(
  //                 '/reservas',
  //                 arguments: {
  //                   'reservaIdNotificada': reservaId,
  //                   'forceShowAll': true,
  //                 },
  //               );
  //             });
  //           }
  //         });
  //       }
  //     }
  //   });
  // }

  // void _cancelFcmListeners() {
  //   debugPrint('[AuthController] Cancelando listeners FCM');
  //   _onMessageSub?.cancel();
  //   _onMessageSub = null;
  //   _onMessageOpenedSub?.cancel();
  //   _onMessageOpenedSub = null;
  //   _fcmListenersInitialized = false;
  //   _gotInitialMessage = false;
  // }

  @override
  void dispose() {
    // _cancelFcmListeners();
    _fbAuthSub?.cancel();
    _appUserSub?.cancel();
    super.dispose();
  }

  // ...existing methods continue unmodified...
}
