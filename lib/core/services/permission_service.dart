import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/roles.dart';

class PermissionService {
  // Este mapa define qué permisos tiene cada rol (como String).
  // Puedes cargar esto desde una base de datos o configuración remota si necesitas que sea dinámico.
  static const Map<String, List<Permission>> _rolePermissions = {
    Roles.admin       : Permission.values,
    // Roles.colaborador: [
    //   // Un colaborador puede editar, ver deuda, contactar, etc., pero no eliminar ni cambiar agencia
    // ],
    Roles.agencia: [
      Permission.ver_reservas,
      Permission.contact_whatsapp,
      Permission.ver_pagina_usuarios,
      // Permission.crear_reserva,
      Permission.crear_agencias_agencias,
      Permission.ver_deuda_reservas,
      Permission.crear_reserva,

      // Permission.manage_observations,
      // Permission.select_reservas,
      // Una agencia solo puede contactar, ver observaciones y seleccionar
    ],
    // Roles.trabajador: [
    //   Permission.contact_whatsapp,
    //   // Permission.manage_observations,
    //   Permission.select_reservas,
    //   // Permission.edit_agencias,
    // ],
    
    Roles.crearAgencias: [
      Permission.crear_agencias,
      // Define permisos específicos para el rol 'crearAgencias'
    ],
    Roles.editarReservas: [
      Permission.edit_reserva,
      // Define permisos específicos para el rol 'editarReservas'
    ],
    Roles.verAgencias: [
      Permission.ver_agencias,
      Permission.ver_pagina_usuarios,
      // Define permisos específicos para el rol 'verAgencias'
    ],

    Roles.verReservas: [
      Permission.ver_reservas,
      Permission.contact_whatsapp,
      Permission.ver_pagina_usuarios,
      Permission.recibir_notificaciones,
      // Define permisos específicos para el rol 'verReservas'
    ],
    Roles.verColaborador: [
      Permission.ver_pagina_usuarios,

      // Define permisos específicos para el rol 'verColaborador'
    ],

    Roles.verFinanzas: [
      Permission.ver_deuda_agencia,
    ],

    Roles.verDeudasReservas: [
      Permission.ver_deuda_reservas,
    ],

    // Roles.reservas: [
    //   // Define permisos específicos para el rol 'reservas' si es distinto de 'colaborador'
    //   Permission.contact_whatsapp,
    //   Permission.manage_observations,
    //   Permission.select_reservas,
    //   // Ejemplo: quizás 'reservas' solo puede ver, no editar
    // ],
    Roles.reportar: [
      Permission.export_reservas,
      // Define permisos específicos para el rol 'reportador'
    ],

    Roles.editarAgencias: [
      Permission.edit_agencias,
      // Define permisos específicos para el rol 'editarAgencias'
    ],

    Roles.crearReservas: [
      Permission.crear_reserva,
      // Define permisos específicos para el rol 'crearReservas'
    ],


  };

  /// Verifica si un rol específico (String) tiene un permiso dado.
  bool _hasPermissionForRole(String role, Permission permission) {
    return _rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Verifica si alguna de las roles de un usuario (List<String>) tiene un permiso dado.
  bool hasAnyPermission(List<String> userRoles, Permission permission) {
    for (final role in userRoles) {
      if (_hasPermissionForRole(role, permission)) {
        return true;
      }
    }
    return false;
  }
}
