import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/assessment/assessment_engine.dart';
import '../../data/phs_questions.dart';
import '../../features/property/services/property_repository.dart';
import '../../features/report/services/report_builder_service.dart';
import '../../state/assessment_state.dart';
import '../../widgets/assessment/analyzing_step.dart';
import 'score_reveal_screen.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  @override
  void initState() {
    super.initState();
    _analyzeAssessment();
  }

  Future<void> _analyzeAssessment() async {
    await Future.delayed(const Duration(seconds: 2));

    final state = AssessmentState.instance;

    const engine = AssessmentEngine();

    final result = engine.evaluate(
      questions: phsQuestions,
      answers: state.answers,
    );

    // Save the assessment result
    state.saveResult(result);

    // Get the currently selected property
    final property = PropertyRepository.instance.selectedProperty;

    // Build the Property Health Report
    const reportBuilder = ReportBuilderService();

    final report = reportBuilder.build(
      property: property,
      assessment: result,
    );

    // Save the generated report
    state.saveReport(report);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ScoreRevealScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFF2563EB),
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 60,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Analyzing your Property",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "SureBot is evaluating your responses using the HomeSure Property Health Standard.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 40),

              const LinearProgressIndicator(),

              const SizedBox(height: 40),

              const AnalyzingStep(
                title: "Legal & Ownership",
                completed: true,
              ),

              const AnalyzingStep(
                title: "Construction Quality",
                completed: true,
              ),

              const AnalyzingStep(
                title: "Utilities & Infrastructure",
                completed: true,
              ),

              const AnalyzingStep(
                title: "Safety & Compliance",
                completed: true,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}