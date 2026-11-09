
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PropertySubmissionRecord {
  const PropertySubmissionRecord({
    required this.id,
    required this.name,
    required this.builder,
    required this.locality,
    required this.city,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String name;
  final String builder;
  final String locality;
  final String city;
  final String status;
  final DateTime? createdAt;

  factory PropertySubmissionRecord.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['createdAt'];

    return PropertySubmissionRecord(
      id: id,
      name: data['name'] as String? ?? 'Unnamed property',
      builder: data['builder'] as String? ?? '',
      locality: data['locality'] as String? ?? '',
      city: data['city'] as String? ?? '',
      status: data['status'] as String? ?? 'unknown',
      createdAt: timestamp is Timestamp
          ? timestamp.toDate().toLocal()
          : null,
    );
  }
}

abstract interface class PropertySubmissionGateway {
  Future<String> submitProperty({
    required String name,
    required String builder,
    required String locality,
    required String city,
    required String reraNumber,
  });
}

abstract interface class PropertySubmissionStatusGateway {
  Stream<List<PropertySubmissionRecord>> watchMySubmissions();
}

/// Checks whether a user's own submission is approved for app use.
abstract interface class PropertySubmissionApprovalGateway {
  Future<bool> isSubmissionApproved(String submissionId);
}

class PropertySubmissionService
    implements
        PropertySubmissionGateway,
        PropertySubmissionStatusGateway,
        PropertySubmissionApprovalGateway {
  PropertySubmissionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _submissions =>
      _firestore.collection('property_submissions');

  @override
  Future<String> submitProperty({
    required String name,
    required String builder,
    required String locality,
    required String city,
    required String reraNumber,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in before submitting a property.');
    }

    final cleanedName = name.trim();
    final cleanedBuilder = builder.trim();
    final cleanedLocality = locality.trim();
    final cleanedCity = city.trim();
    final cleanedRera = reraNumber.trim();

    if (cleanedName.isEmpty) {
      throw ArgumentError('Project name is required.');
    }
    if (cleanedLocality.isEmpty) {
      throw ArgumentError('Locality is required.');
    }
    if (cleanedCity.isEmpty) {
      throw ArgumentError('City is required.');
    }

    final document = await _submissions.add({
      'name': cleanedName,
      'builder': cleanedBuilder,
      'locality': cleanedLocality,
      'city': cleanedCity,
      'reraNumber': cleanedRera,
      'submittedBy': user.uid,
      'status': 'pending_review',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  @override
  Stream<List<PropertySubmissionRecord>> watchMySubmissions() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Please sign in to view your submissions.');
    }

    return _submissions
        .where('submittedBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => PropertySubmissionRecord.fromMap(
                  document.id,
                  document.data(),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<bool> isSubmissionApproved(String submissionId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in before starting an assessment.');
    }

    final cleanedId = submissionId.trim();
    if (cleanedId.isEmpty) {
      return false;
    }

    // Read the specific Firestore document again immediately before
    // assessment entry. Firestore rules must restrict this read to its owner.
    final snapshot = await _submissions.doc(cleanedId).get();

    if (!snapshot.exists) {
      return false;
    }

    final data = snapshot.data();
    if (data == null) {
      return false;
    }

    // Do not rely only on the status. Confirm that this is the signed-in
    // user's submission.
    if (data['submittedBy'] != user.uid) {
      return false;
    }

    // Approval means approved for use in HomeSureAI, not legal certification.
    return data['status'] == 'approved';
  }
}
