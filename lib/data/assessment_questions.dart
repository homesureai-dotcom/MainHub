import '../models/assessment_question.dart';

const assessmentQuestions = [

  AssessmentQuestion(
    id: "Q1",
    category: "Legal",
    question: "Does your property have an Occupancy Certificate (OC)?",
    helpText:
        "The Occupancy Certificate confirms that the building is approved for occupation by the local authority.",
    yesScore: 10,
    noScore: 0,
    unsureScore: 4,
  ),

  AssessmentQuestion(
    id: "Q2",
    category: "Legal",
    question: "Is your Sale Deed registered?",
    helpText:
        "A registered Sale Deed legally establishes ownership of the property.",
    yesScore: 10,
    noScore: 0,
    unsureScore: 5,
  ),

  AssessmentQuestion(
    id: "Q3",
    category: "Legal",
    question: "Do you have an e-Khata for this property?",
    helpText:
        "An e-Khata is the official municipal property record required for taxation and approvals.",
    yesScore: 8,
    noScore: 2,
    unsureScore: 4,
  ),

  AssessmentQuestion(
    id: "Q4",
    category: "Utilities",
    question: "Does your apartment have an individual BESCOM electricity meter?",
    helpText:
        "Individual electricity meters ensure direct billing from BESCOM.",
    yesScore: 8,
    noScore: 1,
    unsureScore: 4,
  ),
];