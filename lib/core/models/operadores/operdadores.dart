

class Operadores{
    final int id;
    final String nombre;
    final String beneficiario; 
    final int tipoEmpresa;
    final String? logo;
    final int tipoDocumento;
    final String? documento;
    final String? direccion;

    Operadores({
        required this.id,
        required this.nombre,
        required this.beneficiario,
        required this.tipoEmpresa,
        this.logo,
        required this.tipoDocumento,
        this.documento,
        this.direccion,
    });


    factory Operadores.fromMap(Map<String, dynamic> map) {
        return Operadores(
            id: map ['operador_codigo'] as int,
            nombre: map ['operador_nombre'] as String,
            beneficiario: map ['operador_beneficiario'] as String,  
            tipoEmpresa: map ['tipo_empresa_codigo'] as int,
            logo: map ['operador_logo'] as String?,
            tipoDocumento: map ['tipo_documento_codigo'] as int,
            documento: map ['operador_documento'] as String?,
            direccion: map ['operador_direccion'] as String?,
        );
    }

}