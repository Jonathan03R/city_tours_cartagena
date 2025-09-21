class TiposContactos {
  final int id;
  final String nombre;
  final bool activo;

  TiposContactos({
    required this.id,
    required this.nombre,
    required this.activo,
  });
}

class Contactos{
  final int id;
  final String contacto;
  final TiposContactos tipo;


  Contactos({
    required this.id,
    required this.contacto,
    required this.tipo,
  });
}