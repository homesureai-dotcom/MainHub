import '../core/phs/phs_categories.dart';
import '../core/phs/phs_question.dart';

/// Canonical Property Health Standard (PHS) question set.
///
/// This is the single source of truth for questions evaluated by the
/// Property Intelligence Engine.
final List<PHSQuestion> phsQuestions = [
  // ===========================================================================
  // LEGAL & OWNERSHIP — 25%
  // ===========================================================================

  PHSQuestion(
    id: 'LEGAL_OC',
    category: PHSCategory.legalOwnership,
    title: 'Is the Occupancy Certificate (OC) available?',
    helpText:
        'Verify that the competent authority has issued an Occupancy Certificate for the property/project.',
    whyItMatters:
        'An Occupancy Certificate indicates that the completed development has received the required occupancy approval.',
    impact:
        'Missing or unavailable occupancy approval can create significant legal, financing, resale, and possession-related risk.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 40,
    weight: 40,
    requiredEvidence: [
      'Occupancy Certificate',
      'OC approval/reference details',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'LEGAL_SD',
    category: PHSCategory.legalOwnership,
    title: 'Is the Sale Deed registered?',
    helpText:
        'Verify that the property ownership document has been executed and registered with the appropriate authority.',
    whyItMatters:
        'A registered Sale Deed is a key document establishing legal ownership of the property.',
    impact:
        'An unregistered or incomplete ownership document can create ownership and transaction risks.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 25,
    weight: 25,
    requiredEvidence: [
      'Registered Sale Deed',
      'Registration details',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'LEGAL_KHATA',
    category: PHSCategory.legalOwnership,
    title: 'Is the property Khata available and correctly recorded?',
    helpText:
        'Verify that the applicable Khata/e-Khata record exists and reflects the property correctly.',
    whyItMatters:
        'A valid property record supports taxation, municipal administration, financing, and future transactions.',
    impact:
        'Incorrect, incomplete, or unavailable Khata records can create administrative and transaction-related risk.',
    priority: QuestionPriority.high,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Khata certificate',
      'Khata extract',
      'e-Khata record',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'LEGAL_EC',
    category: PHSCategory.legalOwnership,
    title: 'Is the Encumbrance Certificate (EC) available?',
    helpText:
        'Verify the availability of an Encumbrance Certificate covering the relevant property period.',
    whyItMatters:
        'An EC provides information about registered transactions or encumbrances reflected in the relevant records.',
    impact:
        'Missing or incomplete EC documentation can make ownership due diligence less complete.',
    priority: QuestionPriority.high,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'Encumbrance Certificate',
      'Relevant EC period',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  // ===========================================================================
  // CONSTRUCTION QUALITY — 25%
  // ===========================================================================

  PHSQuestion(
    id: 'CONSTRUCTION_CRACKS',
    category: PHSCategory.constructionQuality,
    title: 'Are there no significant structural cracks?',
    helpText:
        'Inspect visible walls, slabs, beams, columns, balconies, and other relevant structural areas for significant cracks.',
    whyItMatters:
        'Significant cracks may indicate construction defects, movement, water ingress, or other issues requiring professional assessment.',
    impact:
        'Unresolved significant cracks can result in safety concerns, property damage, and future repair costs.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Inspection photographs',
      'Builder inspection report where applicable',
      'Structural engineer report for suspected structural cracks',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'CONSTRUCTION_LEAKAGE',
    category: PHSCategory.constructionQuality,
    title: 'Is the property free from significant water leakage?',
    helpText:
        'Check ceilings, walls, bathrooms, balconies, utility areas, parking areas, and other relevant locations for water leakage.',
    whyItMatters:
        'Water leakage can damage finishes, electrical systems, structures, and personal property.',
    impact:
        'Persistent leakage can result in deterioration, mould, repair costs, and disputes over responsibility.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Inspection photographs',
      'Leakage complaint records',
      'Builder rectification records where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'CONSTRUCTION_DAMPNESS',
    category: PHSCategory.constructionQuality,
    title: 'Is the property free from significant dampness?',
    helpText:
        'Inspect walls, ceilings, corners, bathrooms, balconies, and other areas for persistent dampness or moisture marks.',
    whyItMatters:
        'Dampness may indicate water ingress, plumbing problems, waterproofing failure, or ventilation issues.',
    impact:
        'Persistent dampness can deteriorate finishes and contribute to recurring maintenance problems.',
    priority: QuestionPriority.high,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'Inspection photographs',
      'Moisture inspection where applicable',
      'Rectification records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'CONSTRUCTION_FLOORING',
    category: PHSCategory.constructionQuality,
    title: 'Is the flooring quality satisfactory?',
    helpText:
        'Check flooring for cracks, hollow tiles, uneven surfaces, damaged tiles, or significant workmanship defects.',
    whyItMatters:
        'Flooring defects can affect usability, safety, appearance, and long-term maintenance.',
    impact:
        'Unresolved flooring defects can lead to replacement costs and recurring maintenance issues.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'Inspection photographs',
      'Snag list',
      'Rectification records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'CONSTRUCTION_PAINT',
    category: PHSCategory.constructionQuality,
    title: 'Is the paint and surface finish quality satisfactory?',
    helpText:
        'Check internal and external painted surfaces for peeling, patchiness, cracks, stains, or poor workmanship.',
    whyItMatters:
        'Paint and surface finishes provide protection as well as contributing to property condition and appearance.',
    impact:
        'Poor finishes can indicate workmanship issues and may require premature repainting or repair.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 10,
    weight: 10,
    requiredEvidence: [
      'Inspection photographs',
      'Snag list',
      'Warranty/rectification records where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'CONSTRUCTION_WATERPROOFING',
    category: PHSCategory.constructionQuality,
    title: 'Is waterproofing satisfactory in critical areas?',
    helpText:
        'Verify waterproofing performance in bathrooms, balconies, terraces, wet areas, basements, and other relevant locations.',
    whyItMatters:
        'Effective waterproofing protects the building from water ingress and associated deterioration.',
    impact:
        'Waterproofing failures can cause leakage, dampness, structural deterioration, and expensive repairs.',
    priority: QuestionPriority.high,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Waterproofing warranty',
      'Inspection records',
      'Rectification records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  // ===========================================================================
  // UTILITIES & INFRASTRUCTURE — 15%
  // ===========================================================================

  PHSQuestion(
    id: 'UTILITY_BESCOM',
    category: PHSCategory.utilitiesInfrastructure,
    title: 'Is the BESCOM electricity connection and metering operational?',
    helpText:
        'Verify electricity connection, individual/common metering, and relevant BESCOM documentation where applicable.',
    whyItMatters:
        'Reliable electricity supply and appropriate metering are essential for normal property operation.',
    impact:
        'Incomplete electrical infrastructure or documentation can create operational and financial risk.',
    priority: QuestionPriority.high,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'BESCOM documents',
      'Meter details',
      'Connection records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'UTILITY_BWSSB',
    category: PHSCategory.utilitiesInfrastructure,
    title: 'Is the BWSSB water and sewerage connection operational?',
    helpText:
        'Verify applicable water and sewerage connections, approvals, billing arrangements, and supporting records.',
    whyItMatters:
        'Reliable water and sewerage infrastructure is fundamental to property habitability and long-term operation.',
    impact:
        'Incomplete or unavailable water and sewerage arrangements can result in operational, financial, and compliance risks.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'BWSSB documents',
      'Connection details',
      'Demand/payment records where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'UTILITY_STP',
    category: PHSCategory.utilitiesInfrastructure,
    title: 'Is the Sewage Treatment Plant (STP) operational and maintained?',
    helpText:
        'Verify that the STP is operational, maintained, and supported by relevant operating or maintenance records.',
    whyItMatters:
        'Proper sewage treatment is important for environmental compliance and community infrastructure.',
    impact:
        'Poorly maintained or non-operational STP infrastructure can create environmental, regulatory, and maintenance risks.',
    priority: QuestionPriority.high,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'STP operation records',
      'Maintenance records',
      'Relevant test reports',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'UTILITY_WTP',
    category: PHSCategory.utilitiesInfrastructure,
    title: 'Is the Water Treatment Plant (WTP) operational where applicable?',
    helpText:
        'Verify WTP operation, maintenance, and relevant water-quality records where a WTP forms part of the property infrastructure.',
    whyItMatters:
        'Appropriate water treatment infrastructure supports reliable and suitable water availability.',
    impact:
        'Non-operational or poorly maintained treatment infrastructure can affect water quality and availability.',
    priority: QuestionPriority.high,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'WTP operation records',
      'Water-quality reports',
      'Maintenance records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'UTILITY_DG',
    category: PHSCategory.utilitiesInfrastructure,
    title: 'Is DG backup operational where applicable?',
    helpText:
        'Verify diesel generator backup availability, operational status, maintenance, and relevant records where applicable.',
    whyItMatters:
        'Backup power can support critical common-area infrastructure during electricity interruptions.',
    impact:
        'Non-operational backup power may affect lifts, pumps, security systems, and other common services during outages.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'DG maintenance records',
      'AMC documents',
      'Operational test records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'UTILITY_LIFTS',
    category: PHSCategory.utilitiesInfrastructure,
    title: 'Are the lifts operational and appropriately maintained?',
    helpText:
        'Verify lift operation, maintenance arrangements, inspection records, and applicable certifications.',
    whyItMatters:
        'Lift reliability and maintenance are important for accessibility, convenience, and resident safety.',
    impact:
        'Poorly maintained lifts can result in service interruptions and safety concerns.',
    priority: QuestionPriority.high,
    potentialPHIGain: 10,
    weight: 10,
    requiredEvidence: [
      'Lift maintenance records',
      'AMC documents',
      'Inspection/certification records where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'UTILITY_WATER',
    category: PHSCategory.utilitiesInfrastructure,
    title: 'Is adequate water availability maintained?',
    helpText:
        'Assess whether the property has reliable water availability through its applicable water sources and storage systems.',
    whyItMatters:
        'Reliable water availability is essential for everyday residential use and community operations.',
    impact:
        'Frequent water shortages can create significant operational and resident-management challenges.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'Water availability records',
      'Water source details',
      'Water-quality reports where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  // ===========================================================================
  // SAFETY & COMPLIANCE — 15%
  // ===========================================================================

  PHSQuestion(
    id: 'SAFETY_FIRE_NOC',
    category: PHSCategory.safetyCompliance,
    title: 'Is the Fire NOC available and valid where applicable?',
    helpText:
        'Verify the applicable Fire Department approval/NOC and supporting compliance records.',
    whyItMatters:
        'Fire-safety approvals and compliance arrangements are important for resident safety and statutory requirements.',
    impact:
        'Missing or unclear fire approvals can create significant safety and compliance risk.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Fire NOC',
      'Fire Department approval documents',
      'Renewal/compliance records where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'SAFETY_EMERGENCY_EXITS',
    category: PHSCategory.safetyCompliance,
    title: 'Are emergency exits accessible and clearly identified?',
    helpText:
        'Check that designated emergency exits are accessible, unobstructed, and appropriately identified.',
    whyItMatters:
        'Accessible emergency exits support safe evacuation during fires and other emergencies.',
    impact:
        'Blocked, unclear, or inaccessible exits can increase evacuation risk.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Site inspection photographs',
      'Emergency evacuation plan',
      'Fire-safety inspection records where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'SAFETY_FIRE_SYSTEM',
    category: PHSCategory.safetyCompliance,
    title: 'Is the fire-fighting system operational and maintained?',
    helpText:
        'Verify fire pumps, hydrants, alarms, extinguishers, sprinklers, and other applicable fire-fighting systems.',
    whyItMatters:
        'Operational fire-fighting systems are critical to responding to fire emergencies.',
    impact:
        'Non-operational or poorly maintained fire systems can materially increase safety risk.',
    priority: QuestionPriority.critical,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Fire system maintenance records',
      'Inspection reports',
      'AMC/service records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'SAFETY_CCTV',
    category: PHSCategory.safetyCompliance,
    title: 'Is CCTV coverage operational in relevant common areas?',
    helpText:
        'Verify that installed CCTV systems cover relevant common areas and are operational where applicable.',
    whyItMatters:
        'CCTV can support incident investigation, monitoring, and community security processes.',
    impact:
        'Non-operational or inadequate CCTV coverage can reduce monitoring capability in common areas.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'CCTV system details',
      'Maintenance records',
      'Sample operational verification',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'SAFETY_SECURITY',
    category: PHSCategory.safetyCompliance,
    title: 'Is an adequate security arrangement in place?',
    helpText:
        'Assess whether the property has documented security arrangements appropriate to the community and property type.',
    whyItMatters:
        'Defined security procedures can help manage access, incidents, visitors, and common-area safety.',
    impact:
        'Weak or undocumented security arrangements may increase operational and resident-safety risks.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 15,
    weight: 15,
    requiredEvidence: [
      'Security contract',
      'Security procedures',
      'Visitor/access records where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'SAFETY_LIGHTNING',
    category: PHSCategory.safetyCompliance,
    title: 'Is lightning protection installed and maintained where applicable?',
    helpText:
        'Verify the presence and maintenance of applicable lightning protection systems.',
    whyItMatters:
        'Lightning protection can help reduce risks associated with lightning strikes to buildings and infrastructure.',
    impact:
        'Missing or poorly maintained lightning protection may increase exposure to lightning-related damage and safety risks.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 10,
    weight: 10,
    requiredEvidence: [
      'Lightning protection installation details',
      'Inspection records',
      'Maintenance records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  // ===========================================================================
  // COMMUNITY & MAINTENANCE — 10%
  // ===========================================================================

  PHSQuestion(
    id: 'COMMUNITY_ASSOCIATION',
    category: PHSCategory.communityMaintenance,
    title: 'Has the apartment association been formally formed?',
    helpText:
        'Verify whether the apartment owners association or resident welfare association has been formally established.',
    whyItMatters:
        'A formally established association is important for managing common areas, maintenance, contracts, utilities, and community responsibilities.',
    impact:
        'An unformed association can create gaps in maintenance governance and ownership of common responsibilities.',
    priority: QuestionPriority.high,
    potentialPHIGain: 2,
    weight: 20,
    requiredEvidence: [
      'Association registration certificate',
      'Association formation documents',
      'Registered bye-laws',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
    ],
  ),

  PHSQuestion(
    id: 'COMMUNITY_CORPUS',
    category: PHSCategory.communityMaintenance,
    title: 'Is the corpus fund established and documented?',
    helpText:
        'Check whether a corpus or sinking fund has been collected and whether the amount and purpose are documented.',
    whyItMatters:
        'A corpus fund provides financial preparedness for major repairs, replacements, and long-term common-area maintenance.',
    impact:
        'Absence of a documented corpus fund may increase the risk of unexpected maintenance contributions.',
    priority: QuestionPriority.high,
    potentialPHIGain: 2,
    weight: 20,
    requiredEvidence: [
      'Corpus fund statement',
      'Association financial records',
      'Builder handover or collection records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
    ],
  ),

  PHSQuestion(
    id: 'COMMUNITY_AMC',
    category: PHSCategory.communityMaintenance,
    title: 'Are required Annual Maintenance Contracts (AMCs) in place?',
    helpText:
        'Verify whether critical systems and equipment have active maintenance contracts where applicable.',
    whyItMatters:
        'AMCs help ensure critical equipment and infrastructure receive scheduled maintenance and servicing.',
    impact:
        'Missing or expired AMCs can increase equipment downtime, maintenance risk, and unexpected repair costs.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 2,
    weight: 20,
    requiredEvidence: [
      'AMC agreements',
      'AMC validity details',
      'Maintenance schedules',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'COMMUNITY_VENDOR_CONTRACTS',
    category: PHSCategory.communityMaintenance,
    title: 'Are key community vendor contracts documented?',
    helpText:
        'Check whether contracts with important service providers are documented and currently valid.',
    whyItMatters:
        'Clear vendor contracts establish service expectations, responsibilities, pricing, duration, and escalation mechanisms.',
    impact:
        'Undocumented vendor arrangements can create service continuity, accountability, and cost-management risks.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 2,
    weight: 20,
    requiredEvidence: [
      'Vendor contracts',
      'Service agreements',
      'Vendor scope and pricing documents',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'COMMUNITY_COMPLAINTS',
    category: PHSCategory.communityMaintenance,
    title: 'Is there a documented complaint resolution process?',
    helpText:
        'Verify whether residents have a defined process for registering, tracking, escalating, and closing complaints.',
    whyItMatters:
        'A structured complaint process improves accountability and helps ensure resident issues are tracked through resolution.',
    impact:
        'Without a documented process, complaints may be missed, delayed, or difficult to escalate and close.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 2,
    weight: 20,
    requiredEvidence: [
      'Complaint register or tracking system',
      'Complaint resolution process',
      'Escalation mechanism',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  // ===========================================================================
  // DOCUMENTATION — 10%
  // ===========================================================================

  PHSQuestion(
    id: 'DOCUMENTATION_PROPERTY_TAX',
    category: PHSCategory.documentation,
    title: 'Are the property tax records available and up to date?',
    helpText:
        'Verify that the applicable property tax records are available and that the property tax status can be confirmed.',
    whyItMatters:
        'Property tax records provide supporting evidence of municipal tax compliance and help maintain an organized property record.',
    impact:
        'Missing or unclear property tax records can create documentation and administrative gaps.',
    priority: QuestionPriority.high,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Property tax receipt',
      'Latest tax payment record',
      'Property tax assessment details where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'DOCUMENTATION_BESCOM',
    category: PHSCategory.documentation,
    title: 'Are the BESCOM electricity documents available?',
    helpText:
        'Verify that relevant electricity connection, metering, billing, and supporting BESCOM records are available.',
    whyItMatters:
        'Maintaining electricity documentation helps establish the status of the connection and supports future service or ownership-related requirements.',
    impact:
        'Missing electricity documentation can make utility verification and future issue resolution more difficult.',
    priority: QuestionPriority.high,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'BESCOM connection document',
      'Latest electricity bill',
      'Meter details',
      'Relevant correspondence or approvals where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'DOCUMENTATION_BWSSB',
    category: PHSCategory.documentation,
    title: 'Are the BWSSB water and sewerage documents available?',
    helpText:
        'Verify that relevant BWSSB connection, billing, approval, demand, and payment records are available where applicable.',
    whyItMatters:
        'Water and sewerage documentation supports verification of the property infrastructure and ongoing utility arrangements.',
    impact:
        'Missing or incomplete BWSSB records can create utility verification and administrative gaps.',
    priority: QuestionPriority.high,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'BWSSB connection documents',
      'Latest bills or demand records',
      'Payment records where applicable',
      'Relevant approvals or correspondence where applicable',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'DOCUMENTATION_WARRANTY',
    category: PHSCategory.documentation,
    title: 'Are property and equipment warranty documents available?',
    helpText:
        'Verify that applicable builder, equipment, appliance, waterproofing, and system warranty documents are retained.',
    whyItMatters:
        'Warranty records help owners identify coverage periods, responsible parties, and available remedies when defects or failures occur.',
    impact:
        'Missing warranty documentation can make it harder to establish coverage and pursue eligible rectification or service.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Builder warranty documents',
      'Waterproofing warranty',
      'Equipment warranty documents',
      'Warranty terms and validity details',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),

  PHSQuestion(
    id: 'DOCUMENTATION_MANUALS',
    category: PHSCategory.documentation,
    title: 'Are maintenance manuals and relevant property records available?',
    helpText:
        'Verify that applicable operation manuals, maintenance manuals, asset records, handover documents, and service information are retained.',
    whyItMatters:
        'Maintenance manuals and property records help owners and associations operate, maintain, and service building systems correctly.',
    impact:
        'Missing manuals and handover records can increase maintenance dependency, delay troubleshooting, and reduce continuity of property management.',
    priority: QuestionPriority.medium,
    potentialPHIGain: 20,
    weight: 20,
    requiredEvidence: [
      'Operation and maintenance manuals',
      'Asset register where applicable',
      'Handover documentation',
      'Equipment service records',
    ],
    applicableTo: [
      PropertyType.apartment,
      PropertyType.villa,
      PropertyType.independentHouse,
    ],
  ),
];