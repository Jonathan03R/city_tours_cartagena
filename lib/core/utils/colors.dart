import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:flutter/material.dart';

class AppColors {
  static Color getEstadoColor(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.confirmada:
        return Colors.green.shade600;
      case EstadoReserva.pendiente:
        return Colors.orange.shade600;
      case EstadoReserva.cancelada:
        return Colors.red.shade600;
    }
  }

  static Color getEstadoBackgroundColor(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.confirmada:
        return Colors.green.shade50;
      case EstadoReserva.pendiente:
        return Colors.orange.shade50;
      case EstadoReserva.cancelada:
        return Colors.red.shade50;
    }
  }

  static Color getEstadoBorderColor(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.confirmada:
        return Colors.green.shade200;
      case EstadoReserva.pendiente:
        return Colors.orange.shade200;
      case EstadoReserva.cancelada:
        return Colors.red.shade200;
    }
  }

  // Colores principales de la app
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color secondary = Color(0xFF9C27B0);
  static const Color accent = Color(0xFFFF9800);
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Colores de fondo
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
}
