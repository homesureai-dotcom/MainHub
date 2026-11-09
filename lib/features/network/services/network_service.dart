
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/community_membership.dart';
import '../models/membership_request.dart';

class NetworkService {
  NetworkService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'You must be signed in to use HomeSureAI Network.',
      );
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _communityCollection(
    String propertyId,
    String collectionName,
  ) {
    return _firestore
        .collection('properties')
        .doc(propertyId)
        .collection('community')
        .doc('main')
        .collection(collectionName);
  }

  DocumentReference<Map<String, dynamic>> _requestRef(
    String propertyId,
  ) {
    return _communityCollection(
      propertyId,
      'membership_requests',
    ).doc(_uid);
  }

  DocumentReference<Map<String, dynamic>> _memberRef(
    String propertyId,
  ) {
    return _communityCollection(
      propertyId,
      'members',
    ).doc(_uid);
  }

  Stream<MembershipRequest?> watchMyRequest(String propertyId) {
    return _requestRef(propertyId).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return MembershipRequest.fromMap(data);
    });
  }

  Stream<CommunityMembership?> watchMyMembership(String propertyId) {
    return _memberRef(propertyId).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return CommunityMembership.fromMap(data);
    });
  }

  /// Submits or resubmits a membership request.
  ///
  /// This method never approves membership. Approval must be handled
  /// by trusted server-side administrative code.
  Future<void> submitMembershipRequest({
    required String propertyId,
    required CommunityRelationship relationship,
    String? displayName,
    String? message,
  }) async {
    final uid = _uid;

    if (propertyId.trim().isEmpty) {
      throw ArgumentError('Property ID cannot be empty.');
    }

    final cleanName = displayName?.trim();
    final cleanMessage = message?.trim();

    if (cleanName != null && cleanName.length > 100) {
      throw ArgumentError(
        'Display name cannot exceed 100 characters.',
      );
    }

    if (cleanMessage != null && cleanMessage.length > 300) {
      throw ArgumentError(
        'Message cannot exceed 300 characters.',
      );
    }

    final requestRef = _requestRef(propertyId);
    final memberRef = _memberRef(propertyId);

    await _firestore.runTransaction((transaction) async {
      final memberSnapshot = await transaction.get(memberRef);

      if (memberSnapshot.exists &&
          memberSnapshot.data()?['status'] == 'approved') {
        throw StateError(
          'You are already a member of this community.',
        );
      }

      final requestSnapshot = await transaction.get(requestRef);

      if (requestSnapshot.exists) {
        final existingStatus =
            requestSnapshot.data()?['status'];

        if (existingStatus == 'pending') {
          throw StateError(
            'Your membership request is already awaiting review.',
          );
        }

        if (existingStatus != 'rejected' &&
            existingStatus != 'left') {
          throw StateError(
            'Your existing membership request must be reviewed '
            'before another request can be submitted.',
          );
        }
      }

      final request = MembershipRequest(
        userId: uid,
        propertyId: propertyId,
        relationship: relationship,
        status: CommunityMembershipStatus.pending,
        requestedAt: Timestamp.now(),
        displayName:
            cleanName == null || cleanName.isEmpty ? null : cleanName,
        message: cleanMessage == null || cleanMessage.isEmpty
            ? null
            : cleanMessage,
      );

      final data = request.toFirestore();

      // Firestore rules validate this server timestamp against request.time.
      data['requestedAt'] = FieldValue.serverTimestamp();

      transaction.set(requestRef, data);
    });
  }
}
