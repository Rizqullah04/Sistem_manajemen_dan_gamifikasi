import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.title,
    required this.organizer,
    required this.date,
    required this.status,
    required this.points,
    super.key,
  });

  final String title;
  final String organizer;
  final String date;
  final String status;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 212,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1733),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(organizer, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: status == 'Approved' ? Colors.green.withValues(alpha: 0.18) : Colors.orange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(status, style: TextStyle(color: status == 'Approved' ? Colors.greenAccent : Colors.orangeAccent)),
              ),
              Text('+$points PTS', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
