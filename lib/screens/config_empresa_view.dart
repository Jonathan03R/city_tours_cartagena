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
              // Editable Precio Asiento Mañana
              _isEditingPrecioManana
                  ? ListTile(
                      title: const Text('Precio Asiento Mañana'),
                      subtitle: TextField(
                        controller: _precioMananaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'Ingrese nuevo precio',
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              final newVal = double.tryParse(_precioMananaController.text);
                              if (newVal != null) {
                                configCtrl.actualizarPrecioManana(newVal);
                                setState(() => _isEditingPrecioManana = false);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _isEditingPrecioManana = false);
                            },
                          ),
                        ],
                      ),
                    )
                  : ListTile(
                      title: const Text('Precio Asiento Mañana'),
                      subtitle: Text(
                        cfg != null
                            ? cfg.precioGeneralAsientoTemprano.toStringAsFixed(2)
                            : 'No configurado',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          if (cfg != null) {
                            _precioMananaController.text = cfg.precioGeneralAsientoTemprano.toStringAsFixed(2);
                            setState(() => _isEditingPrecioManana = true);
                          }
                        },
                      ),
                    ),
              // Editable Precio Asiento Tarde
              _isEditingPrecioTarde
                  ? ListTile(
                      title: const Text('Precio Asiento Tarde'),
                      subtitle: TextField(
                        controller: _precioTardeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: 'Ingrese nuevo precio'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              final newVal = double.tryParse(_precioTardeController.text);
                              if (newVal != null) {
                                configCtrl.actualizarPrecioTarde(newVal);
                                setState(() => _isEditingPrecioTarde = false);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _isEditingPrecioTarde = false),
                          ),
                        ],
                      ),
                    )
                  : ListTile(
                      title: const Text('Precio Asiento Tarde'),
                      subtitle: Text(
                        cfg != null
                            ? cfg.precioGeneralAsientoTarde.toStringAsFixed(2)
                            : 'No configurado',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          if (cfg != null) {
                            _precioTardeController.text = cfg.precioGeneralAsientoTarde.toStringAsFixed(2);
                            setState(() => _isEditingPrecioTarde = true);
                          }
                        },
                      ),
                    ),
              // Última actualización (solo lectura)
              // ListTile(
              //   title: const Text('Última actualización'),
              //   subtitle: Text(
              //     cfg != null
              //         ? cfg.actualizadoEn.toIso8601String()
              //         : 'No configurado',
              //   ),
              // ),
              const Divider(),
              // Editable Tipo de Documento
              _isEditingTipoDocumento
                  ? ListTile(
                      title: const Text('Tipo de Documento'),
                      subtitle: DropdownButton<TipoDocumento>(
                        value: _selectedTipoDocumento,
                        items: TipoDocumento.values.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name.toUpperCase()),
                            )).toList(),
                        onChanged: (v) => setState(() => _selectedTipoDocumento = v),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              if (_selectedTipoDocumento != null) {
                                configCtrl.actualizarTipoDocumento(_selectedTipoDocumento!);
                                setState(() => _isEditingTipoDocumento = false);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _isEditingTipoDocumento = false),
                          ),
                        ],
                      ),
                    )
                  : ListTile(
                      title: const Text('Tipo de Documento'),
                      subtitle: Text(
                        cfg != null
                            ? cfg.tipoDocumento.name.toUpperCase()
                            : 'No configurado',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          if (cfg != null) {
                            _selectedTipoDocumento = cfg.tipoDocumento;
                            setState(() => _isEditingTipoDocumento = true);
                          }
                        },
                      ),
                    ),
              // Editable Número de Documento
              _isEditingNumeroDocumento
                  ? ListTile(
                      title: const Text('Número de Documento'),
                      subtitle: TextField(
                        controller: _numeroDocumentoController,
                        decoration: const InputDecoration(hintText: 'Ingrese número'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              final num = _numeroDocumentoController.text.trim();
                              if (num.isNotEmpty) {
                                configCtrl.actualizarNumeroDocumento(num);
                                setState(() => _isEditingNumeroDocumento = false);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _isEditingNumeroDocumento = false),
                          ),
                        ],
                      ),
                    )
                  : ListTile(
                      title: const Text('Número de Documento'),
                      subtitle: Text(
                        cfg != null && cfg.numeroDocumento != null
                            ? cfg.numeroDocumento!
                            : 'No configurado',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          if (cfg != null && cfg.numeroDocumento != null) {
                            _numeroDocumentoController.text = cfg.numeroDocumento!;
                          }
                          setState(() => _isEditingNumeroDocumento = true);
                        },
                      ),
                    ),
              // Editable Nombre Beneficiario
              _isEditingNombreBeneficiario
                  ? ListTile(
                      title: const Text('Nombre Beneficiario'),
                      subtitle: TextField(
                        controller: _nombreBeneficiarioController,
                        decoration: const InputDecoration(hintText: 'Ingrese nombre'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check),
                            onPressed: () {
                              final name = _nombreBeneficiarioController.text.trim();
                              if (name.isNotEmpty) {
                                configCtrl.actualizarNombreBeneficiario(name);
                                setState(() => _isEditingNombreBeneficiario = false);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _isEditingNombreBeneficiario = false),
                          ),
                        ],
                      ),
                    )
                  : ListTile(
                      title: const Text('Nombre Beneficiario'),
                      subtitle: Text(
                        cfg != null && cfg.nombreBeneficiario != null
                            ? cfg.nombreBeneficiario!
                            : 'No configurado',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          if (cfg != null && cfg.nombreBeneficiario != null) {
                            _nombreBeneficiarioController.text = cfg.nombreBeneficiario!;
                          }
                          setState(() => _isEditingNombreBeneficiario = true);
                        },
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }
}
