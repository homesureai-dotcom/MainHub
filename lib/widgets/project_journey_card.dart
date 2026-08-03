import 'package:flutter/material.dart';

import '../models/apartment.dart';
import '../models/timeline_event.dart';

class ProjectJourneyCard extends StatelessWidget {
  final Apartment apartment;

  const ProjectJourneyCard({
    super.key,
    required this.apartment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: Colors.deepPurple,
                ),
                SizedBox(width: 10),
                Text(
                  "Project Journey",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            ...apartment.timeline.map(
              (event) => TimelineTile(event: event),
            ),
          ],
        ),
      ),
    );
  }
}

class TimelineTile extends StatelessWidget {
  final TimelineEvent event;

  const TimelineTile({
    super.key,
    required this.event,
  });

  Color get color {
    switch (event.status) {
      case TimelineStatus.completed:
        return Colors.green;

      case TimelineStatus.ongoing:
        return Colors.orange;

      case TimelineStatus.pending:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (event.status) {
      case TimelineStatus.completed:
        return Icons.check_circle;

      case TimelineStatus.ongoing:
        return Icons.timelapse;

      case TimelineStatus.pending:
        return Icons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Column(
            children: [

              Icon(
                icon,
                color: color,
              ),

              Container(
                width: 2,
                height: 55,
                color: Colors.grey.shade300,
              ),
            ],
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  event.date,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(event.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}