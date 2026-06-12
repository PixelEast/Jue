import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static final WidgetService _instance = WidgetService._();
  factory WidgetService() => _instance;
  WidgetService._();

  static const String _androidWidgetName = 'JueWidgetProvider';
  static const String _androidWidgetWideName = 'JueWidgetWideProvider';

  Future<void> updateWidgetData({
    required String decisionId,
    required String decisionTheme,
  }) async {
    try {
      await HomeWidget.saveWidgetData('widget_decision_id', decisionId);
      await HomeWidget.saveWidgetData('widget_decision_theme', decisionTheme);
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: 'widget.JueWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: _androidWidgetWideName,
        androidName: 'widget.JueWidgetWideProvider',
      );
      debugPrint('WidgetService: Updated widget with id=$decisionId, theme=$decisionTheme');
    } catch (e) {
      debugPrint('WidgetService: Failed to update widget: $e');
    }
  }

  Future<void> removeWidgetData() async {
    try {
      await HomeWidget.saveWidgetData('widget_decision_id', null);
      await HomeWidget.saveWidgetData('widget_decision_theme', null);
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
        androidName: 'widget.JueWidgetProvider',
      );
      await HomeWidget.updateWidget(
        name: _androidWidgetWideName,
        androidName: 'widget.JueWidgetWideProvider',
      );
      debugPrint('WidgetService: Removed widget data');
    } catch (e) {
      debugPrint('WidgetService: Failed to remove widget data: $e');
    }
  }

  Future<String?> getWidgetDecisionId() async {
    try {
      return await HomeWidget.getWidgetData('widget_decision_id');
    } catch (e) {
      debugPrint('WidgetService: Failed to get widget decision id: $e');
      return null;
    }
  }

  Future<String?> getWidgetDecisionTheme() async {
    try {
      return await HomeWidget.getWidgetData('widget_decision_theme');
    } catch (e) {
      debugPrint('WidgetService: Failed to get widget decision theme: $e');
      return null;
    }
  }
}
