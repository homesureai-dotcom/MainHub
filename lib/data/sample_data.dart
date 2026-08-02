import '../models/apartment.dart';
import '../models/compliance_item.dart';
import '../enums/compliance_status.dart';

final List<Apartment> apartments = [

  Apartment(
    projectName: "Casagrand Aquene",
    builder: "Casagrand",
    city: "Bengaluru",

    healthScore: 82,

    rera: true,
    oc: true,
    fireNoc: true,
    bwssb: true,
    bescom: false,
    eKhata: false,
    stp: false,

    priorityTask: "Apply for e-Khata",
    estimatedMinutes: 30,
    complianceItems: [
  const ComplianceItem(
    title: "RERA Registration",
    status: ComplianceStatus.verified,
    weight: 15,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "Occupancy Certificate",
    status: ComplianceStatus.verified,
    weight: 20,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "Fire NOC",
    status: ComplianceStatus.verified,
    weight: 15,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "BWSSB",
    status: ComplianceStatus.verified,
    weight: 10,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "BESCOM",
    status: ComplianceStatus.pending,
    weight: 10,
    recommendation: "Individual BESCOM meter pending.",
  ),
  const ComplianceItem(
    title: "e-Khata",
    status: ComplianceStatus.pending,
    weight: 15,
    recommendation: "Apply through BBMP.",
  ),
  const ComplianceItem(
    title: "STP",
    status: ComplianceStatus.issue,
    weight: 15,
    recommendation: "STP issue reported by residents.",
  ),
],
  ),

  Apartment(
    projectName: "Prestige Lakeside Habitat",
    builder: "Prestige",
    city: "Bengaluru",

    healthScore: 95,

    rera: true,
    oc: true,
    fireNoc: true,
    bwssb: true,
    bescom: true,
    eKhata: true,
    stp: true,

    priorityTask: "No Pending Tasks",
    estimatedMinutes: 0,
    complianceItems: [
  const ComplianceItem(
    title: "RERA Registration",
    status: ComplianceStatus.verified,
    weight: 15,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "Occupancy Certificate",
    status: ComplianceStatus.verified,
    weight: 20,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "Fire NOC",
    status: ComplianceStatus.verified,
    weight: 15,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "BWSSB",
    status: ComplianceStatus.verified,
    weight: 10,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "BESCOM",
    status: ComplianceStatus.pending,
    weight: 10,
    recommendation: "Individual BESCOM meter pending.",
  ),
  const ComplianceItem(
    title: "e-Khata",
    status: ComplianceStatus.pending,
    weight: 15,
    recommendation: "Apply through BBMP.",
  ),
  const ComplianceItem(
    title: "STP",
    status: ComplianceStatus.issue,
    weight: 15,
    recommendation: "STP issue reported by residents.",
  ),
],
  ),

  Apartment(
    projectName: "Sobha Dream Acres",
    builder: "Sobha",
    city: "Bengaluru",

    healthScore: 90,

    rera: true,
    oc: true,
    fireNoc: true,
    bwssb: true,
    bescom: true,
    eKhata: false,
    stp: true,

    priorityTask: "Apply for e-Khata",
    estimatedMinutes: 20,
    complianceItems: [
  const ComplianceItem(
    title: "RERA Registration",
    status: ComplianceStatus.verified,
    weight: 15,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "Occupancy Certificate",
    status: ComplianceStatus.verified,
    weight: 20,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "Fire NOC",
    status: ComplianceStatus.verified,
    weight: 15,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "BWSSB",
    status: ComplianceStatus.verified,
    weight: 10,
    recommendation: "",
  ),
  const ComplianceItem(
    title: "BESCOM",
    status: ComplianceStatus.pending,
    weight: 10,
    recommendation: "Individual BESCOM meter pending.",
  ),
  const ComplianceItem(
    title: "e-Khata",
    status: ComplianceStatus.pending,
    weight: 15,
    recommendation: "Apply through BBMP.",
  ),
  const ComplianceItem(
    title: "STP",
    status: ComplianceStatus.issue,
    weight: 15,
    recommendation: "STP issue reported by residents.",
  ),
],
  ),

];