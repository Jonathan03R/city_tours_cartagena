import 'dart:io';

import 'package:citytourscartagena/core/models/enum/tipo_documento.dart';
import 'package:citytourscartagena/core/utils/parsers/parser_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CrearAgenciaForm extends StatefulWidget {
  final String? initialNombre;
  final String? initialImagenUrl;
  // final double? initialPrecioPorAsiento;
  final double? initialPrecioPorAsientoTurnoManana;
  final double? initialPrecioPorAsientoTurnoTarde;
  final TipoDocumento? initialTipoDocumento;
  final String? initialNumeroDocumento;
  final String? initialNombreBeneficiario;
  final Function(
    String nombre,
    XFile? imagenFile,
    double? precioPorAsientoTurnoManana,
    double? precioPorAsientoTurnoTarde,
    TipoDocumento? tipoDocumento,
    String numeroDocumento,
    String nombreBeneficiario,
  )
  onCrear;

  const CrearAgenciaForm({
    super.key,
    this.initialNombre,
    this.initialImagenUrl,
    // this.initialPrecioPorAsiento,
    this.initialPrecioPorAsientoTurnoManana,
    this.initialPrecioPorAsientoTurnoTarde,
    this.initialTipoDocumento,
    this.initialNumeroDocumento,
    this.initialNombreBeneficiario,
    required this.onCrear,
  });

  @override
  State<CrearAgenciaForm> createState() => _CrearAgenciaFormState();
}

