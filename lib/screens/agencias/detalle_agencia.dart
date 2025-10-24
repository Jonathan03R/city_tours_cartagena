import 'package:citytourscartagena/core/controller/agencias/agencias_controller.dart';
import 'package:citytourscartagena/core/controller/operadores/operadores_controller.dart';
import 'package:citytourscartagena/core/models/agencia/contacto_agencia.dart';
import 'package:citytourscartagena/core/models/agencia/perfil_agencia.dart';
import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:citytourscartagena/core/models/tipos/tipo_contacto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DetalleAgenciaScreen extends StatefulWidget {
  final int agenciaId;

  const DetalleAgenciaScreen({super.key, required this.agenciaId});

  @override
  State<DetalleAgenciaScreen> createState() => _DetalleAgenciaScreenState();
}

class _DetalleAgenciaScreenState extends State<DetalleAgenciaScreen> {
  Future<void> _mostrarDialogoEditarDatos(Agenciaperfil agencia) async {
    final controller = context.read<AgenciasControllerSupabase>();
    final tiposDocumentos = await controller.obtenerTiposDocumentosActivos();

    final nombreController = TextEditingController(text: agencia.nombre);
    final direccionController = TextEditingController(text: agencia.direccion ?? '');
    final representanteController = TextEditingController(text: agencia.representante ?? '');
    final documentoController = TextEditingController(text: agencia.documento ?? '');
    int? tipoDocumentoSeleccionado = agencia.tipoDocumento;
  // int tipoEmpresaSeleccionado = agencia.tipoEmpresa;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Información General'),
        content: SingleChildScrollView(
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre de la Empresa'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: representanteController,
                  decoration: const InputDecoration(labelText: 'Representante'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: documentoController,
                  decoration: const InputDecoration(labelText: 'Documento'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: tipoDocumentoSeleccionado,
                  decoration: const InputDecoration(labelText: 'Tipo de Documento'),
                  items: tiposDocumentos.map((tipo) => DropdownMenuItem(
                    value: tipo.codigo,
                    child: Text(tipo.nombre),
                  )).toList(),
                  onChanged: (value) => tipoDocumentoSeleccionado = value,
                ),
                // Campo de tipo de empresa oculto, no editable
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await controller.actualizarDatosAgencia(
                agenciaId: agencia.codigo,
                nombre: nombreController.text.trim(),
                direccion: direccionController.text.trim(),
                tipoDocumentoCodigo: tipoDocumentoSeleccionado,
                representante: representanteController.text.trim(),
                // tipoEmpresaCodigo: tipoEmpresaSeleccionado, // No se actualiza
                documento: documentoController.text.trim(),
              );
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Datos actualizados correctamente')),
                );
                setState(() {
                  _agenciaFuture = controller.obtenerAgenciaPorId(widget.agenciaId);
                });
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  late Future<Agenciaperfil?> _agenciaFuture;
  late Future<List<ContactoAgencia>> _contactosFuture;
  late Future<List<Map<String, dynamic>>> _preciosFuture;

  @override
  void initState() {
    super.initState();
    final controller = context.read<AgenciasControllerSupabase>();
    _agenciaFuture = controller.obtenerAgenciaPorId(widget.agenciaId);
    _contactosFuture = controller.obtenerContactosAgencia(widget.agenciaId);
    
    // Obtener precios personalizados
    final operadoresController = context.read<OperadoresController>();
    _preciosFuture = _obtenerPreciosPersonalizados(operadoresController, controller);
  }

  Future<List<Map<String, dynamic>>> _obtenerPreciosPersonalizados(
    OperadoresController operadoresController,
    AgenciasControllerSupabase agenciasController,
  ) async {
    try {
      final operador = await operadoresController.obtenerOperador();
      if (operador == null) {
        return [];
      }
      return await agenciasController.obtenerPreciosServiciosAgencia(
        operadorCodigo: operador.id,
        agenciaCodigo: widget.agenciaId,
      );
    } catch (e) {
      debugPrint('Error obteniendo precios: $e');
      return [];
    }
  }

  void _refreshContactos() {
    setState(() {
      final controller = context.read<AgenciasControllerSupabase>();
      _contactosFuture = controller.obtenerContactosAgencia(widget.agenciaId);
    });
  }

  void _refreshPrecios() {
    setState(() {
      final operadoresController = context.read<OperadoresController>();
      _preciosFuture = _obtenerPreciosPersonalizados(operadoresController, context.read<AgenciasControllerSupabase>());
    });
  }

  Future<void> _mostrarDialogoContacto({ContactoAgencia? contacto}) async {
    final controller = context.read<AgenciasControllerSupabase>();
    final tiposContactos = await controller.obtenerTiposContactosActivos();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => ContactoDialog(
        agenciaId: widget.agenciaId,
        contacto: contacto,
        tiposContactos: tiposContactos,
        controller: controller,
        onSave: _refreshContactos,
      ),
    );
  }

  Future<void> _mostrarDialogoPrecio() async {
    final controller = context.read<AgenciasControllerSupabase>();
    final operadoresController = context.read<OperadoresController>();
    
    final operador = await operadoresController.obtenerOperador();
    if (operador == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se encontró el operador')),
      );
      return;
    }

    final tiposServicios = await controller.obtenerTiposServiciosDisponiblesParaAgencia(
      operadorCodigo: operador.id,
      agenciaCodigo: widget.agenciaId,
    );

    if (tiposServicios.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay servicios disponibles para crear precios personalizados. Todos los servicios ya tienen precio asignado.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => PrecioDialog(
        agenciaId: widget.agenciaId,
        tiposServicios: tiposServicios,
        controller: controller,
        operadoresController: operadoresController,
        onSave: _refreshPrecios,
      ),
    );
  }

