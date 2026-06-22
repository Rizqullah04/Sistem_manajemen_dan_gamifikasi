import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/domain/entities/period_status.dart';
import 'package:sistem_manajemen_dan_gamifikasi/src/features/dashboard/presentation/providers/dashboard_providers.dart';

class PeriodResetCard extends ConsumerWidget {
  const PeriodResetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodAsync = ref.watch(periodStatusProvider);
    final resetState = ref.watch(periodResetControllerProvider);

    ref.listen(periodResetControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Periode ${result.archivedPeriod.name} ditutup. '
                'Poin periode ${result.activePeriod.name} dimulai dari 0.',
              ),
            ),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: periodAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _PeriodError(
            message: error.toString(),
            onRetry: () => ref.invalidate(periodStatusProvider),
          ),
          data: (status) => _PeriodContent(
            status: status,
            isLoading: resetState.isLoading,
            onReset: () => _confirmReset(context, ref, status.activePeriod),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    DashboardPeriod activePeriod,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Akhiri periode?'),
          content: Text(
            'Data poin dan ranking periode ${activePeriod.name} akan disimpan, '
            'lalu poin anggota dan Ormawa di periode baru akan direset menjadi 0.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Akhiri & Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await ref.read(periodResetControllerProvider.notifier).endCurrentPeriod();
  }
}

class _PeriodContent extends StatelessWidget {
  const _PeriodContent({
    required this.status,
    required this.isLoading,
    required this.onReset,
  });

  final PeriodStatus status;
  final bool isLoading;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final active = status.activePeriod;
    final archivedCount = status.archivedPeriods.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event_repeat_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Manajemen Periode',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoRow(label: 'Periode aktif', value: active.name),
        _InfoRow(label: 'Rentang', value: _periodRange(active)),
        _InfoRow(label: 'Riwayat periode', value: '$archivedCount tersimpan'),
        const SizedBox(height: 12),
        Text(
          'Saat periode diakhiri, snapshot ranking dan poin disimpan sebagai arsip. Badge lama tetap tercatat, sementara poin periode baru dimulai lagi dari 0.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isLoading ? null : onReset,
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.restart_alt_rounded),
            label: Text(isLoading ? 'Memproses...' : 'Akhiri Periode & Reset Poin'),
          ),
        ),
      ],
    );
  }

  String _periodRange(DashboardPeriod period) {
    final formatter = DateFormat('dd MMM yyyy');
    final start = period.startsOn == null ? '-' : formatter.format(period.startsOn!);
    final end = period.endsOn == null ? '-' : formatter.format(period.endsOn!);

    return '$start - $end';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PeriodError extends StatelessWidget {
  const _PeriodError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gagal memuat periode',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Coba lagi'),
        ),
      ],
    );
  }
}
