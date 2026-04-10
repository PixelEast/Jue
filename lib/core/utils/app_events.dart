import 'package:flutter/foundation.dart';

class AppEvents {
  static final ValueNotifier<int> historyChanged = ValueNotifier<int>(0);

  static void notifyHistoryChanged() {
    historyChanged.value++;
  }
}
