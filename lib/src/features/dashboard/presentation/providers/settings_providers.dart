import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardSettings {
  const DashboardSettings({
    required this.notificationsEnabled,
    required this.discussionNotificationsEnabled,
    required this.compactDashboardEnabled,
    required this.language,
  });

  final bool notificationsEnabled;
  final bool discussionNotificationsEnabled;
  final bool compactDashboardEnabled;
  final String language;

  DashboardSettings copyWith({
    bool? notificationsEnabled,
    bool? discussionNotificationsEnabled,
    bool? compactDashboardEnabled,
    String? language,
  }) {
    return DashboardSettings(
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      discussionNotificationsEnabled:
          discussionNotificationsEnabled ??
          this.discussionNotificationsEnabled,
      compactDashboardEnabled:
          compactDashboardEnabled ?? this.compactDashboardEnabled,
      language: language ?? this.language,
    );
  }
}

class DashboardSettingsController
    extends StateNotifier<AsyncValue<DashboardSettings>> {
  DashboardSettingsController() : super(const AsyncValue.loading()) {
    load();
  }

  static const _notificationsKey = 'dashboard_notifications_enabled';
  static const _discussionNotificationsKey =
      'dashboard_discussion_notifications_enabled';
  static const _compactDashboardKey = 'dashboard_compact_enabled';
  static const _languageKey = 'dashboard_language';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AsyncValue.data(
      DashboardSettings(
        notificationsEnabled: prefs.getBool(_notificationsKey) ?? true,
        discussionNotificationsEnabled:
            prefs.getBool(_discussionNotificationsKey) ?? true,
        compactDashboardEnabled: prefs.getBool(_compactDashboardKey) ?? false,
        language: prefs.getString(_languageKey) ?? 'Indonesia',
      ),
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _update((settings) => settings.copyWith(
          notificationsEnabled: value,
          discussionNotificationsEnabled:
              value ? settings.discussionNotificationsEnabled : false,
        ));
  }

  Future<void> setDiscussionNotificationsEnabled(bool value) async {
    await _update(
      (settings) => settings.copyWith(discussionNotificationsEnabled: value),
    );
  }

  Future<void> setCompactDashboardEnabled(bool value) async {
    await _update(
      (settings) => settings.copyWith(compactDashboardEnabled: value),
    );
  }

  Future<void> setLanguage(String value) async {
    await _update((settings) => settings.copyWith(language: value));
  }

  Future<void> _update(
    DashboardSettings Function(DashboardSettings settings) update,
  ) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final next = update(current);
    state = AsyncValue.data(next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, next.notificationsEnabled);
    await prefs.setBool(
      _discussionNotificationsKey,
      next.discussionNotificationsEnabled,
    );
    await prefs.setBool(_compactDashboardKey, next.compactDashboardEnabled);
    await prefs.setString(_languageKey, next.language);
  }
}

final dashboardSettingsProvider = StateNotifierProvider<
    DashboardSettingsController, AsyncValue<DashboardSettings>>((ref) {
  return DashboardSettingsController();
});
