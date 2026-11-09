
import 'package:flutter/material.dart';

import '../../features/property_submission/services/property_submission_service.dart';
import '../assessment/surebot_screen.dart';

class MyPropertyRequestsScreen extends StatelessWidget {
  final PropertySubmissionStatusGateway? statusGateway;
  final PropertySubmissionApprovalGateway? approvalGateway;

  const MyPropertyRequestsScreen({
    super.key,
    this.statusGateway,
    this.approvalGateway,
  });

  @override
  Widget build(BuildContext context) {
    // Only the status gateway is needed to render the screen.
    final gateway = statusGateway ?? PropertySubmissionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Property Requests'),
      ),
      body: StreamBuilder<List<PropertySubmissionRecord>>(
        stream: gateway.watchMySubmissions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load your property requests. '
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final records = snapshot.data ?? const [];

          if (records.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.apartment_outlined,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No property requests yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When you submit a property for review, '
                      'its status will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, index) =>
                const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = records[index];

              final statusLabel = switch (record.status) {
                'pending_review' => 'Pending review',
                'approved' => 'Approved for use in HomeSureAI',
                'rejected' => 'Not approved',
                'additional_verification' =>
                  'Additional verification required',
                _ => 'Status unavailable',
              };

              final statusIcon = switch (record.status) {
                'pending_review' => Icons.hourglass_top,
                'approved' => Icons.check_circle_outline,
                'rejected' => Icons.info_outline,
                'additional_verification' => Icons.fact_check_outlined,
                _ => Icons.help_outline,
              };

              final statusMessage = switch (record.status) {
                'pending_review' =>
                  'Your request is waiting for HomeSureAI review. '
                      'Assessment is not available yet.',
                'approved' =>
                  'This property has been approved for use in the app. '
                      'This is not a legal or regulatory certification.',
                'rejected' =>
                  'This request was not approved. Please contact '
                      'HomeSureAI for clarification before resubmitting.',
                'additional_verification' =>
                  'We need more information to verify this property. '
                      'Assessment is not available yet.',
                _ =>
                  'Please contact HomeSureAI for help with this request.',
              };

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      if (record.builder.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Builder: ${record.builder}'),
                      ],

                      if (record.locality.isNotEmpty ||
                          record.city.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            record.locality,
                            record.city,
                          ].where((part) => part.isNotEmpty).join(', '),
                        ),
                      ],

                      if (record.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Submitted: '
                          '${record.createdAt!.day.toString().padLeft(2, '0')}/'
                          '${record.createdAt!.month.toString().padLeft(2, '0')}/'
                          '${record.createdAt!.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],

                      const SizedBox(height: 12),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(statusIcon),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text(statusMessage),

                      // Assessment is available only for approved requests.
                      if (record.status == 'approved') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: ValueKey(
                              'start-assessment-${record.id}',
                            ),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Assessment'),
                            onPressed: () async {
                              try {
                                final checker = approvalGateway ??
                                    PropertySubmissionService();

                                // Recheck the current Firestore status
                                // and ownership before opening SureBot.
                                final approved = await checker
                                    .isSubmissionApproved(record.id);

                                if (!context.mounted) return;

                                if (!approved) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'This property is no longer approved '
                                        'for assessment.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => SureBotScreen(
                                      submissionId: record.id,
                                      approvalGateway: checker,
                                    ),
                                  ),
                                );
                              } catch (_) {
                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'We could not verify this property’s '
                                      'approval. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
