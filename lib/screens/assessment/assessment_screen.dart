import 'package:flutter/material.dart';

import '../../core/phs/phs_answer.dart';
import '../../data/phs_questions.dart';
import '../../state/assessment_state.dart';
import '../../widgets/assessment/answer_option.dart';
import '../../widgets/assessment/assessment_progress.dart';
import '../../widgets/assessment/question_card.dart';
import 'analyzing_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int currentQuestion = 0;

  final AssessmentState assessmentState = AssessmentState.instance;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      assessmentState.startAssessment();
    });
  }

  void saveAnswer(PHSResponse response) {
    final question = phsQuestions[currentQuestion];

    assessmentState.saveAnswer(
      PHSAnswer(
        questionId: question.id,
        response: response,
      ),
    );

    if (currentQuestion < phsQuestions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AnalyzingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = phsQuestions[currentQuestion];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        title: const Text("Property Assessment"),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssessmentProgress(
                current: currentQuestion + 1,
                total: phsQuestions.length,
              ),

              const SizedBox(height: 24),

              QuestionCard(
                question: question,
              ),

              const SizedBox(height: 24),

              AnswerOption(
                icon: Icons.check_circle,
                color: Colors.green,
                text: "Yes",
                onTap: () => saveAnswer(PHSResponse.yes),
              ),

              const SizedBox(height: 14),

              AnswerOption(
                icon: Icons.cancel,
                color: Colors.red,
                text: "No",
                onTap: () => saveAnswer(PHSResponse.no),
              ),

              const SizedBox(height: 14),

              AnswerOption(
                icon: Icons.help,
                color: Colors.orange,
                text: "I'm Not Sure",
                onTap: () => saveAnswer(PHSResponse.unsure),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}