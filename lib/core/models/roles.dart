class Roles {
  static const String admin = 'admin';
  static const String agencia = 'agencia';
  // static const String colaborador = 'colaborador';
  // static const String trabajador = 'trabajador';

  static const String reportar = 'reportar';
  /// roles especificos
  /// AGENCIAS
  static const String crearAgencias = 'crear agencias';
  static const String editarAgencias = 'editar agencias';
  static const String verAgencias = 'ver agencias';
  
  /// RESERVAS
  static const String crearReservas = 'crear reservas';
  static const String editarReservas = 'editar reservas';
  static const String verReservas = 'ver reservas';
  static const String verDeudasReservas = 'ver deudas reservas';

  /// Colaboradores
  static const String verColaborador = 'ver colaborador';

  /// Ver finanzas
  static const String verFinanzas = 'ver finanzas';

  // ver_cards_metas,
  // ver_cards_gastos,

  // ver_graficos_pasajeros,
  // ver_graficos_gastos,


  // ver_graficos_pasajeros_semanal,
  // ver_graficos_gastos_semanal,
  // /// ver graficos
  static const String verGraficosPasajeros = 'ver grafico de pasajeros';
  static const String verGraficosGastos = 'ver grafico de gastos';
  static const String verCardMetas = "Ver metas";
  static const String verCardGastos = "ver gastos";
  static const String verGraficoSemanalPasajero = "ver grafico semanal de pasajeros";
  static const String verGraficoSemanalGastos = "ver grafico semanal de gastos";

  static List<String> get allRoles => [
        admin,
        agencia,
        reportar,
        crearAgencias,
        editarReservas,
        crearReservas,
        editarAgencias,
        verAgencias,
        verReservas,
        verColaborador,
        verFinanzas,
        verDeudasReservas,
        verGraficosPasajeros,
        verGraficosGastos,
        verGraficoSemanalPasajero,
        verGraficoSemanalGastos,
        verCardGastos,
        verCardMetas
      ];

}