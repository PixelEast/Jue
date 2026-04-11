import 'package:flutter/foundation.dart';

class AppEvents {
  static final ValueNotifier<int> historyChanged = ValueNotifier<int>(0);
  static final ValueNotifier<int> decisionsChanged = ValueNotifier<int>(0);

  static void notifyHistoryChanged() {
    historyChanged.value++;
  }

  static void notifyDecisionsChanged() {
    decisionsChanged.value++;
  }
}
