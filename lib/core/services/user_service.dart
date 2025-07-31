import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // Para debugPrint

import '../models/usuarios.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Usuarios>> getAllUsersStream() {
    return _firestore.collection('usuarios').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Usuarios.fromMap(doc.data())).toList();
    });
  }

  Stream<Usuarios?> getUserStream(String uid) {
    return _firestore.collection('usuarios').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = <String, dynamic>{...snap.data()!};
      data['id'] = snap.id; // inyecta el UID
      return Usuarios.fromMap(data); // lee activo tal cual
    });
  }

  // Guardar datos del usuario en Firestore (usado para crear o actualizar)
  Future<void> saveUserData(String uid, Usuarios userModel) async {
    try {
      await _firestore
          .collection('usuarios')
          .doc(uid)
          .set(userModel.toJson(), SetOptions(merge: true));
      debugPrint(
        '✅ Datos de usuario $uid guardados/actualizados en Firestore.',
      );
    } catch (e) {
      debugPrint('Error al guardar datos de usuario $uid en Firestore: $e');
      rethrow;
    }
  }

  // Actualizar datos de usuario en Firestore (solo campos específicos)
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update(data);
      debugPrint('✅ Datos de usuario $uid actualizados: $data');
    } catch (e) {
      debugPrint('Error al actualizar datos de usuario $uid: $e');
      rethrow;
    }
  }

  // Actualizar la contraseña del usuario actual (Firebase Auth)
  Future<void> updateCurrentUserPassword(String newPassword) async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePassword(newPassword);
        debugPrint('✅ Contraseña del usuario actual actualizada.');
      } else {
        throw Exception(
          'No hay usuario autenticado para actualizar la contraseña.',
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Error de Firebase Auth al actualizar contraseña: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('Error al actualizar contraseña: $e');
      rethrow;
    }
  }

  // Activar/Desactivar un usuario
  Future<void> toggleUserActiveStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection('usuarios').doc(uid).update({
        'activo': isActive,
      });
      debugPrint('✅ Estado de usuario $uid cambiado a activo: $isActive');
    } catch (e) {
      debugPrint('Error al cambiar estado de usuario $uid: $e');
      rethrow;
    }
  }

  Future<Usuarios?> getUserOnce(String uid) async {
    final doc = await _firestore.collection('usuarios').doc(uid).get();

    if (!doc.exists) {
      print('[getUserOnce] ❌ No existe el documento con UID: $uid');
      return null;
    }

    final data = doc.data();
    print('[getUserOnce] 📄 Datos del usuario obtenidos:');
    data?.forEach((key, value) {
      print('🔹 $key: $value');
    });

    return Usuarios.fromMap(data!);
  }
}
