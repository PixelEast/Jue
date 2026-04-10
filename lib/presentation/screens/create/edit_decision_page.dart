import 'package:flutter/material.dart';
import '../../../data/models/app_models.dart';
import 'create_decision_page.dart';

class EditDecisionPage extends StatelessWidget {
  final Decision decision;

  const EditDecisionPage({super.key, required this.decision});

  @override
  Widget build(BuildContext context) {
    return CreateDecisionPage(initialDecision: decision, isEditing: true);
  }
}
