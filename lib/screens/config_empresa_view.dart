import 'package:citytourscartagena/core/controller/configuracion_controller.dart'; // <-- importar controlador
import 'package:citytourscartagena/core/models/enum/tipo_documento.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ...existing imports...

class ConfigEmpresaView extends StatefulWidget {
  const ConfigEmpresaView({super.key});

  @override
  State<ConfigEmpresaView> createState() => _ConfigEmpresaViewState();
}

class _ConfigEmpresaViewState extends State<ConfigEmpresaView> {
  bool _isEditingWhatsapp = false;
  final TextEditingController _whatsappController = TextEditingController();
  bool _isEditingNombreEmpresa = false;
  final TextEditingController _nombreEmpresaController = TextEditingController();
  bool _isEditingMaxCuposManana = false;
  final TextEditingController _maxCuposMananaController = TextEditingController();
  bool _isEditingMaxCuposTarde = false;
  final TextEditingController _maxCuposTardeController = TextEditingController();
  bool _isEditingPrecioManana = false;
  final TextEditingController _precioMananaController = TextEditingController();
  bool _isEditingPrecioTarde = false;
  final TextEditingController _precioTardeController = TextEditingController();
  bool _isEditingTipoDocumento = false;
  TipoDocumento? _selectedTipoDocumento;
  bool _isEditingNumeroDocumento = false;
  final TextEditingController _numeroDocumentoController = TextEditingController();
  bool _isEditingNombreBeneficiario = false;
  final TextEditingController _nombreBeneficiarioController = TextEditingController();

