import 'dart:async'; // Importar para StreamSubscription

import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/firestore_service.dart';
import 'package:citytourscartagena/core/utils/extensions.dart'; // Importar la extensión compartida
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart'; // Para DateFilterType
import 'package:citytourscartagena/screens/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ReservasController extends ChangeNotifier {
  final FirestoreService _firestoreService;
  StreamSubscription?
  _reservasSubscription; // Para gestionar la suscripción al stream

  // --- Filtros ---
  TurnoType? _turnoFilter;
  DateFilterType _selectedFilter = DateFilterType.today;
  DateTime? _customDate;
  String? _agenciaIdFilter; // Para filtrar por agencia en ReservasView

  // --- Paginación ---
  int _itemsPerPage = 10; // Default items per page
  int _currentPageIndex = 0; // 0-indexed current page
  bool _isFetchingPage = false; // To prevent multiple simultaneous fetches
  bool _hasMorePages =
      true; // Indicates if there are more pages after the current one
  List<ReservaConAgencia> _allLoadedReservas = []; // DECLARACIÓN AÑADIDA AQUÍ
  bool _isLoading = false; // Nuevo estado de carga

  // --- Streams ---
  final BehaviorSubject<List<ReservaConAgencia>> _filteredReservasSubject =
      BehaviorSubject<List<ReservaConAgencia>>();
  Stream<List<ReservaConAgencia>>
  get filteredReservasStream => // CORREGIDO: ReservaConAgencia
      _filteredReservasSubject.stream;
  StreamSubscription<List<Agencia>>? _agenciasSub;

  List<Agencia> _allAgencias = []; // Cache de agencias para combinar

  ReservasController({FirestoreService? firestoreService})
    : _firestoreService = firestoreService ?? FirestoreService() {
    _initializeController(); // Call async initialization

    // ---------------- SUSCRIPCIÓN A CAMBIOS EN AGENCIAS ----------------
    _agenciasSub = _firestoreService.getAgenciasStream().listen((all) {
      // sólo agencias activas
      _allAgencias = all.where((a) => !a.eliminada).toList();
      // refrescar lista de reservas actuales
      _updateFilteredReservasStream(resetPagination: true);
    });
  }

  Future<void> _initializeController() async {
    _isLoading = true;
    notifyListeners();
    await _loadAllAgencias(); // Await agency loading
    _updateFilteredReservasStream(resetPagination: true); // Then update stream
  }

  // Getters para la UI
  DateFilterType get selectedFilter => _selectedFilter;
  DateTime? get customDate => _customDate;
  List<ReservaConAgencia> get currentReservas =>
      _allLoadedReservas; // Ahora devuelve todas las cargadas
  TurnoType? get turnoFilter => _turnoFilter; // Exponer el filtro de turno
  bool get isLoading => _isLoading; // Exponer el estado de carga

  // Getters para la paginación
  int get itemsPerPage => _itemsPerPage;
  int get currentPage => _currentPageIndex + 1; // 1-indexed for UI
  bool get isFetchingPage => _isFetchingPage;
  bool get canGoPrevious => _currentPageIndex > 0;
  bool get canGoNext => _hasMorePages;

  // Método para cargar todas las agencias (para uso interno y dropdowns)
  Future<void> _loadAllAgencias() async {
    final all = await _firestoreService.getAllAgencias();
    _allAgencias = all.where((a) => !a.eliminada).toList();
    // debugPrint('✅ Agencias cargadas: ${_allAgencias.length}'); // Debug print
    // No notificar listeners aquí, ya que _updateFilteredReservasStream lo hará
  }

  // Método para obtener todas las agencias (para dropdowns en la UI)
  List<Agencia> getAllAgencias() {
    return _allAgencias;
  }

  // NUEVO: Stream para obtener TODAS las reservas con sus agencias, sin filtros
  Stream<List<ReservaConAgencia>> getAllReservasConAgenciaStream() {
    return Rx.combineLatest2<
      List<Reserva>,
      List<Agencia>,
      List<ReservaConAgencia>
    >(
      _firestoreService
          .getReservasStream(), // Stream de todas las reservas sin filtrar
      _firestoreService.getAgenciasStream(), // Stream de todas las agencias
      /// Combina reservas y agencias para crear una lista de ReservaConAgencia
      /// @param reservas Lista de reservas obtenidas del stream
      /// @param agencias Lista de agencias obtenidas del stream
      /// @return Lista de ReservaConAgencia que combina reservas con sus agencias correspondientes
      (reservas, agencias) {
        // Filtrar reservas para incluir solo aquellas que tienen una agencia válida
        // y mapearlas a ReservaConAgencia
        return reservas.where((r) => agencias.any((a) => a.id == r.agenciaId)).map((
          r,
        ) {
          /// Buscar la agencia correspondiente a la reserva
          /// @param r Reserva actual del stream
          /// @return ReservaConAgencia que combina la reserva con su agencia
          /// Si no se encuentra la agencia, se crea una agencia por defecto
          /// con el ID de la reserva y un nombre genérico
          /// para evitar errores en la UI.
          /// Esto es útil para manejar casos donde la agencia puede haber sido eliminada.
          /// @note Se utiliza firstWhereOrNull para evitar excepciones si no se encuentra la agencia
          /// y se proporciona un fallback para evitar errores en la UI.
          final ag =
              agencias.firstWhereOrNull((a) => a.id == r.agenciaId) ??
              Agencia(
                id: r.agenciaId,
                nombre: 'Agencia DesconocidaAA',
                eliminada: true,
              ); // Fallback
          return ReservaConAgencia(reserva: r, agencia: ag);
        }).toList();
      },
    );
  }

  // Método para actualizar el filtro y recargar el stream
  /// Actualiza los filtros de reservas y recarga el stream
  /// @param filter El filtro de tipo DateFilterType a aplicar
  /// @param date Fecha personalizada si se aplica
  /// @param agenciaId ID de la agencia para filtrar reservas
  /// @param turno Turno seleccionado para filtrar reservas
  /// @note Este método no fuerza una recarga de la UI, ya que el stream
  ///       se actualizará automáticamente al cambiar los filtros.
  /// @note Si el filtro no cambia, no se actualiza el stream.
  /// @note Si se cambia el filtro, se reinicia la paginación.
  /// @note Si se cambia el turno, se reinicia la paginación.
  /// @note Si se cambia la agencia, se reinicia la paginación.
  /// @note Si se cambia la fecha personalizada, se reinicia la paginación.
  /// @note Si se cambia el número de elementos por página, se reinicia la paginación.
  /// @note Si se cambia la página actual, se reinicia la paginación.
  /// @note Si se cambia el estado de carga, se reinicia la paginación.
  /// @note Si se cambia el estado de paginación, se reinicia la paginación.
  void updateFilter(
    DateFilterType filter, {
    DateTime? date,
    String? agenciaId,
    TurnoType? turno,
  }) {
    //   debugPrint('🔎 filtro prueba → '
    //   'filter: $filter, '
    //   'customDate: ${date?.toIso8601String() ?? "null"}, '
    //   'agenciaId: ${agenciaId ?? "null"}, '
    //   'turno: ${turno?.toString() ?? "null"}'
    // );
    // Solo actualizar si los filtros realmente cambian
    /// la condicion dice que si el filtro, fecha, agencia o turno no cambian, no se actualiza
    /// esto previene recargas innecesarias del stream
    /// ejemplo: si el filtro es DateFilterType.today y la fecha es null, no se actualiza
    /// la condicion dice _selectedFilter == filter lo que quiere decir que el filtro no ha cambiado
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
    _updateFilteredReservasStream(
      resetPagination: true,
    ); // Resetear paginación al cambiar filtros
    notifyListeners(); // Notificar para que la UI refleje los nuevos filtros
  }

  // Método para establecer el número de elementos por página
  void setItemsPerPage(int newSize) {
    if (_itemsPerPage == newSize) return;
    _itemsPerPage = newSize;
    _updateFilteredReservasStream(resetPagination: true);
  }

  // Método para cargar la siguiente página de reservas
  void nextPage() {
    if (!canGoNext || _isFetchingPage) return;
    _currentPageIndex++;
    _updateFilteredReservasStream(resetPagination: false);
  }

  // Método para cargar la página anterior de reservas
  void previousPage() {
    if (!canGoPrevious || _isFetchingPage) return;
    _currentPageIndex--;
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
    final valid = raw
        .where((r) => _allAgencias.any((a) => a.id == r.agenciaId))
        .toList();

    return valid.map((r) {
      final ag = _allAgencias.firstWhere((a) => a.id == r.agenciaId);
      return ReservaConAgencia(reserva: r, agencia: ag);
    }).toList();
  }

  // Lógica para construir el stream de reservas basado en el filtro y paginación
  void _updateFilteredReservasStream({bool resetPagination = false}) {
    _reservasSubscription
        ?.cancel(); // Cancelar suscripción anterior para evitar duplicados

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
            // Extraer reservas y filtrar por agencias válidas
            final raw = snapshot.docs.map((d) => d.data()).toList();
            final valid = raw
                .where((r) => _allAgencias.any((a) => a.id == r.agenciaId))
                .toList();
            // Paginación local
            final total = valid.length;
            final start = _currentPageIndex * _itemsPerPage;
            final end = (start + _itemsPerPage).clamp(0, total);
            _hasMorePages = end < total;
            final slice = valid.sublist(start, end);
            // Mapear a ReservaConAgencia
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

  // Métodos CRUD que delegan a FirestoreService (ya no fuerzan recarga)
  Future<void> addReserva(Reserva reserva) async {
    await _firestoreService.addReserva(reserva);
    // El stream de Firestore se encargará de actualizar la UI
  }

  Future<void> updateReserva(String id, Reserva reserva) async {
    await _firestoreService.updateReserva(id, reserva);
    // El stream de Firestore se encargará de actualizar la UI
  }

  Future<void> deleteReserva(String id) async {
    await _firestoreService.deleteReserva(id);
    // El stream de Firestore se encargará de actualizar la UI
  }

  // Método para depuración (mantener si es útil)
  static void printDebugInfo() {
    debugPrint('ReservasController debug info: (implementar si es necesario)');
  }

  @override
  void dispose() {
    _reservasSubscription?.cancel(); // Cancelar la suscripción al disponer
    _agenciasSub?.cancel();
    _filteredReservasSubject.close(); // Es crucial cerrar el BehaviorSubject
    super.dispose();
  }
}
