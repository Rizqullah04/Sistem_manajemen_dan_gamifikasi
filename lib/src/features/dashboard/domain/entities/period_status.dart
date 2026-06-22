class DashboardPeriod {
  const DashboardPeriod({
    required this.id,
    required this.year,
    required this.name,
    required this.status,
    this.startsOn,
    this.endsOn,
  });

  final int id;
  final int year;
  final String name;
  final String status;
  final DateTime? startsOn;
  final DateTime? endsOn;

  factory DashboardPeriod.fromJson(Map<String, dynamic> json) {
    return DashboardPeriod(
      id: int.tryParse(json['id_period']?.toString() ?? '0') ?? 0,
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '-',
      status: json['status']?.toString() ?? '-',
      startsOn: DateTime.tryParse(json['starts_on']?.toString() ?? ''),
      endsOn: DateTime.tryParse(json['ends_on']?.toString() ?? ''),
    );
  }
}

class PeriodStatus {
  const PeriodStatus({
    required this.activePeriod,
    required this.archivedPeriods,
  });

  final DashboardPeriod activePeriod;
  final List<DashboardPeriod> archivedPeriods;

  factory PeriodStatus.fromJson(Map<String, dynamic> json) {
    final archived = json['archived_periods'];

    return PeriodStatus(
      activePeriod: DashboardPeriod.fromJson(
        (json['active_period'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      archivedPeriods: archived is List
          ? archived
              .whereType<Map>()
              .map((item) => DashboardPeriod.fromJson(item.cast<String, dynamic>()))
              .toList()
          : const <DashboardPeriod>[],
    );
  }
}

class PeriodResetResult {
  const PeriodResetResult({
    required this.archivedPeriod,
    required this.activePeriod,
    required this.userSnapshotCount,
    required this.ormawaSnapshotCount,
  });

  final DashboardPeriod archivedPeriod;
  final DashboardPeriod activePeriod;
  final int userSnapshotCount;
  final int ormawaSnapshotCount;

  factory PeriodResetResult.fromJson(Map<String, dynamic> json) {
    final snapshot = (json['snapshot'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    return PeriodResetResult(
      archivedPeriod: DashboardPeriod.fromJson(
        (json['archived_period'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      activePeriod: DashboardPeriod.fromJson(
        (json['active_period'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      userSnapshotCount:
          int.tryParse(snapshot['users']?.toString() ?? '0') ?? 0,
      ormawaSnapshotCount:
          int.tryParse(snapshot['ormawas']?.toString() ?? '0') ?? 0,
    );
  }
}
