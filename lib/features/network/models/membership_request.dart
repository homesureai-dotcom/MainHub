import 'package:cloud_firestore/cloud_firestore.dart';

import 'community_membership.dart';

class MembershipRequest {
  const MembershipRequest({
    required this.userId,
    required this.propertyId,
    required this.relationship,
    required this.status,
    required this.requestedAt,
    this.displayName,
    this.message,
  });

  final String userId;
  final String propertyId;
  final CommunityRelationship relationship;
  final CommunityMembershipStatus status;
  final Timestamp requestedAt;
  final String? displayName;
  final String? message;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'propertyId': propertyId,
        'relationship': relationship.name,
        'status': status.name,
        'requestedAt': requestedAt,
        'displayName': displayName,
        'message': message,
      };

  factory MembershipRequest.fromMap(Map<String, dynamic> data) {
    return MembershipRequest(
      userId: data['userId'] as String? ?? '',
      propertyId: data['propertyId'] as String? ?? '',
      relationship: CommunityRelationship.fromValue(data['relationship']),
      status: CommunityMembershipStatus.fromValue(data['status']),
      requestedAt: data['requestedAt'] as Timestamp? ?? Timestamp.now(),
      displayName: data['displayName'] as String?,
      message: data['message'] as String?,
    );
  }
}
