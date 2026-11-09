import 'package:cloud_firestore/cloud_firestore.dart';

enum CommunityMembershipStatus {
  notRequested,
  pending,
  approved,
  rejected,
  suspended,
  left;

  static CommunityMembershipStatus fromValue(Object? value) {
    return CommunityMembershipStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CommunityMembershipStatus.notRequested,
    );
  }
}

enum CommunityRelationship {
  owner,
  tenant,
  familyMember;

  static CommunityRelationship fromValue(Object? value) {
    return CommunityRelationship.values.firstWhere(
      (relationship) => relationship.name == value,
      orElse: () => CommunityRelationship.owner,
    );
  }
}

class CommunityMembership {
  const CommunityMembership({
    required this.userId,
    required this.propertyId,
    required this.status,
    required this.relationship,
    required this.requestedAt,
    this.displayName,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
    this.role = 'member',
  });

  final String userId;
  final String propertyId;
  final CommunityMembershipStatus status;
  final CommunityRelationship relationship;
  final Timestamp requestedAt;
  final String? displayName;
  final Timestamp? reviewedAt;
  final String? reviewedBy;
  final String? reviewNote;
  final String role;

  factory CommunityMembership.fromMap(Map<String, dynamic> data) {
    return CommunityMembership(
      userId: data['userId'] as String? ?? '',
      propertyId: data['propertyId'] as String? ?? '',
      status: CommunityMembershipStatus.fromValue(data['status']),
      relationship: CommunityRelationship.fromValue(data['relationship']),
      requestedAt: data['requestedAt'] as Timestamp? ?? Timestamp.now(),
      displayName: data['displayName'] as String?,
      reviewedAt: data['reviewedAt'] as Timestamp?,
      reviewedBy: data['reviewedBy'] as String?,
      reviewNote: data['reviewNote'] as String?,
      role: data['role'] as String? ?? 'member',
    );
  }
}
