import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/models/operadores/contacto_operador.dart';
import 'package:citytourscartagena/core/models/operadores/operdadores.dart';
import 'package:citytourscartagena/core/models/tipos/tipo_contacto.dart';
import 'package:citytourscartagena/core/utils/colors.dart';
import 'package:flutter/material.dart';

class ConfigOperadoresScreems extends StatefulWidget {
  final OperadoresController controller;

  const ConfigOperadoresScreems({super.key, required this.controller});

  @override
  State<ConfigOperadoresScreems> createState() => _ConfigOperadoresScreemsState();
}

class _ConfigOperadoresScreemsState extends State<ConfigOperadoresScreems> {
  final _formKey = GlobalKey<FormState>();
  Operadores? _operador;
  List<ContactoOperador> _contactos = [];
  List<Map<String, dynamic>> _tiposEmpresas = [];
  List<Map<String, dynamic>> _tiposDocumentos = [];
  List<TipoContacto> _tiposContactos = [];

  // Controllers for form fields
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _beneficiarioController = TextEditingController();
  final TextEditingController _documentoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  int? _selectedTipoEmpresa;
  int? _selectedTipoDocumento;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final operador = await widget.controller.obtenerOperador();
      final contactos = await widget.controller.obtenerContactosOperador();
      final tiposEmpresas = await widget.controller.obtenerTiposEmpresasActivos();
      final tiposDocumentos = await widget.controller.obtenerTiposDocumentosActivos();
      final tiposContactos = await widget.controller.obtenerTiposContactosActivos();

