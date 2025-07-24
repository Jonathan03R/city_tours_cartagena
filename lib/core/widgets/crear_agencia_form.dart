import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CrearAgenciaForm extends StatefulWidget {
  final String? initialNombre;
  final File? initialImagenFile;
  final String? initialImagenUrl;               // ← Nuevo, opcional
  final void Function(String nombre, File? imagen) onCrear;

  const CrearAgenciaForm({
    super.key,
    this.initialNombre,
    this.initialImagenFile,
    this.initialImagenUrl,                      // ← Nuevo
    required this.onCrear,
  });

  @override
  State<CrearAgenciaForm> createState() => _CrearAgenciaFormState();
}

class _CrearAgenciaFormState extends State<CrearAgenciaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  File? _imagenSeleccionada;
  bool _borrarImagen = false;

  @override
  void initState() {
    super.initState();
    // Nombre pre-cargado
    _nombreController = TextEditingController(text: widget.initialNombre ?? '');
    // Si llamas con initialImagenFile (File), lo cargas; sino null
    _imagenSeleccionada = widget.initialImagenFile;
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imagenSeleccionada = File(picked.path);
        _borrarImagen = false;
      });
    }
  }

  void _toggleBorrarImagen() {
    setState(() {
      _borrarImagen = !_borrarImagen;
      if (_borrarImagen) _imagenSeleccionada = null;
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final imagenParaEnviar = _borrarImagen ? null : _imagenSeleccionada;
    widget.onCrear(_nombreController.text.trim(), imagenParaEnviar);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Decide qué mostrar en el avatar:
    ImageProvider? avatarImage;
    if (_imagenSeleccionada != null) {
      avatarImage = FileImage(_imagenSeleccionada!);
    } else if (!_borrarImagen && widget.initialImagenFile != null) {
      avatarImage = FileImage(widget.initialImagenFile!);
    } else if (!_borrarImagen && widget.initialImagenUrl != null) {
      avatarImage = NetworkImage(widget.initialImagenUrl!);
    }

    return AlertDialog(
      title: Text(widget.initialNombre != null ? 'Editar Agencia' : 'Agregar Agencia'),
      content: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.topRight, children: [
            GestureDetector(
              onTap: _seleccionarImagen,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: avatarImage,
                child: avatarImage == null ? const Icon(Icons.add_a_photo, size: 32) : null,
              ),
            ),
            if (avatarImage != null)
              IconButton(
                icon: Icon(_borrarImagen ? Icons.undo : Icons.delete, color: Colors.red),
                onPressed: _toggleBorrarImagen,
              ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: 'Nombre de la agencia'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
