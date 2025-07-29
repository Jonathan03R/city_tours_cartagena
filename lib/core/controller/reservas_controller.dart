import 'dart:async';

import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/firestore_service.dart';
import 'package:citytourscartagena/core/utils/extensions.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart';
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ReservasController extends ChangeNotifier {
  final FirestoreService _firestoreService;
  StreamSubscription? _reservasSubscription;

  // --- Filtros ---
  TurnoType? _turnoFilter;
  DateFilterType _selectedFilter = DateFilterType.today;
  DateTime? _customDate;
  String? _agenciaIdFilter;

  // --- Paginación ---
  int _itemsPerPage = 10;
  int _currentPageIndex = 0;
  bool _isFetchingPage = false;
  bool _hasMorePages = true;
  List<ReservaConAgencia> _allLoadedReservas = [];
  bool _isLoading = false;

  // --- NUEVA FUNCIONALIDAD: Selección múltiple ---
  final Set<String> _selectedReservaIds = <String>{};
  bool _isSelectionMode = false;

  // --- Streams ---
  final BehaviorSubject<List<ReservaConAgencia>> _filteredReservasSubject =
      BehaviorSubject<List<ReservaConAgencia>>();
  Stream<List<ReservaConAgencia>> get filteredReservasStream =>
      _filteredReservasSubject.stream;
  StreamSubscription<List<Agencia>>? _agenciasSub;

  List<Agencia> _allAgencias = [];

  ReservasController({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService() {
    _initializeController();

    _agenciasSub = _firestoreService.getAgenciasStream().listen((all) {
      _allAgencias = all.where((a) => !a.eliminada).toList();
      _updateFilteredReservasStream(resetPagination: true);
    });
  }

  Future<void> _initializeController() async {
    _isLoading = true;
    notifyListeners();
    await _loadAllAgencias();
    _updateFilteredReservasStream(resetPagination: true);
  }

  // Getters existentes
  DateFilterType get selectedFilter => _selectedFilter;
  DateTime? get customDate => _customDate;
  List<ReservaConAgencia> get currentReservas => _allLoadedReservas;
  TurnoType? get turnoFilter => _turnoFilter;
  bool get isLoading => _isLoading;

  // Getters para la paginación
  int get itemsPerPage => _itemsPerPage;
  int get currentPage => _currentPageIndex + 1;
  bool get isFetchingPage => _isFetchingPage;
  bool get canGoPrevious => _currentPageIndex > 0;
  bool get canGoNext => _hasMorePages;

  // --- NUEVOS GETTERS PARA SELECCIÓN ---
  Set<String> get selectedReservaIds => Set.from(_selectedReservaIds);
  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedReservaIds.length;
  
  // Obtener reservas seleccionadas
  List<ReservaConAgencia> get selectedReservas {
    return _allLoadedReservas
        .where((reserva) => _selectedReservaIds.contains(reserva.id))
        .toList();
  }

  // --- MÉTODOS PARA SELECCIÓN ---
  
  /// Activa o desactiva el modo de selección
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedReservaIds.clear();
    }
    notifyListeners();
  }

  /// Selecciona o deselecciona una reserva específica
  void toggleReservaSelection(String reservaId) {
    if (_selectedReservaIds.contains(reservaId)) {
      _selectedReservaIds.remove(reservaId);
    } else {
      _selectedReservaIds.add(reservaId);
    }
    
    // Si no hay reservas seleccionadas, salir del modo selección
    if (_selectedReservaIds.isEmpty) {
      _isSelectionMode = false;
    }
    
    notifyListeners();
  }

  /// Inicia el modo de selección con una reserva específica
  void startSelectionWith(String reservaId) {
    _isSelectionMode = true;
    _selectedReservaIds.clear();
    _selectedReservaIds.add(reservaId);
    notifyListeners();
  }

  /// Selecciona todas las reservas visibles
  void selectAllVisible() {
    _selectedReservaIds.clear();
    _selectedReservaIds.addAll(_allLoadedReservas.map((r) => r.id));
    _isSelectionMode = true;
    notifyListeners();
  }

  /// Deselecciona todas las reservas
  void clearSelection() {
    _selectedReservaIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  /// Verifica si una reserva está seleccionada
  bool isReservaSelected(String reservaId) {
    return _selectedReservaIds.contains(reservaId);
  }

  // --- MÉTODOS PARA CÁLCULOS DE SELECCIONADAS ---
  
  /// Calcula el total de PAX de las reservas seleccionadas
  int getSelectedTotalPax() {
    return selectedReservas.fold<int>(0, (sum, ra) => sum + ra.reserva.pax);
  }

  /// Calcula el total de saldo de las reservas seleccionadas
  double getSelectedTotalSaldo() {
    return selectedReservas.fold<double>(0.0, (sum, ra) => sum + ra.reserva.saldo);
  }

  /// Calcula el total de deuda de las reservas seleccionadas
  double getSelectedTotalDeuda() {
    return selectedReservas.fold<double>(0.0, (sum, ra) => sum + ra.reserva.deuda);
  }

  // Métodos existentes sin cambios...
  Future<void> _loadAllAgencias() async {
    final all = await _firestoreService.getAllAgencias();
    _allAgencias = all.where((a) => !a.eliminada).toList();
  }

  List<Agencia> getAllAgencias() {
    return _allAgencias;
  }

  Stream<List<ReservaConAgencia>> getAllReservasConAgenciaStream() {
    return Rx.combineLatest2<List<Reserva>, List<Agencia>, List<ReservaConAgencia>>(
      _firestoreService.getReservasStream(),
      _firestoreService.getAgenciasStream(),
      (reservas, agencias) {
        return reservas.where((r) => agencias.any((a) => a.id == r.agenciaId)).map((r) {
          final ag = agencias.firstWhereOrNull((a) => a.id == r.agenciaId) ??
              Agencia(
                id: r.agenciaId,
                nombre: 'Agencia DesconocidaAA',
                eliminada: true,
              );
          return ReservaConAgencia(reserva: r, agencia: ag);
        }).toList();
      },
    );
  }

  void updateFilter(
    DateFilterType filter, {
    DateTime? date,
    String? agenciaId,
    TurnoType? turno,
  }) {
    if (_selectedFilter == filter &&
        _customDate == date &&
        _agenciaIdFilter == agenciaId &&
        _turnoFilter == turno) {
      return;
    }

    _selectedFilter = filter;
    _customDate = date;
    _agenciaIdFilter = agenciaId;
    _turnoFilter = turno;
    
    // Limpiar selección al cambiar filtros
    _selectedReservaIds.clear();
    _isSelectionMode = false;
    
    _updateFilteredReservasStream(resetPagination: true);
    notifyListeners();
  }

  void setItemsPerPage(int newSize) {
    if (_itemsPerPage == newSize) return;
    _itemsPerPage = newSize;
    
    // Limpiar selección al cambiar paginación
    _selectedReservaIds.clear();
    _isSelectionMode = false;
    
    _updateFilteredReservasStream(resetPagination: true);
  }

  void nextPage() {
    if (!canGoNext || _isFetchingPage) return;
    _currentPageIndex++;
    
    // Limpiar selección al cambiar página
    _selectedReservaIds.clear();
    _isSelectionMode = false;
    
    _updateFilteredReservasStream(resetPagination: false);
  }

  void previousPage() {
    if (!canGoPrevious || _isFetchingPage) return;
    _currentPageIndex--;
    
    // Limpiar selección al cambiar página
    _selectedReservaIds.clear();
    _isSelectionMode = false;
    
    _updateFilteredReservasStream(resetPagination: false);
  }

  Future<List<ReservaConAgencia>> getAllFilteredReservasSinPaginacion() async {
    final snapshot = await _firestoreService
        .getReservasFiltered(
          turno: _turnoFilter,
          filter: _selectedFilter,
          customDate: _customDate,
          agenciaId: _agenciaIdFilter,
        )
        .first;

    final raw = snapshot.docs.map((d) => d.data()).toList();
    final todayEnd = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ).add(Duration(days: 1));
    final valid = raw
        .where((r) => _allAgencias.any((a) => a.id == r.agenciaId))
        .where((r) => r.estado != EstadoReserva.pagada)
        .where((r) => r.fecha.isBefore(todayEnd))
        .toList();

    return valid.map((r) {
      final ag = _allAgencias.firstWhere((a) => a.id == r.agenciaId);
      return ReservaConAgencia(reserva: r, agencia: ag);
    }).toList();
  }

  void _updateFilteredReservasStream({bool resetPagination = false}) {
    _reservasSubscription?.cancel();

    if (resetPagination) {
      _allLoadedReservas = [];
      _currentPageIndex = 0;
      _hasMorePages = true;
      _filteredReservasSubject.add([]);
    }

    _isFetchingPage = true;
    _isLoading = true;
    notifyListeners();

    _reservasSubscription?.cancel();

    _reservasSubscription = _firestoreService
        .getReservasFiltered(
          turno: _turnoFilter,
          filter: _selectedFilter,
          customDate: _customDate,
          agenciaId: _agenciaIdFilter,
        )
        .listen(
          (snapshot) {
            final raw = snapshot.docs.map((d) => d.data()).toList();
            final valid = raw
                .where((r) => _allAgencias.any((a) => a.id == r.agenciaId))
                .toList();
            final total = valid.length;
            final start = _currentPageIndex * _itemsPerPage;
            final end = (start + _itemsPerPage).clamp(0, total);
            _hasMorePages = end < total;
            final slice = valid.sublist(start, end);
            _allLoadedReservas = slice.map((r) {
              final ag = _allAgencias.firstWhere((a) => a.id == r.agenciaId);
              return ReservaConAgencia(reserva: r, agencia: ag);
            }).toList();
            _isFetchingPage = false;
            _isLoading = false;
            _filteredReservasSubject.add(_allLoadedReservas);
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Error en ReservasController stream: $e');
            _isFetchingPage = false;
            _isLoading = false;
            _filteredReservasSubject.addError(e);
            notifyListeners();
          },
        );
  }

  // Métodos CRUD sin cambios
  Future<void> addReserva(Reserva reserva) async {
    await _firestoreService.addReserva(reserva);
  }

  Future<void> updateReserva(String id, Reserva reserva) async {
    await _firestoreService.updateReserva(id, reserva);
  }

  Future<void> deleteReserva(String id) async {
    await _firestoreService.deleteReserva(id);
  }

  static void printDebugInfo() {
    debugPrint('ReservasController debug info: (implementar si es necesario)');
  }

  @override
  void dispose() {
    _reservasSubscription?.cancel();
    _agenciasSub?.cancel();
    _filteredReservasSubject.close();
    super.dispose();
  }
}
