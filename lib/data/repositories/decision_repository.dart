import '../models/app_models.dart';
import '../local/app_storage.dart';

class DecisionRepository {
  Future<List<Decision>> getAllDecisions() async {
    return await AppStorage.getDecisions();
  }

  Future<Decision?> getDecisionById(String id) async {
    final decisions = await getAllDecisions();
    try {
      return decisions.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Decision?> saveDecision(Decision decision) async {
    return await AppStorage.saveDecision(decision);
  }

  Future<void> deleteDecision(String id) async {
    await AppStorage.deleteDecision(id);
  }

  Future<Decision?> getDraft() async {
    final decisions = await getAllDecisions();
    try {
      return decisions.firstWhere((d) => d.isDraft);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearDraft() async {
    final decisions = await getAllDecisions();
    final draftIds = decisions
        .where((d) => d.isDraft)
        .map((d) => d.id)
        .toList();
    for (final id in draftIds) {
      await AppStorage.deleteDecision(id);
    }
  }
}
