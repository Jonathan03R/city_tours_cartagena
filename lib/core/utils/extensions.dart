

// Extensión para firstWhereOrNull, ya que no está en todas las versiones de Dart
import 'package:citytourscartagena/screens/main_screens.dart';

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}


extension TurnoTypeExtension on TurnoType {
  String get label {
    switch (this) {
      case TurnoType.manana:
        return 'mañana';
      case TurnoType.tarde:
        return 'tarde';
    }
  }
}
