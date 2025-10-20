class ColorModel {
  final int codigo;
  final String prefijo;
  final bool activo;
  final String nombre;

  ColorModel({
    required this.codigo,
    required this.prefijo,
    required this.activo,
    required this.nombre,
  });

  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(
      codigo: json['color_codigo'] as int,
      prefijo: json['color_prefijo'] as String,
      activo: json['color_activo'] as bool,
      nombre: json['color_nombre'] as String,
    );
  }
}