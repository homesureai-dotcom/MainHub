import 'package:flutter/material.dart';

import '../../../core/engine/engine.dart';
import '../../../core/engine/models/question_evaluation.dart';
import '../../../core/phs/phs_answer.dart';

class EnginePlaygroundScreen extends StatefulWidget {
  const EnginePlaygroundScreen({super.key});

  @override
  State<EnginePlaygroundScreen> createState() =>
      _EnginePlaygroundScreenState();
}

class _EnginePlaygroundScreenState
    extends State<EnginePlaygroundScreen> {
  final PropertyIntelligenceEngine engine =
      PropertyIntelligenceEngine();

  PHSResponse selectedAnswer = PHSResponse.yes;

  QuestionEvaluation? result;

  void evaluate() {
    setState(() {
      result = engine.evaluate(
        PHSAnswer(
          questionId: "LEGAL_OC",
          response: selectedAnswer,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Engine Playground"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text(
              "Property Intelligence Engine",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Question",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Does the property have a valid Occupancy Certificate?",
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Answer",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            RadioListTile<PHSResponse>(
              title: const Text("Yes"),
              value: PHSResponse.yes,
              groupValue: selectedAnswer,
              onChanged: (value) {
                setState(() {
                  selectedAnswer = value!;
                });
              },
            ),

            RadioListTile<PHSResponse>(
              title: const Text("No"),
              value: PHSResponse.no,
              groupValue: selectedAnswer,
              onChanged: (value) {
                setState(() {
                  selectedAnswer = value!;
                });
              },
            ),

            RadioListTile<PHSResponse>(
              title: const Text("I'm Not Sure"),
              value: PHSResponse.unsure,
              groupValue: selectedAnswer,
              onChanged: (value) {
                setState(() {
                  selectedAnswer = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: evaluate,
              child: const Text("Evaluate"),
            ),

            const SizedBox(height: 30),

            if (result != null) ...[
              Card(
                child: ListTile(
                  title: const Text("Score"),
                  subtitle: Text(
                    "${result!.score} / ${result!.maxScore}",
                  ),
                ),
              ),

              if (result!.risk != null)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning,
                      color: Colors.red,
                    ),
                    title: Text(result!.risk!.title),
                    subtitle: Text(
                      result!.risk!.description,
                    ),
                  ),
                ),

              if (result!.recommendation != null)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.lightbulb,
                      color: Colors.orange,
                    ),
                    title: Text(
                      result!.recommendation!.title,
                    ),
                    subtitle: Text(
                      result!.recommendation!.description,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}