class _CrearAgenciaFormState extends State<CrearAgenciaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioMananaController;
  late TextEditingController _precioTardeController;
  // Nuevos controladores
  // Tipo de documento seleccionado
  TipoDocumento? _selectedTipoDocumento;
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _nombreBeneficiarioController;
  XFile? _selectedImage;
  bool _isSaving = false;
  bool _clearExistingImage =
      false; // Nuevo estado para indicar si se debe eliminar la imagen existente

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.initialNombre);
    // Formatear el precio inicial para mostrarlo correctamente en el TextField
    // _precioController = TextEditingController(
    //   text: widget.initialPrecioPorAsiento != null
    //       ? ParserUtils.formatDoubleForInput(widget.initialPrecioPorAsiento!)
    //       : '',
    // );
    _precioMananaController = TextEditingController(
      text: widget.initialPrecioPorAsientoTurnoManana != null
          ? ParserUtils.formatDoubleForInput(
              widget.initialPrecioPorAsientoTurnoManana!,
            )
          : '',
    );
    _precioTardeController = TextEditingController(
      text: widget.initialPrecioPorAsientoTurnoTarde != null
          ? ParserUtils.formatDoubleForInput(
              widget.initialPrecioPorAsientoTurnoTarde!,
            )
          : '',
    );
    // Inicializar tipo de documento
    _selectedTipoDocumento = widget.initialTipoDocumento;
    _numeroDocumentoController = TextEditingController(
      text: widget.initialNumeroDocumento ?? '',
    );
    _nombreBeneficiarioController = TextEditingController(
      text: widget.initialNombreBeneficiario ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    // _precioController.dispose();
    _precioMananaController.dispose();
    _precioTardeController.dispose();
    // No hay controlador de tipo documento
    _numeroDocumentoController.dispose();
    _nombreBeneficiarioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = image;
      _clearExistingImage =
          false; // Si se selecciona una nueva imagen, no se borra la existente
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _clearExistingImage = true; // Marcar para eliminar la imagen existente
    });
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      final nombre = _nombreController.text.trim();
      // Sólo parsear si no está vacío, si no dejar null
      final double? precioManana = _precioMananaController.text.trim().isEmpty
          ? null
          : ParserUtils.parseDouble(_precioMananaController.text.trim());
      final double? precioTarde = _precioTardeController.text.trim().isEmpty
          ? null
          : ParserUtils.parseDouble(_precioTardeController.text.trim());
      final TipoDocumento? tipoDocumento = _selectedTipoDocumento;
      final numeroDocumento = _numeroDocumentoController.text.trim();
      final nombreBeneficiario = _nombreBeneficiarioController.text.trim();

      // Si se marcó para limpiar la imagen existente, pasar null para la URL de la imagen
      XFile? finalImageFile = _selectedImage;
      if (_clearExistingImage && _selectedImage == null) {
        // Si el usuario explícitamente borró la imagen y no seleccionó una nueva
        await widget.onCrear(
          nombre,
          null,
          precioManana,
          precioTarde,
          tipoDocumento,
          numeroDocumento,
          nombreBeneficiario,
        );
      } else {
        // Si hay una nueva imagen seleccionada o no se borró la existente
        await widget.onCrear(
          nombre,
          finalImageFile,
          precioManana,
          precioTarde,
          tipoDocumento,
          numeroDocumento,
          nombreBeneficiario,
        );
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialNombre != null ? 'Editar Agencia' : 'Crear Nueva Agencia',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Agencia',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // TextFormField(
              //   controller: _precioController,
              //   decoration: const InputDecoration(
              //     labelText: 'Precio por Asiento (opcional)',
              //     hintText: 'Ej: 50.000 o 50,000.00',
              //     border: OutlineInputBorder(),
              //     prefixIcon: Icon(Icons.attach_money),
              //   ),
              //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
              //   // No usamos un formatter restrictivo aquí para permitir varios formatos de entrada
              //   validator: (value) {
              //     if (value != null && value.isNotEmpty) {
              //       final parsed = ParserUtils.parseDouble(value);
              //       if (parsed == null || parsed < 0) {
              //         return 'Ingresa un precio válido (ej. 50.000 o 50,000.00)';
              //       }
              //     }
              //     return null;
              //   },
              // ),
              TextFormField(
                controller: _precioMananaController,
                decoration: const InputDecoration(
                  labelText: 'Precio Asiento (Mañana)',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: 'Ej: 50.000 o 50,000.00',
                  hintStyle: TextStyle(fontSize: 11),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                // No usamos un formatter restrictivo aquí para permitir varios formatos de entrada
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final parsed = ParserUtils.parseDouble(value);
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa un precio válido (ej. 50.000 o 50,000.00)';
                    }
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: _precioTardeController,
                decoration: const InputDecoration(
                  labelText: 'Precio Asiento (Tarde)',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: 'Ej: 50.000 o 50,000.00',
                  hintStyle: TextStyle(fontSize: 11),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final parsed = ParserUtils.parseDouble(value);
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa un precio válido (ej. 50.000 o 50,000.00)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Nuevo: Campo Tipo de Documento
              // Dropdown para Tipo de Documento
              DropdownButtonFormField<TipoDocumento?>(
                value: _selectedTipoDocumento,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Documento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                items: [
                  // opción nula
                  const DropdownMenuItem<TipoDocumento?>(
                    value: null,
                    child: Text('No especificado'),
                  ),
                  // todas las demás
                  ...TipoDocumento.values.map((td) {
                    final label = td.name.toUpperCase();
                    return DropdownMenuItem<TipoDocumento?>(
                      value: td,
                      child: Text(label),
                    );
                  }),
                ],
                onChanged: (td) => setState(() => _selectedTipoDocumento = td),
                // validator: (td) {
                //   if (td == null)
                //     return 'Por favor selecciona un tipo de documento';
                //   return null;
                // },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numeroDocumentoController,
                decoration: const InputDecoration(
                  labelText: 'Número de Documento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.document_scanner),
                ),
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Por favor ingresa número de documento';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreBeneficiarioController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Beneficiario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return 'Por favor ingresa nombre del beneficiario';
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 20),
              // Sección de selección y vista previa de imagen
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.image, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Imagen de la Agencia',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Seleccionar Imagen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_selectedImage != null ||
                            (widget.initialImagenUrl != null &&
                                !_clearExistingImage))
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: _clearImage,
                              tooltip: 'Eliminar imagen',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Vista previa de la imagen
                    if (_selectedImage != null)
                      Center(
                        child: Image.file(
                          File(_selectedImage!.path),
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (widget.initialImagenUrl != null &&
                        !_clearExistingImage)
                      Center(
                        child: Image.network(
                          widget.initialImagenUrl!,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 120,
                                width: 120,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          height: 120,
                          width: 120,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _selectedImage != null
                            ? 'Nueva imagen: ${_selectedImage!.name}'
                            : (widget.initialImagenUrl != null &&
                                  !_clearExistingImage)
                            ? 'Imagen actual'
                            : 'Ninguna imagen seleccionada',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.initialNombre != null
                      ? 'Guardar Cambios'
                      : 'Crear Agencia',
                ),
        ),
      ],
    );
  }
}
