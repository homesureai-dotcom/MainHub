import '../models/apartment.dart';

class PropertyAdvisorService {
  static List<String> strengths(Apartment apartment) {
    List<String> items = [];

    if (apartment.rera) {
      items.add("RERA registration is verified.");
    }

    if (apartment.oc) {
      items.add("Occupancy Certificate is available.");
    }

    if (apartment.fireNoc) {
      items.add("Fire NOC has been obtained.");
    }

    if (apartment.bwssb) {
      items.add("BWSSB connection is available.");
    }

    return items;
  }

  static List<String> warnings(Apartment apartment) {
    List<String> items = [];

    if (!apartment.eKhata) {
      items.add("e-Khata is pending.");
    }

    if (!apartment.bescom) {
      items.add("Individual BESCOM meter is pending.");
    }

    if (!apartment.stp) {
      items.add("STP requires further verification.");
    }

    return items;
  }

  static String recommendation(Apartment apartment) {
    if (!apartment.eKhata ||
        !apartment.bescom ||
        !apartment.stp) {
      return "Proceed only after verifying the pending compliance items.";
    }

    return "This project appears to have strong compliance and is suitable for further evaluation.";
  }

  static String confidence(Apartment apartment) {
    if (apartment.healthScore >= 90) {
      return "Very High";
    }

    if (apartment.healthScore >= 80) {
      return "High";
    }

    if (apartment.healthScore >= 70) {
      return "Medium";
    }

    return "Low";
  }
}