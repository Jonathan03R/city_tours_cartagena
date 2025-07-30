class Roles {
  static const String admin = 'admin';
  static const String agencia = 'agencia';
  static const String colaborador = 'colaborador';
  static const String reservas = 'reservas';
  static const String trabajador = 'trabajador';


  static List<String> get allRoles => [
        admin,
        agencia,
        colaborador,
        reservas,
        trabajador,
      ];

}