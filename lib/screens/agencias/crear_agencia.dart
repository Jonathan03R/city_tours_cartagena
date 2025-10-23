import 'dart:io';

import 'package:citytourscartagena/core/controller/agencias/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/models/agencia/agencia.dart';
import 'package:citytourscartagena/core/models/tipos/tipo_documento.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CrearAgenciaScreen extends StatefulWidget {
  const CrearAgenciaScreen({super.key});

  @override
  State<CrearAgenciaScreen> createState() => _CrearAgenciaScreenState();
}

class _CrearAgenciaScreenState extends State<CrearAgenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _beneficiarioController = TextEditingController();

  int? _tipoDocumentoSeleccionado;
  File? _logoArchivo;

  List<TipoDocumento> _tiposDocumentos = [];
  int? _operadorCodigo;
  int? _usuarioCodigo;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final operadoresController = context.read<OperadoresController>();
    final operador = await operadoresController.obtenerOperador();
    if (operador != null) {
      setState(() {
        _operadorCodigo = operador.id;
        _usuarioCodigo = operadoresController.codigoUsuario;
      });
    }

    final agenciasController = context.read<AgenciasControllerSupabase>();
    final tiposDocumentos = await agenciasController.obtenerTiposDocumentosActivos();

    setState(() {
      _tiposDocumentos = tiposDocumentos;
    });
  }

  Future<void> _seleccionarLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoArchivo = File(pickedFile.path);
      });
    }
  }

  Future<void> _crearAgencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tipoDocumentoSeleccionado != null && _beneficiarioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Beneficiario requerido cuando se selecciona tipo de documento')),
      );
      return;
    }

    if (_logoArchivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un logo')),
      );
      return;
    }

    if (_operadorCodigo == null || _usuarioCodigo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: operador o usuario no encontrado')),
      );
      return;
    }

    final agenciasController = context.read<AgenciasControllerSupabase>();

    try {
      await agenciasController.crearAgencia(
        datos: CrearAgenciaDTO(
          nombre: _nombreController.text.trim(),
          direccion: _direccionController.text.trim(),
          tipoDocumentoCodigo: _tipoDocumentoSeleccionado,
          beneficiario: _tipoDocumentoSeleccionado != null ? _beneficiarioController.text.trim() : null,
          tipoEmpresaCodigo: 1,
          logoUrl: null, // Se setea en el controller
          creadoPor: _usuarioCodigo!,
          operadorCodigo: _operadorCodigo!,
          ipOrigen: null, // Opcional
        ),
        logoArchivo: _logoArchivo!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agencia creada exitosamente')),
      );
      Navigator.of(context).pop(); // Regresar a la pantalla anterior
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear agencia: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agenciasController = context.watch<AgenciasControllerSupabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Agencia'),
      ),
      body: agenciasController.cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _tipoDocumentoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Tipo de Documento'),
                      items: _tiposDocumentos.map((tipo) {
                        return DropdownMenuItem<int>(
                          value: tipo.codigo,
                          child: Text(tipo.nombre),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _tipoDocumentoSeleccionado = value),
                      validator: (value) => null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _beneficiarioController,
                      decoration: const InputDecoration(labelText: 'Beneficiario'),
                      validator: (value) {
                        if (_tipoDocumentoSeleccionado != null && (value?.isEmpty ?? true)) {
                          return 'Campo requerido cuando se selecciona tipo de documento';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _seleccionarLogo,
                          child: const Text('Seleccionar Logo'),
                        ),
                        const SizedBox(width: 16),
                        if (_logoArchivo != null)
                          Image.file(_logoArchivo!, width: 50, height: 50, fit: BoxFit.cover),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _crearAgencia,
                        child: const Text('Crear Agencia'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _beneficiarioController.dispose();
    super.dispose();
  }
}