  @override
  void dispose() {
    _precioMananaController.dispose();
    _precioTardeController.dispose();
    _numeroDocumentoController.dispose();
    _nombreBeneficiarioController.dispose();
    _nombreEmpresaController.dispose();
    _maxCuposMananaController.dispose();
    _maxCuposTardeController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Empresa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<ConfiguracionController>(
        builder: (_, configCtrl, __) {
          final cfg = configCtrl.configuracion;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Datos Generales',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildEditableField(
                        label: 'Nombre Empresa',
                        value: cfg?.nombreEmpresa ?? 'No configurado',
                        isEditing: _isEditingNombreEmpresa,
                        controller: _nombreEmpresaController,
                        onEdit: () {
                          if (cfg != null) {
                            _nombreEmpresaController.text = cfg.nombreEmpresa;
                            setState(() => _isEditingNombreEmpresa = true);
                          }
                        },
                        onSave: () async {
                          final name = _nombreEmpresaController.text.trim();
                          if (name.isNotEmpty) {
                            await configCtrl.actualizarNombreEmpresa(name);
                            setState(() => _isEditingNombreEmpresa = false);
                          }
                        },
                        onCancel: () => setState(() => _isEditingNombreEmpresa = false),
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: 'WhatsApp de contacto',
                        value: cfg?.contact_whatsapp ?? 'No configurado',
                        isEditing: _isEditingWhatsapp,
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        onEdit: () {
                          if (cfg != null && cfg.contact_whatsapp != null) {
                            _whatsappController.text = cfg.contact_whatsapp!;
                          }
                          setState(() => _isEditingWhatsapp = true);
                        },
                        onSave: () async {
                          final phone = _whatsappController.text.trim();
                          // Permitir guardar vacío (lo borra)
                          await configCtrl.actualizarWhatsapp(phone.isEmpty ? null : phone);
                          setState(() => _isEditingWhatsapp = false);
                        },
                        onCancel: () => setState(() => _isEditingWhatsapp = false),
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: 'Max. Cupos Turno Mañana',
                        value: cfg != null ? cfg.maxCuposTurnoManana.toString() : 'No configurado',
                        isEditing: _isEditingMaxCuposManana,
                        controller: _maxCuposMananaController,
                        keyboardType: TextInputType.number,
                        onEdit: () {
                          if (cfg != null) {
                            _maxCuposMananaController.text = cfg.maxCuposTurnoManana.toString();
                            setState(() => _isEditingMaxCuposManana = true);
                          }
                        },
                        onSave: () async {
                          final val = int.tryParse(_maxCuposMananaController.text);
                          if (val != null && val > 0) {
                            await configCtrl.actualizarMaxCuposTurnoManana(val);
                            setState(() => _isEditingMaxCuposManana = false);
                          }
                        },
                        onCancel: () => setState(() => _isEditingMaxCuposManana = false),
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: 'Max. Cupos Turno Tarde',
                        value: cfg != null ? cfg.maxCuposTurnoTarde.toString() : 'No configurado',
                        isEditing: _isEditingMaxCuposTarde,
                        controller: _maxCuposTardeController,
                        keyboardType: TextInputType.number,
                        onEdit: () {
                          if (cfg != null) {
                            _maxCuposTardeController.text = cfg.maxCuposTurnoTarde.toString();
                            setState(() => _isEditingMaxCuposTarde = true);
                          }
                        },
                        onSave: () async {
                          final val = int.tryParse(_maxCuposTardeController.text);
                          if (val != null && val > 0) {
                            await configCtrl.actualizarMaxCuposTurnoTarde(val);
                            setState(() => _isEditingMaxCuposTarde = false);
                          }
                        },
                        onCancel: () => setState(() => _isEditingMaxCuposTarde = false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Precios y Beneficiario',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildEditableField(
                        label: 'Precio Asiento Mañana',
                        value: cfg != null ? cfg.precioGeneralAsientoTemprano.toStringAsFixed(2) : 'No configurado',
                        isEditing: _isEditingPrecioManana,
                        controller: _precioMananaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onEdit: () {
                          if (cfg != null) {
                            _precioMananaController.text = cfg.precioGeneralAsientoTemprano.toStringAsFixed(2);
                            setState(() => _isEditingPrecioManana = true);
                          }
                        },
                        onSave: () async {
                          final newVal = double.tryParse(_precioMananaController.text);
                          if (newVal != null) {
                            await configCtrl.actualizarPrecioManana(newVal);
                            setState(() => _isEditingPrecioManana = false);
                          }
                        },
                        onCancel: () => setState(() => _isEditingPrecioManana = false),
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: 'Precio Asiento Tarde',
                        value: cfg != null ? cfg.precioGeneralAsientoTarde.toStringAsFixed(2) : 'No configurado',
                        isEditing: _isEditingPrecioTarde,
                        controller: _precioTardeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onEdit: () {
                          if (cfg != null) {
                            _precioTardeController.text = cfg.precioGeneralAsientoTarde.toStringAsFixed(2);
                            setState(() => _isEditingPrecioTarde = true);
                          }
                        },
                        onSave: () async {
                          final newVal = double.tryParse(_precioTardeController.text);
                          if (newVal != null) {
                            await configCtrl.actualizarPrecioTarde(newVal);
                            setState(() => _isEditingPrecioTarde = false);
                          }
                        },
                        onCancel: () => setState(() => _isEditingPrecioTarde = false),
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: 'Nombre Beneficiario',
                        value: cfg != null && cfg.nombreBeneficiario != null ? cfg.nombreBeneficiario! : 'No configurado',
                        isEditing: _isEditingNombreBeneficiario,
                        controller: _nombreBeneficiarioController,
                        onEdit: () {
                          if (cfg != null && cfg.nombreBeneficiario != null) {
                            _nombreBeneficiarioController.text = cfg.nombreBeneficiario!;
                          }
                          setState(() => _isEditingNombreBeneficiario = true);
                        },
                        onSave: () async {
                          final name = _nombreBeneficiarioController.text.trim();
                          if (name.isNotEmpty) {
                            await configCtrl.actualizarNombreBeneficiario(name);
                            setState(() => _isEditingNombreBeneficiario = false);
                          }
                        },
                        onCancel: () => setState(() => _isEditingNombreBeneficiario = false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Datos de Documento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildEditableDropdownField(
                        label: 'Tipo de Documento',
                        value: cfg != null ? cfg.tipoDocumento.name.toUpperCase() : 'No configurado',
                        isEditing: _isEditingTipoDocumento,
                        currentValue: _selectedTipoDocumento,
                        onEdit: () {
                          if (cfg != null) {
                            _selectedTipoDocumento = cfg.tipoDocumento;
                            setState(() => _isEditingTipoDocumento = true);
                          }
                        },
                        onSave: () async {
                          if (_selectedTipoDocumento != null) {
                            await configCtrl.actualizarTipoDocumento(_selectedTipoDocumento!);
                            setState(() => _isEditingTipoDocumento = false);
                          }
                        },
                        onCancel: () => setState(() => _isEditingTipoDocumento = false),
                      ),
                      const Divider(),
                      _buildEditableField(
                        label: 'Número de Documento',
                        value: cfg != null && cfg.numeroDocumento != null ? cfg.numeroDocumento! : 'No configurado',
                        isEditing: _isEditingNumeroDocumento,
                        controller: _numeroDocumentoController,
                        onEdit: () {
                          if (cfg != null && cfg.numeroDocumento != null) {
                            _numeroDocumentoController.text = cfg.numeroDocumento!;
                          }
                          setState(() => _isEditingNumeroDocumento = true);
                        },
                        onSave: () async {
                          final num = _numeroDocumentoController.text.trim();
                          if (num.isNotEmpty) {
                            await configCtrl.actualizarNumeroDocumento(num);
                            setState(() => _isEditingNumeroDocumento = false);
                          }
                        },
                        onCancel: () => setState(() => _isEditingNumeroDocumento = false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (cfg != null)
                Text(
                  'Última actualización: ${cfg.actualizadoEn.toIso8601String()}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    TextInputType? keyboardType,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required Future<void> Function() onSave,
  }) {
    return isEditing
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(labelText: label),
                  autofocus: true,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: onSave,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onCancel,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(label),
                  subtitle: Text(value),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            ],
          );
  }

  Widget _buildEditableDropdownField({
    required String label,
    required String value,
    required bool isEditing,
    required TipoDocumento? currentValue,
    required VoidCallback onEdit,
    required VoidCallback onCancel,
    required Future<void> Function() onSave,
  }) {
    return isEditing
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: DropdownButtonFormField<TipoDocumento>(
                  value: currentValue,
                  items: TipoDocumento.values
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTipoDocumento = v),
                  decoration: InputDecoration(labelText: label),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: onSave,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onCancel,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(label),
                  subtitle: Text(value),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: onEdit,
              ),
            ],
          );
  }

}
