
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/community_membership.dart';
import '../models/membership_request.dart';
import '../services/network_service.dart';

class NetworkHomeScreen extends StatefulWidget {
  const NetworkHomeScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
    this.networkService,
  });

  final String propertyId;
  final String propertyName;
  final NetworkService? networkService;

  @override
  State<NetworkHomeScreen> createState() => _NetworkHomeScreenState();
}

class _NetworkHomeScreenState extends State<NetworkHomeScreen> {
  late final NetworkService _service;

  CommunityRelationship _relationship = CommunityRelationship.owner;

  final TextEditingController _messageController =
      TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.networkService ?? NetworkService();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_submitting) return;

    setState(() => _submitting = true);

    try {
      await _service.submitMembershipRequest(
        propertyId: widget.propertyId,
        relationship: _relationship,
        displayName: FirebaseAuth.instance.currentUser?.displayName,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Membership request submitted for review.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Residents Welfare'),
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (authSnapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to verify your sign-in status. Please try again.',
              ),
            );
          }

          final user = authSnapshot.data;

          if (user == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Please sign in to access Residents Welfare.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return _buildMembershipStream();
        },
      ),
    );
  }

  Widget _buildMembershipStream() {
    return StreamBuilder<CommunityMembership?>(
      stream: _service.watchMyMembership(widget.propertyId),
      builder: (context, membershipSnapshot) {
        if (membershipSnapshot.hasError) {
          return const Center(
            child: Text(
              'Unable to load your community membership.',
            ),
          );
        }

        if (membershipSnapshot.connectionState ==
                ConnectionState.waiting &&
            !membershipSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final membership = membershipSnapshot.data;

        if (membership?.status ==
            CommunityMembershipStatus.approved) {
          return _approvedPlaceholder();
        }

        return StreamBuilder<MembershipRequest?>(
          stream: _service.watchMyRequest(widget.propertyId),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return const Center(
                child: Text(
                  'Unable to load your membership request.',
                ),
              );
            }

            if (requestSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !requestSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return _membershipPanel(requestSnapshot.data);
          },
        );
      },
    );
  }

  Widget _membershipPanel(MembershipRequest? request) {
    final status =
        request?.status ?? CommunityMembershipStatus.notRequested;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.propertyName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Access community updates, association services and '
          'apartment-related information in one place.',
        ),
        const SizedBox(height: 24),

        if (status == CommunityMembershipStatus.pending) ...[
          const Icon(
            Icons.hourglass_top,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your request is awaiting administrator approval.',
            textAlign: TextAlign.center,
          ),
        ] else if (status ==
            CommunityMembershipStatus.rejected) ...[
          const Text(
            'Your previous request was not approved. '
            'You may submit a new request if your details have changed.',
          ),
          const SizedBox(height: 16),
          _requestForm(),
        ] else if (status ==
            CommunityMembershipStatus.suspended) ...[
          const Text(
            'Your community access is currently suspended. '
            'Please contact the community administrator.',
          ),
        ] else if (status == CommunityMembershipStatus.left) ...[
          const Text(
            'You have left this community. '
            'You may request to join again.',
          ),
          const SizedBox(height: 16),
          _requestForm(),
        ] else ...[
          _requestForm(),
        ],
      ],
    );
  }

  Widget _requestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Your relationship to this property',
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<CommunityRelationship>(
          initialValue: _relationship,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: CommunityRelationship.values
              .map(
                (relationship) => DropdownMenuItem(
                  value: relationship,
                  child: Text(
                    switch (relationship) {
                      CommunityRelationship.owner => 'Owner',
                      CommunityRelationship.tenant => 'Tenant',
                      CommunityRelationship.familyMember =>
                        'Family member',
                    },
                  ),
                ),
              )
              .toList(),
          onChanged: _submitting
              ? null
              : (value) {
                  if (value != null) {
                    setState(() => _relationship = value);
                  }
                },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 300,
          enabled: !_submitting,
          decoration: const InputDecoration(
            labelText: 'Additional information (optional)',
            hintText:
                'For example, apartment/unit details for the reviewer',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _submitting ? null : _submitRequest,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Request to join'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your request will be reviewed by an authorised community '
          'administrator. Do not enter sensitive identity or financial '
          'details.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _approvedPlaceholder() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          widget.propertyName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text(
          'You are an approved member of this community.',
        ),
        const SizedBox(height: 20),
        const Card(
          child: ListTile(
            leading: Icon(Icons.forum_outlined),
            title: Text('Community discussions'),
            subtitle: Text(
              'Community conversations will appear here.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.task_alt),
            title: Text('Complaints and maintenance'),
            subtitle: Text(
              'Track shared property issues and progress.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.campaign_outlined),
            title: Text('Notices and announcements'),
            subtitle: Text(
              'Important association updates will appear here.',
            ),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.folder_outlined),
            title: Text('Documents and compliance'),
            subtitle: Text(
              'Community-approved documents will appear here.',
            ),
          ),
        ),
      ],
    );
  }
}
