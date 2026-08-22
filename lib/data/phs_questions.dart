import '../core/phs/phs_categories.dart';
import '../core/phs/phs_question.dart';

const List<PHSQuestion> phsQuestions = [

  //==========================================================
  // OCCUPANCY CERTIFICATE
  //==========================================================

  PHSQuestion(
    id: "LEGAL_OC",
    category: PHSCategory.legalOwnership,
    title: "Does the property have a valid Occupancy Certificate (OC)?",
    helpText:
        "The Occupancy Certificate confirms that the building has been approved for occupation by the local authority.",

    whyItMatters:
        "Without a valid Occupancy Certificate, the property may not be legally fit for occupation and could face future legal or utility-related complications.",

    impact:
        "A missing Occupancy Certificate significantly reduces Property Health because it is one of the most important legal compliance documents.",

    priority: QuestionPriority.critical,

    potentialPHIGain: 10,

    weight: 40,

    requiredEvidence: [
      "Occupancy Certificate",
    ],

    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  //==========================================================
  // SALE DEED
  //==========================================================

  PHSQuestion(
    id: "LEGAL_SD",
    category: PHSCategory.legalOwnership,
    title: "Is the Sale Deed registered?",
    helpText:
        "A registered Sale Deed legally establishes ownership of the property.",

    whyItMatters:
        "The Sale Deed is the primary proof of ownership and is essential for resale, loans, inheritance and legal protection.",

    impact:
        "An unregistered or missing Sale Deed creates significant ownership risk and can affect the property's legal standing.",

    priority: QuestionPriority.critical,

    potentialPHIGain: 8,

    weight: 25,

    requiredEvidence: [
      "Registered Sale Deed",
    ],

    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  //==========================================================
  // E-KHATA
  //==========================================================

  PHSQuestion(
    id: "LEGAL_KHATA",
    category: PHSCategory.legalOwnership,
    title: "Does the property have an e-Khata?",

    helpText:
        "An e-Khata is the official municipal property record maintained by the local authority.",

    whyItMatters:
        "An updated e-Khata simplifies ownership verification, taxation, property registration and municipal services.",

    impact:
        "Missing or incorrect e-Khata records can delay registrations, resale and financing.",

    priority: QuestionPriority.high,

    potentialPHIGain: 6,

    weight: 20,

    requiredEvidence: [
      "e-Khata",
    ],

    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  //==========================================================
  // ENCUMBRANCE CERTIFICATE
  //==========================================================

  PHSQuestion(
    id: "LEGAL_EC",

    category: PHSCategory.legalOwnership,

    title: "Do you have a recent Encumbrance Certificate?",

    helpText:
        "The Encumbrance Certificate confirms there are no registered legal liabilities on the property.",

    whyItMatters:
        "The Encumbrance Certificate helps verify that the property is free from registered financial or legal encumbrances.",

    impact:
        "Keeping a recent EC improves confidence during resale, refinancing and legal verification.",

    priority: QuestionPriority.medium,

    potentialPHIGain: 4,

    weight: 15,

    requiredEvidence: [
      "Encumbrance Certificate",
    ],

    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),
];