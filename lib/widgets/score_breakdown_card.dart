import 'package:flutter/material.dart';

class ScoreBreakdownCard extends StatelessWidget {
  const ScoreBreakdownCard({super.key});

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
          children: const [

            Text(
              "Health Score Breakdown",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            ScoreRow(
              title: "RERA Registration",
              points: "+15",
              color: Colors.green,
            ),

            ScoreRow(
              title: "Occupancy Certificate",
              points: "+20",
              color: Colors.green,
            ),

            ScoreRow(
              title: "Fire NOC",
              points: "+15",
              color: Colors.green,
            ),

            ScoreRow(
              title: "BWSSB",
              points: "+10",
              color: Colors.green,
            ),

            ScoreRow(
              title: "BESCOM",
              points: "+5",
              color: Colors.orange,
            ),

            ScoreRow(
              title: "e-Khata",
              points: "+7",
              color: Colors.orange,
            ),

            ScoreRow(
              title: "STP",
              points: "0",
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreRow extends StatelessWidget {
  final String title;
  final String points;
  final Color color;

  const ScoreRow({
    super.key,
    required this.title,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [

          Icon(
            Icons.circle,
            size: 12,
            color: color,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17),
            ),
          ),

          Text(
            points,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          )
        ],
      ),
    );
  }
}