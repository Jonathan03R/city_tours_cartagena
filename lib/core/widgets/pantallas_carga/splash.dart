import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            // logo
            FlutterLogo(size: 96),
            SizedBox(height: 24),
            // texto opcional
            Text('City Tours', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            // indicador
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
