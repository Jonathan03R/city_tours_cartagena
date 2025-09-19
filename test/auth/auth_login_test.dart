import 'package:citytourscartagena/core/controller/auth/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Inicializa Supabase antes de ejecutar los tests
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({}); // Mock para SharedPreferences
    await dotenv.load(fileName: ".env");

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  });

  late AuthSupabaseController controller;

  setUp(() {
    controller = AuthSupabaseController();
  });

  test('register creates a user in Supabase and database', () async {
    // Llama al método register con datos de prueba
    await controller.register(
      nombre: 'test1',
      apellido: 'User',
      email: 'test123@gmail.com',
      password: 'test0312',
      alias: 'test12',
      rol: 2,
      tipoUsuario: 'operador',
      codigoRelacion: 1,
    );

    // Verifica que el usuario se haya registrado
    expect(controller.usuario, isNotNull);
    expect(controller.usuario?.email, 'test123@gmail.com');
    debugPrint('Usuario registrado: ${controller.usuario?.toMap()}');
  });
}