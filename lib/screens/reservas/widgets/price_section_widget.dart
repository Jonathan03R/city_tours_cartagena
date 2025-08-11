import 'package:citytourscartagena/core/controller/auth_controller.dart';
import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/configuracion.dart';
import 'package:citytourscartagena/core/models/enum/tipo_turno.dart';
import 'package:citytourscartagena/core/models/permisos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';


class PriceSectionWidget extends StatelessWidget {
  final AgenciaConReservas? currentAgencia;
  final Configuracion? configuracion;
  final TurnoType? turnoFilter;
  final bool editandoPrecio;
  final String? editingTurno;
  final TextEditingController precioController;
  final TextEditingController precioMananaController;
  final TextEditingController precioTardeController;
  final VoidCallback onStartEditing;
  final Future<void> Function() onSavePrice;
  final Future<void> Function(String) onSaveGlobalPrice;
  final VoidCallback onCancelEditing;

  const PriceSectionWidget({
    super.key,
    this.currentAgencia,
    this.configuracion,
    this.turnoFilter,
    required this.editandoPrecio,
    this.editingTurno,
    required this.precioController,
    required this.precioMananaController,
    required this.precioTardeController,
    required this.onStartEditing,
    required this.onSavePrice,
    required this.onSaveGlobalPrice,
    required this.onCancelEditing,
  });

  @override
  Widget build(BuildContext context) {
    final authController = context.read<AuthController>();
    final ag = currentAgencia?.agencia;
    
    final showManana = ag != null && (turnoFilter == null || turnoFilter == TurnoType.manana);
    final showTarde = ag != null && (turnoFilter == null || turnoFilter == TurnoType.tarde);
    
    final double? globalPriceManana = configuracion?.precioGeneralAsientoTemprano;
    final double? globalPriceTarde = configuracion?.precioGeneralAsientoTarde;

    if (ag != null) {
      return _buildAgencyPriceSection(
        ag, 
        showManana, 
        showTarde, 
        globalPriceManana, 
        globalPriceTarde, 
        authController
      );
    } else {
      return _buildGlobalPriceSection(
        globalPriceManana, 
        globalPriceTarde, 
        authController
      );
    }
  }

  Widget _buildAgencyPriceSection(
    Agencia ag,
    bool showManana,
    bool showTarde,
    double? globalPriceManana,
    double? globalPriceTarde,
    AuthController authController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showManana)
          _buildPriceRow(
            'Mañana',
            ag.precioPorAsientoTurnoManana ?? globalPriceManana ?? 0.0,
            ag.precioPorAsientoTurnoManana == null,
            Icons.wb_sunny,
            Colors.orange,
          ),
        if (showTarde)
          _buildPriceRow(
            'Tarde',
            ag.precioPorAsientoTurnoTarde ?? globalPriceTarde ?? 0.0,
            ag.precioPorAsientoTurnoTarde == null,
            Icons.wb_twilight,
            Colors.blue,
          ),
        if (editandoPrecio) ...[
          const SizedBox(height: 12),
          if (showManana) ...[
            _buildPriceTextField(
              precioMananaController,
              'Precio mañana',
              'Vacío = usar global (${globalPriceManana?.toStringAsFixed(2) ?? '0.00'})',
              Icons.wb_sunny,
              Colors.orange.shade600,
            ),
            const SizedBox(height: 8),
          ],
          if (showTarde) ...[
            _buildPriceTextField(
              precioTardeController,
              'Precio tarde',
              'Vacío = usar global (${globalPriceTarde?.toStringAsFixed(2) ?? '0.00'})',
              Icons.wb_twilight,
              Colors.blue.shade600,
            ),
          ],
        ],
        if (authController.hasPermission(Permission.edit_agencias))
          _buildEditButtons(),
      ],
    );
  }

  Widget _buildGlobalPriceSection(
    double? globalPriceManana,
    double? globalPriceTarde,
    AuthController authController,
  ) {
    final showManana = turnoFilter == null || turnoFilter == TurnoType.manana;
    final showTarde = turnoFilter == null || turnoFilter == TurnoType.tarde;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Precios Globales:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (showManana)
          _buildGlobalPriceRow(
            'Mañana',
            globalPriceManana,
            Icons.wb_sunny,
            Colors.orange.shade600,
            authController,
          ),
        if (showManana && showTarde) const SizedBox(height: 8),
        if (showTarde)
          _buildGlobalPriceRow(
            'Tarde',
            globalPriceTarde,
            Icons.wb_twilight,
            Colors.blue.shade600,
            authController,
          ),
      ],
    );
  }

  Widget _buildPriceRow(
    String turno,
    double precio,
    bool esHeredado,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '$turno: \$${precio.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: esHeredado ? Colors.grey.shade600 : Colors.black87,
              ),
            ),
          ),
          if (esHeredado)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Global',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlobalPriceRow(
    String turno,
    double? precio,
    IconData icon,
    Color color,
    AuthController authController,
  ) {
    final turnoKey = turno.toLowerCase();
    final isEditing = editandoPrecio && editingTurno == turnoKey;

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: precioController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => onSaveGlobalPrice(turnoKey),
                )
              : Text(
                  '$turno: \$${precio?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
        ),
        if (authController.hasPermission(Permission.edit_configuracion))
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: Colors.grey.shade800,
              size: 18,
            ),
            onPressed: () {
              if (isEditing) {
                onSaveGlobalPrice(turnoKey);
              } else {
                // Start editing for this specific turno
                // This would need to be handled by the parent widget
              }
            },
          ),
      ],
    );
  }

  Widget _buildPriceTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    Color iconColor,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: iconColor),
      ),
    );
  }

  Widget _buildEditButtons() {
    return Align(
      alignment: Alignment.centerRight,
      child: editandoPrecio
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  tooltip: 'Cancelar',
                  onPressed: onCancelEditing,
                ),
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green.shade600),
                  tooltip: 'Guardar',
                  onPressed: onSavePrice,
                ),
              ],
            )
          : IconButton(
              icon: Icon(Icons.edit, color: Colors.grey.shade800),
              tooltip: 'Editar precios',
              onPressed: onStartEditing,
            ),
    );
  }
}
