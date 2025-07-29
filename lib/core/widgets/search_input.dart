import 'dart:async';

import 'package:flutter/material.dart';

typedef OnSearchChanged = void Function(String);

class SearchInput extends StatefulWidget {
  final String hintText;
  final OnSearchChanged onChanged;
  final EdgeInsetsGeometry padding;
  final bool enabled;

  const SearchInput({
    super.key,
    this.hintText = 'Buscar...',
    required this.onChanged,
    this.padding = const EdgeInsets.all(8.0),
    this.enabled = true,
  });

  @override
  // ignore: library_private_types_in_public_api
  _SearchInputState createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounceTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    
    // Listener optimizado con debounce para evitar llamadas excesivas
    _controller.addListener(_onTextChanged);
    
    // Listener para manejar cambios de focus
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    if (_isDisposed) return;
    
    // Cancelar timer anterior si existe
    _debounceTimer?.cancel();
    
    // Crear nuevo timer con debounce de 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!_isDisposed && mounted) {
        widget.onChanged(_controller.text);
        if (mounted) {
          setState(() {}); // Actualizar suffixIcon
        }
      }
    });
  }

  void _onFocusChanged() {
    if (_isDisposed || !mounted) return;
    
    // Si pierde el focus, asegurar que se mantenga así
    if (!_focusNode.hasFocus) {
      setState(() {});
    }
  }

  void _clearSearch() {
    if (_isDisposed) return;
    
    _debounceTimer?.cancel();
    _controller.clear();
    _focusNode.unfocus(); // Desenfocar inmediatamente
    widget.onChanged('');
    
    if (mounted) {
      setState(() {});
    }
  }

  void _unfocusField() {
    if (_isDisposed) return;
    
    _focusNode.unfocus();
    // Asegurar que el focus se pierda completamente
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: GestureDetector(
        // Prevenir que el tap fuera del campo lo active
        behavior: HitTestBehavior.opaque,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          autofocus: false,
          
          // Configuración mejorada para el manejo de focus
          onTap: () {
            // Solo permitir focus si está habilitado
            if (!widget.enabled) {
              _unfocusField();
            }
          },
          
          onEditingComplete: _unfocusField,
          onSubmitted: (_) => _unfocusField,
          
          // Prevenir que se active automáticamente en ciertas situaciones
          onTapOutside: (event) => _unfocusField(),
          
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                    // Prevenir que el botón clear cause problemas de focus
                    splashRadius: 20,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            // Mejorar la apariencia cuando está deshabilitado
            filled: !widget.enabled,
            fillColor: !widget.enabled ? Colors.grey.shade100 : null,
          ),
          
          // Manejar cambios de texto con debounce ya implementado
          onChanged: (value) {
            // El debounce se maneja en _onTextChanged
            // Aquí solo actualizamos el estado inmediatamente para el suffixIcon
            if (mounted) {
              setState(() {});
            }
          },
        ),
      ),
    );
  }
}
