enum Permission {
  // DEUDAS
  ver_deuda_reservas,
  ver_deuda_agencia,

  // AGENCIAS
  change_agency,
  edit_agencias,
  ver_agencias,

  // CONTACTO
  contact_whatsapp,

  // RESERVAS
  delete_reserva,
  edit_reserva,
  export_reservas,
  manage_observations, /// Observaciones
  select_reservas, ///seleccionar reservas
  toggle_paid_status, /// Cambiar estado de pago
  ver_reservas, /// Ver reservas pestaña

  // CONFIGURACIÓN
  edit_configuracion,

  /// CREAR
  crear_agencias,
  crear_reserva,

  /// USUARIOS
  ver_perfil,
  ver_todos_usuarios,
  ver_pagina_usuarios,
  



  // Añade aquí cualquier otra acción granular que necesites controlar
}