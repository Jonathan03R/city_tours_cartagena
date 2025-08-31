enum TurnoType { manana, tarde, privado }
extension TurnoTypeLabel on TurnoType {
  String get label {
    switch (this) {
      case TurnoType.manana:
        return 'Turno Mañana';
      case TurnoType.tarde:
        return 'Turno Tarde';
      case TurnoType.privado:
        return 'Servicio Privado';
    }
  }
}