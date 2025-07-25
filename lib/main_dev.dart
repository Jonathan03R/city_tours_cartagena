import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reservas App',
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
