import 'package:citytourscartagena/core/models/agencia.dart';
import 'package:citytourscartagena/core/models/reserva.dart';
import 'package:citytourscartagena/core/models/reserva_con_agencia.dart';
import 'package:citytourscartagena/core/services/firestore_service.dart';
import 'package:citytourscartagena/core/widgets/date_filter_buttons.dart'; // Para DateFilterType
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class ReservasController extends ChangeNotifier {
  final FirestoreService _firestoreService;
  List<Agencia> _allAgencias = []; // Cache de agencias para combinar

  DateFilterType _selectedFilter = DateFilterType.today;
  DateTime? _customDate;
  String? _agenciaIdFilter; // Para filtrar por agencia en ReservasView

  // MODIFICADO: Usar BehaviorSubject para el stream de reservas filtradas
  // Esto lo convierte en un broadcast stream y almacena el último valor.
  final BehaviorSubject<List<ReservaConAgencia>> _filteredReservasSubject =
      BehaviorSubject<List<ReservaConAgencia>>();
  Stream<List<ReservaConAgencia>> get filteredReservasStream => _filteredReservasSubject.stream;

  List<ReservaConAgencia> _currentReservas = [];

  ReservasController({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService() {
    _loadAllAgencias(); // Cargar agencias una vez
    _updateFilteredReservasStream(); // Iniciar el stream de reservas
  }

  // Getters para la UI
  DateFilterType get selectedFilter => _selectedFilter;
  DateTime? get customDate => _customDate;
  List<ReservaConAgencia> get currentReservas => _currentReservas;

  // Método para cargar todas las agencias (para uso interno y dropdowns)
  Future<void> _loadAllAgencias() async {
    _allAgencias = await _firestoreService.getAllAgencias();
    notifyListeners(); // Notificar si esto afecta alguna UI que dependa de _allAgencias
  }

  // Método para obtener todas las agencias (para dropdowns en la UI)
  List<Agencia> getAllAgencias() {
    return _allAgencias;
  }

  // NUEVO: Stream para obtener TODAS las reservas con sus agencias, sin filtros
  Stream<List<ReservaConAgencia>> getAllReservasConAgenciaStream() {
    return Rx.combineLatest2<List<Reserva>, List<Agencia>, List<ReservaConAgencia>>(
      _firestoreService.getReservasStream(), // Stream de todas las reservas sin filtrar
      _firestoreService.getAgenciasStream(), // Stream de todas las agencias
      (reservas, agencias) {
        return reservas
            .where((r) => agencias.any((a) => a.id == r.agenciaId))
            .map((r) {
              final ag = agencias.firstWhere((a) => a.id == r.agenciaId);
              return ReservaConAgencia(reserva: r, agencia: ag);
            })
            .toList();
      },
    );
  }

  // Método para actualizar el filtro y recargar el stream
  void updateFilter(DateFilterType filter, {DateTime? date, String? agenciaId}) {
    _selectedFilter = filter;
    _customDate = date;
    _agenciaIdFilter = agenciaId;
    _updateFilteredReservasStream();
    notifyListeners();
  }

  // Lógica para construir el stream de reservas basado en el filtro
  void _updateFilteredReservasStream() {
    Stream<List<Reserva>> baseReservasStream;

    switch (_selectedFilter) {
      case DateFilterType.all:
        baseReservasStream = _firestoreService.getReservasStream();
        break;
      case DateFilterType.today:
        baseReservasStream = _firestoreService.getReservasByFechaStream(DateTime.now());
        break;
      case DateFilterType.yesterday:                                    // ← nuevo
        final ayer = DateTime.now().subtract(const Duration(days: 1));
        baseReservasStream = _firestoreService.getReservasByFechaStream(ayer);
        break;
      case DateFilterType.tomorrow:
        baseReservasStream = _firestoreService.getReservasByFechaStream(DateTime.now().add(const Duration(days: 1)));
        break;
      case DateFilterType.lastWeek:
        final now = DateTime.now();
        final startOfWeek = now.subtract(const Duration(days: 7));
        baseReservasStream = _firestoreService.getReservasByDateRangeStream(startOfWeek, now);
        break;
      case DateFilterType.custom:
        if (_customDate != null) {
          baseReservasStream = _firestoreService.getReservasByFechaStream(_customDate!);
        } else {
          baseReservasStream = Stream.value([]); // Stream vacío si no hay fecha personalizada
        }
        break;
    }

    // Combinar con agencias y aplicar filtro de agencia si existe
    Rx.combineLatest2<List<Reserva>, List<Agencia>, List<ReservaConAgencia>>(
      baseReservasStream,
      _firestoreService.getAgenciasStream(), // Siempre necesitamos las agencias para combinar
      (reservas, agencias) {
        final combinedList = reservas
            .where((r) => agencias.any((a) => a.id == r.agenciaId))
            .map((r) {
              final ag = agencias.firstWhere((a) => a.id == r.agenciaId);
              return ReservaConAgencia(reserva: r, agencia: ag);
            })
            .toList();

        // Aplicar filtro de agencia si está activo
        if (_agenciaIdFilter != null && _agenciaIdFilter!.isNotEmpty) {
          return combinedList.where((r) => r.agencia.id == _agenciaIdFilter).toList();
        }
        return combinedList;
      },
    ).listen((data) {
      _currentReservas = data;
      _filteredReservasSubject.add(data); // Emitir los datos a través del BehaviorSubject
    }, onError: (error) {
      debugPrint('Error en ReservasController stream: $error');
      _filteredReservasSubject.addError(error); // Emitir el error a través del BehaviorSubject
    });
  }

  // Métodos CRUD que delegan a FirestoreService
  Future<void> addReserva(Reserva reserva) async {
    await _firestoreService.addReserva(reserva);
  }

  Future<void> updateReserva(String id, Reserva reserva) async {
    await _firestoreService.updateReserva(id, reserva);
  }

  Future<void> deleteReserva(String id) async {
    await _firestoreService.deleteReserva(id);
  }

  // Método para depuración (mantener si es útil)
  static void printDebugInfo() {
    debugPrint('ReservasController debug info: (implementar si es necesario)');
  }

  @override
  void dispose() {
    _filteredReservasSubject.close(); // Es crucial cerrar el BehaviorSubject
    super.dispose();
  }
}