  Future<void> _mostrarDialogoEditarPrecio(Map<String, dynamic> precio) async {
    final controller = context.read<AgenciasControllerSupabase>();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => EditarPrecioDialog(
        precio: precio,
        controller: controller,
        onSave: _refreshPrecios,
      ),
    );
  }

  Future<void> _eliminarPrecio(Map<String, dynamic> precio) async {
    final controller = context.read<AgenciasControllerSupabase>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Precio'),
        content: Text('¿Estás seguro de que quieres eliminar el precio de "${precio['descripcion'] ?? 'este servicio'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await controller.eliminarPrecioAgencia(
          precioCodigo: precio['codigo'] as int,
        );
        _refreshPrecios();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Precio eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error eliminando precio: $e')),
          );
        }
      }
    }
  }

  Future<void> _eliminarContacto(ContactoAgencia contacto) async {
    final controller = context.read<AgenciasControllerSupabase>();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Contacto'),
        content: Text('¿Estás seguro de que quieres eliminar "${contacto.descripcion}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await controller.eliminarContacto(contacto.codigo);
        _refreshContactos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacto eliminado correctamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error eliminando contacto: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Agencia'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Agenciaperfil?>(
        future: _agenciaFuture,
        builder: (context, agenciaSnapshot) {
          if (agenciaSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (agenciaSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${agenciaSnapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          }
          final agencia = agenciaSnapshot.data;
          if (agencia == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Agencia no encontrada', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con logo y nombre
                if (agencia.logoUrl != null)
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          agencia.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.business, size: 60, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    agencia.nombre,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Información General
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Información General',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Editar información',
                              onPressed: () => _mostrarDialogoEditarDatos(agencia),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.business, 'Código', agencia.codigo.toString()),
                        _buildInfoRow(Icons.location_on, 'Dirección', agencia.direccion ?? 'No especificada'),
                        _buildInfoRow(Icons.person, 'Representante', agencia.representante ?? 'No especificado'),
                        _buildInfoRow(Icons.badge, 'Documento', agencia.documento ?? 'No especificado'),
                        if (agencia.documento != null)
                          _buildInfoRow(Icons.description, 'Tipo Documento', agencia.tipoDocumentoNombre!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Contactos
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.contacts, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text(
                              'Contactos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        FutureBuilder<List<ContactoAgencia>>(
                          future: _contactosFuture,
                          builder: (context, contactosSnapshot) {
                            if (contactosSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (contactosSnapshot.hasError) {
                              return Column(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red),
                                  const SizedBox(height: 8),
                                  Text('Error cargando contactos: ${contactosSnapshot.error}'),
                                ],
                              );
                            }
                            final contactos = contactosSnapshot.data ?? [];
                            if (contactos.isEmpty) {
                              return Column(
                                children: [
                                  const Icon(Icons.contact_phone_outlined, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'No hay contactos registrados',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: contactos.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final contacto = contactos[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.shade100,
                                    child: const Icon(Icons.contact_phone, color: Colors.green),
                                  ),
                                  title: Text(
                                    contacto.descripcion,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(contacto.tipoContacto.descripcion),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _mostrarDialogoContacto(contacto: contacto),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _eliminarContacto(contacto),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Precios de Servicios Personalizados
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.orange),
                            const SizedBox(width: 8),
                            const Text(
                              'Precios de Servicios Personalizados',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _preciosFuture,
                          builder: (context, preciosSnapshot) {
                            if (preciosSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (preciosSnapshot.hasError) {
                              return Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text('Error cargando precios: ${preciosSnapshot.error}'),
                                  ],
                                ),
                              );
                            }
                            final precios = preciosSnapshot.data ?? [];
                            if (precios.isEmpty) {
                              return const Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.money_off, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('No hay precios personalizados', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: precios.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final precio = precios[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: const Icon(Icons.local_offer, color: Colors.orange),
                                  ),
                                  title: Text(
                                    precio['descripcion'] ?? 'Servicio desconocido',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    'Precio: \$${precio['precio']?.toString() ?? 'N/A'}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _mostrarDialogoEditarPrecio(precio),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _eliminarPrecio(precio),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => _mostrarDialogoPrecio(),
            backgroundColor: Colors.orange,
            tooltip: 'Agregar Precio',
            child: const Icon(Icons.attach_money),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () => _mostrarDialogoContacto(),
            backgroundColor: Colors.green,
            tooltip: 'Agregar Contacto',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditarPrecioDialog extends StatefulWidget {
  final Map<String, dynamic> precio;
  final AgenciasControllerSupabase controller;
  final VoidCallback onSave;

  const EditarPrecioDialog({
    super.key,
    required this.precio,
    required this.controller,
    required this.onSave,
  });

  @override
  State<EditarPrecioDialog> createState() => _EditarPrecioDialogState();
}

class _EditarPrecioDialogState extends State<EditarPrecioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _precioController.text = (widget.precio['precio'] as num?)?.toString() ?? '';
  }

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await widget.controller.actualizarPrecioAgencia(
        precioCodigo: widget.precio['codigo'] as int,
        precio: double.parse(_precioController.text.trim()),
      );

      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precio actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando precio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Precio'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Servicio: ${widget.precio['descripcion'] ?? 'Desconocido'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                hintText: 'Ej: 15000.00',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un precio';
                }
                final precio = double.tryParse(value.trim());
                if (precio == null || precio <= 0) {
                  return 'Ingresa un precio válido mayor a 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : _guardar,
          child: _cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Actualizar'),
        ),
      ],
    );
  }
}

class PrecioDialog extends StatefulWidget {
  final int agenciaId;
  final List<TipoServicio> tiposServicios;
  final AgenciasControllerSupabase controller;
  final OperadoresController operadoresController;
  final VoidCallback onSave;

  const PrecioDialog({
    super.key,
    required this.agenciaId,
    required this.tiposServicios,
    required this.controller,
    required this.operadoresController,
    required this.onSave,
  });

  @override
  State<PrecioDialog> createState() => _PrecioDialogState();
}

class _PrecioDialogState extends State<PrecioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  int? _tipoServicioSeleccionado;
  bool _cargando = false;

  @override
  void dispose() {
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final operador = await widget.operadoresController.obtenerOperador();
      if (operador == null) {
        throw Exception('No se encontró el operador');
      }

      await widget.controller.crearPrecioAgencia(
        operadorCodigo: operador.id,
        agenciaCodigo: widget.agenciaId,
        tipoServicioCodigo: _tipoServicioSeleccionado!,
        precio: double.parse(_precioController.text.trim()),
      );

      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precio creado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Precio Personalizado'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Servicio',
                border: OutlineInputBorder(),
              ),
              items: widget.tiposServicios.map((tipo) {
                return DropdownMenuItem(
                  value: tipo.codigo,
                  child: Text(tipo.descripcion),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'Selecciona un tipo de servicio';
                }
                return null;
              },
              onChanged: (value) {
                setState(() => _tipoServicioSeleccionado = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio',
                hintText: 'Ej: 15000.00',
                border: OutlineInputBorder(),
                prefixText: '\$',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un precio';
                }
                final precio = double.tryParse(value.trim());
                if (precio == null || precio <= 0) {
                  return 'Ingresa un precio válido mayor a 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : _guardar,
          child: _cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class ContactoDialog extends StatefulWidget {
  final int agenciaId;
  final ContactoAgencia? contacto;
  final List<TipoContacto> tiposContactos;
  final AgenciasControllerSupabase controller;
  final VoidCallback onSave;

  const ContactoDialog({
    super.key,
    required this.agenciaId,
    this.contacto,
    required this.tiposContactos,
    required this.controller,
    required this.onSave,
  });

  @override
  State<ContactoDialog> createState() => _ContactoDialogState();
}

class _ContactoDialogState extends State<ContactoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  int? _tipoContactoSeleccionado;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    if (widget.contacto != null) {
      _descripcionController.text = widget.contacto!.descripcion;
      _tipoContactoSeleccionado = widget.contacto!.tipoContactoCodigo;
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      if (widget.contacto == null) {
        await widget.controller.crearContacto(
          agenciaCodigo: widget.agenciaId,
          tipoContactoCodigo: _tipoContactoSeleccionado!,
          descripcion: _descripcionController.text.trim(),
        );
      } else {
        await widget.controller.actualizarContacto(
          agenciaId: widget.agenciaId,
          contactoCodigo: widget.contacto!.codigo,
          tipoContactoCodigo: _tipoContactoSeleccionado!,
          descripcion: _descripcionController.text.trim(),
        );
      }

      widget.onSave();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.contacto == null
                ? 'Contacto creado correctamente'
                : 'Contacto actualizado correctamente'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contacto == null ? 'Nuevo Contacto' : 'Editar Contacto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _tipoContactoSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Tipo de Contacto',
                border: OutlineInputBorder(),
              ),
              items: widget.tiposContactos.map((tipo) {
                return DropdownMenuItem(
                  value: tipo.id,
                  child: Text(tipo.descripcion),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'Selecciona un tipo de contacto';
                }
                return null;
              },
              onChanged: (value) {
                setState(() => _tipoContactoSeleccionado = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                hintText: 'Ej: +57 300 123 4567',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa una descripción';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cargando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _cargando ? null : _guardar,
          child: _cargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}