      setState(() {
        _operador = operador;
        _contactos = contactos;
        _tiposEmpresas = tiposEmpresas;
        _tiposDocumentos = tiposDocumentos;
        _tiposContactos = tiposContactos;

        if (_operador != null) {
          _nombreController.text = _operador!.nombre;
          _beneficiarioController.text = _operador!.beneficiario;
          _documentoController.text = _operador!.documento ?? '';
          _direccionController.text = _operador!.direccion ?? '';
          _selectedTipoEmpresa = _operador!.tipoEmpresa;
          _selectedTipoDocumento = _operador!.tipoDocumento;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando datos: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddContactoDialog() {
    final TextEditingController descController = TextEditingController();
    int? selectedTipo;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Contacto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedTipo,
              items: _tiposContactos.map((tipo) => DropdownMenuItem(
                value: tipo.id,
                child: Text(tipo.descripcion),
              )).toList(),
              onChanged: (value) => selectedTipo = value,
              decoration: const InputDecoration(labelText: 'Tipo de Contacto'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedTipo != null && descController.text.isNotEmpty) {
                try {
                  await widget.controller.crearContacto(
                    tipoContactoCodigo: selectedTipo!,
                    descripcion: descController.text,
                  );
                  Navigator.of(context).pop();
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creando contacto: $e')),
                  );
                }
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditContactoDialog(ContactoOperador contacto) {
    final TextEditingController descController = TextEditingController(text: contacto.descripcion);
    int? selectedTipo = contacto.tipoContactoCodigo;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Contacto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: selectedTipo,
              items: _tiposContactos.map((tipo) => DropdownMenuItem(
                value: tipo.id,
                child: Text(tipo.descripcion),
              )).toList(),
              onChanged: (value) => selectedTipo = value,
              decoration: const InputDecoration(labelText: 'Tipo de Contacto'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedTipo != null && descController.text.isNotEmpty) {
                try {
                  await widget.controller.actualizarContacto(
                    contactoId: contacto.id,
                    tipoContactoCodigo: selectedTipo,
                    descripcion: descController.text,
                  );
                  Navigator.of(context).pop();
                  _loadData();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error actualizando contacto: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteContacto(ContactoOperador contacto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Contacto'),
        content: const Text('¿Estás seguro de que deseas eliminar este contacto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await widget.controller.eliminarContacto(contactoId: contacto.id);
                Navigator.of(context).pop();
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error eliminando contacto: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Operador'),
          backgroundColor: AppColors.getPrimaryColor(isDark),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Operador'),
        backgroundColor: AppColors.getPrimaryColor(isDark),
        leading: _isEditing ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _isEditing = false),
        ) : null,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveAndExitEdit,
            ),
        ],
      ),
      body: _isEditing ? _buildEditView(isDark) : _buildViewMode(isDark),
      floatingActionButton: _isEditing ? null : FloatingActionButton(
        heroTag: 'config_operadores_fab', // evita colisión con otros FABs
        onPressed: _showAddContactoDialog,
        backgroundColor: AppColors.getAccentColor(isDark),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildViewMode(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección Información del Operador
          Card(
            elevation: 4,
            color: AppColors.getCardColor(isDark),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Información del Operador', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _operador?.logo != null && _operador!.logo!.isNotEmpty
                            ? NetworkImage(_operador!.logo!)
                            : null,
                        child: _operador?.logo == null || _operador!.logo!.isEmpty
                            ? const Icon(Icons.business, size: 40, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_operador?.nombre ?? '', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                            Text(_operador?.beneficiario ?? '', style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow('Tipo Empresa', _tiposEmpresas.firstWhere((t) => t['tipo_empresa_codigo'] == _operador?.tipoEmpresa, orElse: () => {'tipo_empresa_nombre': ''})['tipo_empresa_nombre'], isDark),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoRow('Tipo Documento', _tiposDocumentos.firstWhere((t) => t['tipo_documento_codigo'] == _operador?.tipoDocumento, orElse: () => {'tipo_documento_nombre': ''})['tipo_documento_nombre'], isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow('Documento', _operador?.documento ?? '', isDark),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoRow('Dirección', _operador?.direccion ?? '', isDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Sección Contactos
          Text('Contactos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _contactos.length,
            itemBuilder: (context, index) {
              final contacto = _contactos[index];
              final tipo = _tiposContactos.firstWhere((t) => t.id == contacto.tipoContactoCodigo);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: AppColors.getCardColor(isDark),
                child: ListTile(
                  leading: const Icon(Icons.contact_phone),
                  title: Text(tipo.descripcion, style: TextStyle(color: AppColors.getTextColor(isDark))),
                  subtitle: Text(contacto.descripcion, style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.getSecondaryTextColor(isDark))),
        Text(value, style: TextStyle(fontSize: 16, color: AppColors.getTextColor(isDark))),
      ],
    );
  }

  Widget _buildEditView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección Información Básica
            Card(
              elevation: 4,
              color: AppColors.getCardColor(isDark),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Información Básica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: AppColors.getTextColor(isDark)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _beneficiarioController,
                      decoration: InputDecoration(
                        labelText: 'Beneficiario',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: AppColors.getTextColor(isDark)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sección Detalles
            Card(
              elevation: 4,
              color: AppColors.getCardColor(isDark),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detalles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedTipoEmpresa,
                            items: _tiposEmpresas.map((tipo) => DropdownMenuItem(
                              value: tipo['tipo_empresa_codigo'] as int,
                              child: Text(tipo['tipo_empresa_nombre'] as String),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedTipoEmpresa = value),
                            decoration: InputDecoration(
                              labelText: 'Tipo Empresa',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(color: AppColors.getTextColor(isDark)),
                            ),
                            validator: (value) => value == null ? 'Seleccione' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedTipoDocumento,
                            items: _tiposDocumentos.map((tipo) => DropdownMenuItem(
                              value: tipo['tipo_documento_codigo'] as int,
                              child: Text(tipo['tipo_documento_nombre'] as String),
                            )).toList(),
                            onChanged: (value) => setState(() => _selectedTipoDocumento = value),
                            decoration: InputDecoration(
                              labelText: 'Tipo Documento',
                              border: const OutlineInputBorder(),
                              labelStyle: TextStyle(color: AppColors.getTextColor(isDark)),
                            ),
                            validator: (value) => value == null ? 'Seleccione' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _documentoController,
                      decoration: InputDecoration(
                        labelText: 'Documento',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: AppColors.getTextColor(isDark)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _direccionController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
                        border: const OutlineInputBorder(),
                        labelStyle: TextStyle(color: AppColors.getTextColor(isDark)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sección Contactos
            Card(
              elevation: 4,
              color: AppColors.getCardColor(isDark),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contactos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _contactos.length,
                      itemBuilder: (context, index) {
                        final contacto = _contactos[index];
                        final tipo = _tiposContactos.firstWhere((t) => t.id == contacto.tipoContactoCodigo);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: AppColors.getSurfaceColor(isDark),
                          child: ExpansionTile(
                            leading: const Icon(Icons.contact_phone),
                            title: Text(tipo.descripcion, style: TextStyle(color: AppColors.getTextColor(isDark))),
                            subtitle: Text(contacto.descripcion, style: TextStyle(color: AppColors.getSecondaryTextColor(isDark))),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _showEditContactoDialog(contacto),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Editar'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => _confirmDeleteContacto(contacto),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showAddContactoDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Contacto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.getAccentColor(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndExitEdit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.controller.actualizarOperador(
        nombre: _nombreController.text,
        beneficiario: _beneficiarioController.text,
        tipoEmpresa: _selectedTipoEmpresa,
        tipoDocumento: _selectedTipoDocumento,
        documento: _documentoController.text.isEmpty ? null : _documentoController.text,
        direccion: _direccionController.text.isEmpty ? null : _direccionController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operador actualizado exitosamente')),
        );
      }
      await _loadData();
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando operador: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _beneficiarioController.dispose();
    _documentoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }
}