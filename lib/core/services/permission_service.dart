import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:citytourscartagena/core/models/roles.dart';

class PermissionService {
  // Este mapa define qué permisos tiene cada rol (como String).
  // Puedes cargar esto desde una base de datos o configuración remota si necesitas que sea dinámico.
  static const Map<String, List<Permission>> _rolePermissions = {
    Roles.admin: [
      Permission.edit_reserva,
      Permission.delete_reserva,
      Permission.view_debt,
      Permission.contact_whatsapp,
      Permission.toggle_paid_status,
      Permission.manage_observations,
      Permission.select_reservas,
      Permission.change_agency,
      Permission.edit_configuracion,
      Permission.export_reservas,
      Permission.edit_agencias,
      Permission.crear_agencias,
      Permission.view_usuarios,
      
      
      // Un administrador tiene todos los permisos
    ],
    Roles.colaborador: [
      // Un colaborador puede editar, ver deuda, contactar, etc., pero no eliminar ni cambiar agencia
    ],
    Roles.agencia: [
      Permission.contact_whatsapp,
      Permission.manage_observations,
      Permission.select_reservas,
      // Una agencia solo puede contactar, ver observaciones y seleccionar
    ],
    Roles.trabajador: [
      Permission.contact_whatsapp,
      Permission.manage_observations,
      Permission.select_reservas,
      // Permission.edit_agencias,
    ],
    Roles.reservas: [
      // Define permisos específicos para el rol 'reservas' si es distinto de 'colaborador'
      Permission.contact_whatsapp,
      Permission.manage_observations,
      Permission.select_reservas,
      // Ejemplo: quizás 'reservas' solo puede ver, no editar
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
