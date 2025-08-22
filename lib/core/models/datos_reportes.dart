class FinanzasData {
  final int totalPas;
  final double totalRev;
  FinanzasData({required this.totalPas, required this.totalRev});
}

/// Data model for finance net totals (expenses and net income)
class FinanzasNetosData {
  final double totalExp;
  final double net;
  FinanzasNetosData({required this.totalExp, required this.net});
}
/// Data model for metas tab
class MetasData {
  final int pasWeek;
  final int pasMonth;
  MetasData({required this.pasWeek, required this.pasMonth});
}

/// Data model for metas history entry with compliance
class MetasHistoryData {
  final String id;
  final DateTime date;
  final int weeklyGoal;
  final int monthlyGoal;
  final int pasWeek;
  final int pasMonth;
  final bool weeklyOk;
  final bool monthlyOk;
  MetasHistoryData({
    required this.id,
    required this.date,
    required this.weeklyGoal,
    required this.monthlyGoal,
    required this.pasWeek,
    required this.pasMonth,
    required this.weeklyOk,
    required this.monthlyOk,
  });
}

/// Data model for passengers tab
class PasajerosData {
  final int totalPas;
  final double totalRev;
  final List<ChartCategoryData> data;
  PasajerosData({required this.totalPas, required this.totalRev, required this.data});
}

/// Model for chart category series
class ChartCategoryData {
  final String label;
  final int value;
  ChartCategoryData(this.label, this.value);
}


/// Data model for precios tab (ingresos)
class PreciosData {
  final double revGlobal;
  final double revWeek;
  final double revMonth;
  PreciosData({required this.revGlobal, required this.revWeek, required this.revMonth});
}

/// Data model for net prices (expenses and net incomes)
class PreciosNetosData {
  final double expGlobal;
  final double expWeek;
  final double expMonth;
  final double netGlobal;
  final double netWeek;
  final double netMonth;
  PreciosNetosData({
    required this.expGlobal,
    required this.expWeek,
    required this.expMonth,
    required this.netGlobal,
    required this.netWeek,
    required this.netMonth,
  });
}


class GoalsEntry {
  final String id;
  final DateTime date;
  final int weeklyGoal;
  final int monthlyGoal;

  GoalsEntry({
    required this.id,
    required this.date,
    required this.weeklyGoal,
    required this.monthlyGoal,
  });
}
