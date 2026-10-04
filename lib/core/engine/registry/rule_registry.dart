import '../config/question_rule_config.dart';

import '../config/rules/legal_oc_config.dart';
import '../config/rules/legal_sd_config.dart';
import '../config/rules/legal_khata_config.dart';
import '../config/rules/legal_ec_config.dart';

import '../config/rules/construction_cracks_config.dart';
import '../config/rules/construction_leakage_config.dart';
import '../config/rules/construction_dampness_config.dart';
import '../config/rules/construction_flooring_config.dart';
import '../config/rules/construction_paint_config.dart';
import '../config/rules/construction_waterproofing_config.dart';

import '../config/rules/utility_bescom_config.dart';
import '../config/rules/utility_bwssb_config.dart';
import '../config/rules/utility_stp_config.dart';
import '../config/rules/utility_wtp_config.dart';
import '../config/rules/utility_dg_config.dart';
import '../config/rules/utility_lifts_config.dart';
import '../config/rules/utility_water_config.dart';

import '../config/rules/safety_fire_noc_config.dart';
import '../config/rules/safety_emergency_exits_config.dart';
import '../config/rules/safety_fire_system_config.dart';
import '../config/rules/safety_cctv_config.dart';
import '../config/rules/safety_security_config.dart';
import '../config/rules/safety_lightning_config.dart';

import '../config/rules/community_association_config.dart';
import '../config/rules/community_corpus_config.dart';
import '../config/rules/community_amc_config.dart';
import '../config/rules/community_vendor_contracts_config.dart';
import '../config/rules/community_complaints_config.dart';

import '../config/rules/documentation_property_tax_config.dart';
import '../config/rules/documentation_bescom_config.dart';
import '../config/rules/documentation_bwssb_config.dart';
import '../config/rules/documentation_warranty_config.dart';
import '../config/rules/documentation_manuals_config.dart';

class RuleRegistry {
  RuleRegistry();

  static final List<QuestionRuleConfig> rules = [
    // =========================================================================
    // LEGAL & OWNERSHIP — 25%
    // =========================================================================

    legalOcRule,
    legalSdRule,
    legalKhataRule,
    legalEcRule,

    // =========================================================================
    // CONSTRUCTION QUALITY — 25%
    // =========================================================================

    constructionCracksRule,
    constructionLeakageRule,
    constructionDampnessRule,
    constructionFlooringRule,
    constructionPaintRule,
    constructionWaterproofingRule,

    // =========================================================================
    // UTILITIES & INFRASTRUCTURE — 15%
    // =========================================================================

    utilityBescomRule,
    utilityBwssbRule,
    utilityStpRule,
    utilityWtpRule,
    utilityDgRule,
    utilityLiftsRule,
    utilityWaterRule,

    // =========================================================================
    // SAFETY & COMPLIANCE — 15%
    // =========================================================================

    safetyFireNocRule,
    safetyEmergencyExitsRule,
    safetyFireSystemRule,
    safetyCctvRule,
    safetySecurityRule,
    safetyLightningRule,

    // =========================================================================
    // COMMUNITY & MAINTENANCE — 10%
    // =========================================================================

    communityAssociationRule,
    communityCorpusRule,
    communityAmcRule,
    communityVendorContractsRule,
    communityComplaintsRule,

    // =========================================================================
    // DOCUMENTATION — 10%
    // =========================================================================

    documentationPropertyTaxRule,
    documentationBescomRule,
    documentationBwssbRule,
    documentationWarrantyRule,
    documentationManualsRule,
  ];

  QuestionRuleConfig getRule(String questionId) {
    for (final rule in rules) {
      if (rule.questionId == questionId) {
        return rule;
      }
    }

    throw StateError(
      'No rule configuration found for question: $questionId',
    );
  }
}