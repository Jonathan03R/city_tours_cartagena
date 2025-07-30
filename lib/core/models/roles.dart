class Roles {
  static const String admin = 'admin';
  static const String agencia = 'agencia';
  static const String colaborador = 'colaborador';
  static const String trabajador = 'trabajador';

  static const String reportar = 'reportar';
  /// roles especificos
  /// AGENCIAS
  static const String crearAgencias = 'crear agencias';
  static const String editarAgencias = 'editar agencias';
  
  /// RESERVAS
  static const String editarReservas = 'editar reservas';

  static List<String> get allRoles => [
        admin,
        agencia,
        colaborador,
        trabajador,
        reportar,
        crearAgencias,
        editarReservas,
      ];

}