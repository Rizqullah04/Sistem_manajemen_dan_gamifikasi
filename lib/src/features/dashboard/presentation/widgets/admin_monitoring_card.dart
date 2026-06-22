import 'package:flutter/material.dart';

class AdminMonitoringCard extends StatelessWidget {
  const AdminMonitoringCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Monitoring',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMonitoringItem(
              context,
              icon: Icons.groups_2_outlined,
              title: 'Statistik semua Ormawa',
              subtitle: 'Lihat data statistik dari semua organisasi',
            ),
            const Divider(height: 16),
            _buildMonitoringItem(
              context,
              icon: Icons.forum_outlined,
              title: 'Monitoring diskusi kegiatan',
              subtitle: 'Pantau diskusi dalam setiap kegiatan',
            ),
            const Divider(height: 16),
            _buildMonitoringItem(
              context,
              icon: Icons.how_to_vote_outlined,
              title: 'Monitoring voting digital',
              subtitle: 'Pantau aktivitas voting yang sedang berlangsung',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}
