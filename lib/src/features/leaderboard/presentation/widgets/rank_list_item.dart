import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

class RankListItem extends StatelessWidget {
  final UserModel user;
  final bool isCurrent;

  const RankListItem({super.key, required this.user, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    final movement = user.movement;
    final accentColor = movement == RankMovement.up
        ? Colors.greenAccent
        : movement == RankMovement.down
            ? Colors.redAccent
            : const Color(0xFF6C4AB6);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: movement == RankMovement.up ? 20 : movement == RankMovement.down ? -20 : 0, end: 0),
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutQuad,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: isCurrent ? Border.all(color: const Color(0xFF6C4AB6), width: 1.2) : null,
          boxShadow: [
            if (isCurrent)
              BoxShadow(
                color: const Color(0xFF6C4AB6).withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              alignment: Alignment.center,
              child: Text(
                '#${user.rank}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[900],
              child: Text(
                _initials(user.name),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (movement != RankMovement.stable)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                movement == RankMovement.up ? Icons.arrow_upward : Icons.arrow_downward,
                                color: accentColor,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                movement == RankMovement.up ? 'Up' : 'Down',
                                style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.ormawa,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_formatPoints(user.points)} PTS',
              style: TextStyle(
                color: const Color(0xFF6C4AB6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _initials(String name) {
    if (name.isEmpty) {
      return '?';
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
