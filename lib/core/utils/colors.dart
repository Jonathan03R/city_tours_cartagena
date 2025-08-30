import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:flutter/material.dart';

class AppColors {
  // Colores principales - Azul noche y blanco
  static const Color primaryNightBlue = Color(0xFF0A1628);
  static const Color secondaryNightBlue = Color(0xFF1E293B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF60A5FA);
  
  // Colores de fondo
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  
  // Colores de estado
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryNightBlue, secondaryNightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static Color getEstadoColor(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.pagada:
        return Colors.green.shade600;
      case EstadoReserva.pendiente:
        return Colors.orange.shade600;
      case EstadoReserva.cancelada:
        return Colors.red.shade600;
    }
  }

  static Color getEstadoBackgroundColor(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.pagada:
        return Colors.green.shade50;
      case EstadoReserva.pendiente:
        return Colors.orange.shade50;
      case EstadoReserva.cancelada:
        return Colors.red.shade50;
    }
  }

  static Color getEstadoBorderColor(EstadoReserva estado) {
    switch (estado) {
      case EstadoReserva.pagada:
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
  // static const Color success = Color(0xFF4CAF50);
  // static const Color warning = Color(0xFFFF9800);
  // static const Color error = Color(0xFFF44336);
  // static const Color info = Color(0xFF2196F3);
  
  // Colores de fondo
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  // static const Color cardBackground = Color(0xFFFFFFFF);
}
