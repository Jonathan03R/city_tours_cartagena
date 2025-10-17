import 'package:citytourscartagena/auth/auth_gate.dart';
import 'package:citytourscartagena/core/models/usuarios.dart';
import 'package:citytourscartagena/core/widgets/offline_banner.dart';
import 'package:citytourscartagena/screens/reservas/reservas_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
  // debugPrint('📐 Dimensiones del dispositivo: ancho=${size.width}, alto=${size.height}');
    return ScreenUtilInit(
      /// Inicializa ScreenUtil con el tamaño de diseño base
      designSize: const Size(490, 1074), // Tamaño de diseño base (iPhone X)
      /// Permite la adaptación del texto a diferentes tamaños de pantalla
      minTextAdapt: true,

      /// Habilita el modo de pantalla dividida
      splitScreenMode: true,
      builder: (context, child) { 
        return MultiProvider(
          providers: [
            // Stream de FirebaseAuth
            StreamProvider<User?>.value(
              value: FirebaseAuth.instance.authStateChanges(),
              initialData: null,
            ),
            // Stream del documento usuarios/{uid}
            StreamProvider<Usuarios?>(
              initialData: null,
              create: (_) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return const Stream.empty();
                return FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(uid)
                    .snapshots()
                    .map(
                      (snap) =>
                          snap.exists ? Usuarios.fromJson(snap.data()!) : null,
                    );
              },
            ),
          ],
          child: MaterialApp(
            title: 'Reservas App',
            navigatorKey: navigatorKey,
            routes: {
              '/reservas': (context) {
                final args = ModalRoute.of(context)?.settings.arguments;
                String? reservaIdNotificada;
                DateTime? customDate;
                // bool forceShowAll = false;

                if (args is Map<String, dynamic>) {
                  reservaIdNotificada = args['reservaIdNotificada'] as String?;
                  customDate = args['fechaReserva'] as DateTime?;
                  // forceShowAll = args['forceShowAll'] as bool? ?? false;
                } else if (args is String) {
                  reservaIdNotificada = args;
                }

                return ReservasView(
                  reservaIdNotificada: reservaIdNotificada,
                  customDate: customDate, 
                  // forceShowAll: forceShowAll,
                );
              },
              // ...otras rutas
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('es', 'ES')],
            theme: ThemeData(
              dataTableTheme: DataTableThemeData(
                headingTextStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                dataTextStyle: TextStyle(fontSize: 16.sp),
                dataRowHeight: 50.h,
                headingRowHeight: 44.h,
              ),
              snackBarTheme: SnackBarThemeData(
                  behavior: SnackBarBehavior.fixed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
            ),
            home: const AuthGate(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const OfflineBanner(), // overlay global
                ],
              );
            },
          ),
        );
      },
    );
  }
}
