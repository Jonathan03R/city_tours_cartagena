import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Necesario para FirebaseApp

class AuthService {
  final _fb = FirebaseAuth.instance; // Instancia de Firebase Auth por defecto

  // Segunda instancia de Firebase App y Auth para operaciones de administrador
  static FirebaseApp? _adminApp;
  static FirebaseAuth? _adminFb;

  AuthService() {
    _initializeAdminApp(); // Asegura que la app de admin se inicialice al crear AuthService
  }

  // Inicializa la segunda instancia de Firebase App y Auth
  Future<void> _initializeAdminApp() async {
    if (_adminApp == null) {
      try {
        // Obtener las opciones de la app por defecto
        final defaultAppOptions = Firebase.app().options;
        _adminApp = await Firebase.initializeApp(
          name: 'adminApp', // Un nombre único para la app secundaria
          options: defaultAppOptions,
        );
        _adminFb = FirebaseAuth.instanceFor(app: _adminApp!);
      } on FirebaseException catch (e) {
        // Manejar el error si la app de admin ya existe (ej. hot reload)
        if (e.code == 'duplicate-app') {
          _adminApp = Firebase.app('adminApp');
          _adminFb = FirebaseAuth.instanceFor(app: _adminApp!);
        } else {
          rethrow; // Relanzar otros errores inesperados
        }
      } catch (e) {
        rethrow; // Relanzar cualquier otra excepción
      }
    }
  }

  String _toAuthEmail(String user) => '$user@citytours.local';

  // Métodos originales para el usuario principal (login/signup)
  Future<UserCredential> signUp(String user, String pass) {
    return _fb.createUserWithEmailAndPassword(
      email: _toAuthEmail(user),
      password: pass,
    );
  }

  Future<UserCredential> signIn(String user, String pass) {
    return _fb.signInWithEmailAndPassword(
      email: _toAuthEmail(user),
      password: pass,
    );
  }
  
  Future<void> signOut() => _fb.signOut();

  // Nuevo método para que el administrador cree usuarios sin afectar su sesión
  Future<UserCredential> adminSignUp(String user, String pass) async {
    await _initializeAdminApp(); // Asegura que la app de admin esté inicializada
    if (_adminFb == null) {
      throw Exception('Admin Firebase App no inicializada.');
    }
    // Usa la instancia de Firebase Auth de la app secundaria
    return _adminFb!.createUserWithEmailAndPassword(
      email: _toAuthEmail(user), // Usa la misma convención de email
      password: pass,
    );
  }
}
