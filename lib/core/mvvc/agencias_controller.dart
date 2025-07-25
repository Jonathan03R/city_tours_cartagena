import 'dart:io';

import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart'; // Necesario para contar reservas
import 'package:citytourscartagena/core/services/cloudinaryService.dart'; // Para subir imágenes
import 'package:citytourscartagena/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class AgenciasController extends ChangeNotifier {
  final FirestoreService _firestoreService;

  final BehaviorSubject<List<AgenciaConReservas>> _agenciasConReservasSubject =
      BehaviorSubject<List<AgenciaConReservas>>();
  Stream<List<AgenciaConReservas>> get agenciasConReservasStream => _agenciasConReservasSubject.stream;

  List<AgenciaConReservas> _agencias = [];
  List<AgenciaConReservas> get agencias => _agencias;

  AgenciasController({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService() {
    _listenToAgenciasAndReservas();
  }

  void _listenToAgenciasAndReservas() {
    final agenciasStream = _firestoreService.getAgenciasStream();
    final reservasStream = _firestoreService.getReservasStream(); // Obtener todas las reservas

    Rx.combineLatest2(
      agenciasStream,
      reservasStream,
      (List<Agencia> agencias, List<Reserva> reservas) {
        final activeAgencias = agencias.where((ag) => ag.eliminada == false).toList();
        return activeAgencias.map((agencia) {
          final totalReservas = reservas.where((r) => r.agenciaId == agencia.id).length;
          return AgenciaConReservas(agencia: agencia, totalReservas: totalReservas);
        }).toList();
      },
    ).listen((data) {
      _agencias = data;
      _agenciasConReservasSubject.add(data);
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error en AgenciasController stream: $error');
      _agenciasConReservasSubject.addError(error);
    });
  }

  // Método para obtener una agencia por su ID (útil para dropdowns, etc.)
  Agencia? getAgenciaById(String id) {
    return _agencias.firstWhereOrNull((ag) => ag.id == id)?.agencia;
  }

  Future<Agencia> addAgencia(String nombre, String? imagePath, {double? precioPorAsiento}) async { // MODIFICADO: Añadir precioPorAsiento
    String? imageUrl;
    if (imagePath != null) {
      imageUrl = await CloudinaryService.uploadImage(File(imagePath));
    }
    final nuevaAgencia = Agencia(id: '', nombre: nombre, imagenUrl: imageUrl, precioPorAsiento: precioPorAsiento); // NUEVO
    final addedAgencia = await _firestoreService.addAgencia(nuevaAgencia);
    return addedAgencia;
  }

  Future<void> updateAgencia(String id, String nombre, String? imagePath, String? currentImageUrl, {double? newPrecioPorAsiento}) async { // MODIFICADO: Añadir newPrecioPorAsiento
    String? imageUrl = currentImageUrl;
    if (imagePath != null) {
      imageUrl = await CloudinaryService.uploadImage(File(imagePath));
    }

    // Obtener la agencia actual para comparar el precio
    final currentAgencia = _agencias.firstWhereOrNull((ag) => ag.id == id)?.agencia;

    final updatedAgencia = Agencia(
      id: id,
      nombre: nombre,
      imagenUrl: imageUrl,
      eliminada: currentAgencia?.eliminada ?? false, // Mantener el estado de eliminada
      precioPorAsiento: newPrecioPorAsiento, // NUEVO
    );

    await _firestoreService.updateAgencia(id, updatedAgencia);

    // Si el precio por asiento ha cambiado, actualizar todas las reservas asociadas
    if (currentAgencia?.precioPorAsiento != newPrecioPorAsiento) {
      if (newPrecioPorAsiento != null) {
        await _firestoreService.updateReservasCostoAsiento(id, newPrecioPorAsiento);
      }
    }
  }

  Future<void> softDeleteAgencias(Set<String> ids) async {
    for (var id in ids) {
      // En lugar de eliminar, actualizamos el campo 'eliminada'
      // Necesitamos obtener la agencia actual para mantener sus otros campos
      final currentAgencia = _agencias.firstWhereOrNull((ag) => ag.id == id)?.agencia;
      if (currentAgencia != null) {
        await _firestoreService.updateAgencia(
          id,
          currentAgencia.copyWith(eliminada: true),
        );
      }
    }
  }

  // Método para obtener todas las agencias (útil para dropdowns)
  List<Agencia> getAllAgencias() {
    return _agencias.map((a) => a.agencia).toList();
  }

  @override
  void dispose() {
    _agenciasConReservasSubject.close();
    super.dispose();
  }
}

// Extensión para firstWhereOrNull, ya que no está en todas las versiones de Dart
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
