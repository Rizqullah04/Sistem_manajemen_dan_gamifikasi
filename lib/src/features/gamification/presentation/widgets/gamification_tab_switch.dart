import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/gamification_provider.dart';

class GamificationTabSwitch extends ConsumerWidget {
  const GamificationTabSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeType = ref.watch(leaderboardTypeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF15122B),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: LeaderboardType.values.map((type) {
          final isSelected = activeType == type;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6C4AB6) : Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () => ref.read(leaderboardTypeProvider.notifier).state = type,
                  child: Center(
                    child: Text(
                      _getTabLabel(type),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTabLabel(LeaderboardType type) {
    return type == LeaderboardType.individu ? 'Individu' : 'Ormawa';
  }
}
