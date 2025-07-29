import 'dart:async';

import 'package:citytourscartagena/core/models/roles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/usuarios.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _service;
  User? user;
  Usuarios? appUser;
  bool isLoading = false;

  StreamSubscription<User?>? _fbAuthSub;
  StreamSubscription<DocumentSnapshot>? _appUserSub;

  AuthController(this._service) {
    // 1) FirebaseAuth
    user = FirebaseAuth.instance.currentUser;
    _fbAuthSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      user = u;
      notifyListeners();
      _subscribeToAppUser();
    });
  }

  void _subscribeToAppUser() {
    _appUserSub?.cancel();

    if (user == null) {
      appUser = null;
      notifyListeners();
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid);

    _appUserSub = docRef.snapshots().listen((snap) async {
      if (snap.exists && snap.data() != null) {
        appUser = Usuarios.fromMap(snap.data()!);
      } else {
        final correo = user!.email ?? '';
        final soloUsuario = correo.split('@').first;
        // Crear usuario nuevo si no existe
        final nuevoUsuario = Usuarios(
          id: user!.uid,
          nombre: null,
          usuario: soloUsuario,
          email: null,
          telefono: null,
          roles: [Roles.colaborador],
        );

        await docRef.set(nuevoUsuario.toJson());
        appUser = nuevoUsuario;
      }

      notifyListeners();
    });
  }

  Future<void> login(String username, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      await _service.signIn(username, password);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.signOut();
  }

  @override
  void dispose() {
    _fbAuthSub?.cancel();
    _appUserSub?.cancel();
    super.dispose();
  }
}
