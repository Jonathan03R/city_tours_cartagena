import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para manejar estadisticas (gastos y metas) en Firestore
class MetricsService {
  /// Obtiene la suma total de gastos entre dos fechas
  Future<double> getExpensesSumBetween(DateTime start, DateTime end) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('gastos')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['amount'] as num).toDouble();
    }
    return total;
  }

  /// Agrega un gasto a la colección 'gastos' en Firestore
  /// Guarda: amount, date, description
  Future<void> addExpense({
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    // Importar FirebaseFirestore si no está importado
    // import 'package:cloud_firestore/cloud_firestore.dart';
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('gastos').add({
      'amount': amount,
      'date': Timestamp.fromDate(date),
      if (description != null) 'description': description,
    });
  }

  /// Obtiene el historial de gastos
  Future<List<Map<String, dynamic>>> getExpensesHistory() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('gastos')
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'amount': doc['amount'],
        'date': (doc['date'] as Timestamp).toDate(),
        'description': doc['description'] ?? '',
      };
    }).toList();
  }

  /// Elimina un gasto por ID
  Future<void> deleteExpense(String id) async {
    await FirebaseFirestore.instance.collection('gastos').doc(id).delete();
  }

  /// Agrega una meta semanal de pasajeros a la colección 'metas' en Firestore
  Future<void> addWeeklyPassengerGoal({
    required int goal,
    required DateTime date,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final startOfWeek = date.subtract(Duration(days: date.weekday % 7));
    await firestore.collection('metas').add({
      'goal': goal,
      'startOfWeek': Timestamp.fromDate(startOfWeek),
      'endOfWeek': Timestamp.fromDate(startOfWeek.add(const Duration(days: 6))),
      'createdAt': Timestamp.fromDate(date),
    });
  }

  /// Obtiene la meta semanal de pasajeros para una semana específica
  Future<Map<String, dynamic>?> getWeeklyPassengerGoal(DateTime date) async {
    final firestore = FirebaseFirestore.instance;

    // Calcula el inicio de la semana y normaliza al inicio del día
    final startOfWeek = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday % 7));

    print('DEBUG: Calculando startOfWeek ajustado: ${startOfWeek.toIso8601String()}');

    final allMetasSnapshot = await firestore.collection('metas').get();
    for (var doc in allMetasSnapshot.docs) {
      final storedStartOfWeek = (doc['startOfWeek'] as Timestamp).toDate();
      final normalizedStoredStartOfWeek = DateTime(
        storedStartOfWeek.year,
        storedStartOfWeek.month,
        storedStartOfWeek.day,
      );
      print('DEBUG: Meta en Firestore - startOfWeek (normalizado): ${normalizedStoredStartOfWeek.toIso8601String()}');

      if (normalizedStoredStartOfWeek == startOfWeek) {
        print('DEBUG: Meta encontrada al comparar solo el día: ${doc.data()}');
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }
    }

    print('DEBUG: No se encontró ninguna meta para startOfWeek: ${startOfWeek.toIso8601String()}');
    return null;
  }

  /// Obtiene todas las metas almacenadas en Firestore
  Future<List<Map<String, dynamic>>> getAllWeeklyPassengerGoals() async {
    final firestore = FirebaseFirestore.instance;

    // Obtén todas las metas ordenadas por fecha de inicio de la semana
    final snapshot = await firestore
        .collection('metas')
        .orderBy('startOfWeek', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'goal': doc['goal'],
        'startOfWeek': (doc['startOfWeek'] as Timestamp).toDate(),
        'endOfWeek': (doc['endOfWeek'] as Timestamp).toDate(),
        'createdAt': (doc['createdAt'] as Timestamp).toDate(),
      };
    }).toList();
  }

  /// Actualiza una meta semanal de pasajeros existente en Firestore
  Future<void> updateWeeklyPassengerGoal(String id, int nuevaMeta) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('metas').doc(id).update({'goal': nuevaMeta});
  }
}
