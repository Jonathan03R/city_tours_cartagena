import 'package:citytourscartagena/auth/auth_gate.dart';
import 'package:citytourscartagena/core/models/usuarios.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
// ...existing code (navigatorKey, etc.)...

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
                .map((snap) =>
                    snap.exists ? Usuarios.fromJson(snap.data()!) : null);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Reservas App',
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES')],
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}