import 'package:citytourscartagena/core/controller/filtros/servicios_controller.dart';
import 'package:citytourscartagena/core/models/servicios/servicio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TipoServicioSelector extends StatefulWidget {
  final int? selectedTipoServicioId;
  final Function(TipoServicio?) onSelected;
  final bool enabled;

  const TipoServicioSelector({
    super.key,
    this.selectedTipoServicioId,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  State<TipoServicioSelector> createState() => _TipoServicioSelectorState();
}

class _TipoServicioSelectorState extends State<TipoServicioSelector> {
  TipoServicio? _selectedTipoServicio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiciosController>().cargarTiposServiciosv2();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
    final existe = Provider.of<ServiciosController?>(context, listen: false);
    debugPrint('🔍 Provider ServiciosController encontrado: ${existe != null}');
    if (existe != null) {
      existe.cargarTiposServiciosv2();
    } else {
      debugPrint('⚠️ No se encontró el provider de ServiciosController');
    }
  });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiciosController>();
    final servicios = controller.tiposServicios;
    final isLoading = controller.isLoading;

    TipoServicio? initialValue = _selectedTipoServicio;
    if (initialValue == null && widget.selectedTipoServicioId != null) {
      final found = servicios.where((s) => s.codigo == widget.selectedTipoServicioId);
      if (found.isNotEmpty) {
        initialValue = found.first;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Servicio *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<TipoServicio>(
                initialValue: initialValue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                hint: const Text(
                  'Seleccione servicio',
                  style: TextStyle(color: Colors.grey),
                ),
                items: [
                  // Placeholder fijo
                  const DropdownMenuItem<TipoServicio>(
                    enabled: false,
                    value: null,
                    child: Text(
                      'Seleccione servicio',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  // Lista de servicios reales
                  ...servicios.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.descripcion),
                    ),
                  ),
                ],
                onChanged: widget.enabled
                    ? (value) {
                        setState(() => _selectedTipoServicio = value);
                        widget.onSelected(value);
                      }
                    : null,
                validator: (value) =>
                    value == null ? 'Debe seleccionar un servicio' : null,
              ),
      ],
    );
  }
}
