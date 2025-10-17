import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:flutter/material.dart';

class AppColors {

  // Colores para modo oscuro (noche) - basados en el diseño de referencia
  static const Color darkPrimary = Color(0xFF0F1C2E); // Azul noche profundo
  static const Color darkSecondary = Color(0xFF1A2B42); // Azul noche más claro
  static const Color darkAccent = Color(0xFF2B4F81); // Azul medio para acentos
  static const Color darkSurface = Color(0xFF1E293B); // Superficie oscura
  static const Color darkCard = Color(0xFF0F172A); // Fondo de tarjetas oscuras
  
  // Colores para modo claro (día)
  static const Color lightPrimary = Color(0xFF3B82F6); // Azul brillante
  static const Color lightSecondary = Color(0xFF60A5FA); // Azul claro
  static const Color lightAccent = Color(0xFF1E40AF); // Azul oscuro para acentos
  static const Color lightSurface = Color(0xFFF8FAFC); // Superficie clara
  static const Color lightCard = Color(0xFFFFFFFF); // Fondo de tarjetas claras
  
  // Colores neutros
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  
  // Colores de estado
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // Gradientes para modo oscuro
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkPrimary, darkSecondary],
  );
  
  static const LinearGradient darkCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x14FFFFFF), // Blanco con 8% opacidad
      Color(0x08FFFFFF), // Blanco con 3% opacidad
    ],
  );
  
  static const LinearGradient darkButtonGradient = LinearGradient(
    colors: [darkAccent, darkSecondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // Gradientes para modo claro
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightPrimary, lightSecondary],
  );
  
  static const LinearGradient lightCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [white, gray100],
  );
  
  static const LinearGradient lightButtonGradient = LinearGradient(
    colors: [lightPrimary, lightAccent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  // Métodos para obtener colores según el tema
  static Color getPrimaryColor(bool isDark) => isDark ? darkPrimary : lightPrimary;
  static Color getSecondaryColor(bool isDark) => isDark ? darkSecondary : lightSecondary;
  static Color getAccentColor(bool isDark) => isDark ? darkAccent : lightAccent;
  static Color getSurfaceColor(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getCardColor(bool isDark) => isDark ? darkCard : lightCard;
  static Color getTextColor(bool isDark) => isDark ? white : gray900;
  static Color getSecondaryTextColor(bool isDark) => isDark ? gray300 : gray600;
  
  static LinearGradient getBackgroundGradient(bool isDark) => isDark ? darkGradient : lightGradient;
  static LinearGradient getCardGradient(bool isDark) => isDark ? darkCardGradient : lightCardGradient;
  static LinearGradient getButtonGradient(bool isDark) => isDark ? darkButtonGradient : lightButtonGradient;


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
  
  // Colores de fondo
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
}
