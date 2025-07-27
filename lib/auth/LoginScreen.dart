import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _userCtrl,
              decoration: InputDecoration(labelText: 'Usuario'),
            ),
            TextField(
              controller: _passCtrl,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            auth.isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () => auth.login(_userCtrl.text, _passCtrl.text),
                  child: Text('Ingresar'),
                ),
          ],
        ),
      ),
    );
  }
}