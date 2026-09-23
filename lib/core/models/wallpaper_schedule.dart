/// One wallpaper update time, repeated on the selected weekdays.
///
/// Weekdays use [DateTime.weekday]: Monday is 1 and Sunday is 7.
/// The persisted schedule is the source of truth. WorkManager only runs the
/// next occurrence, and that run is inexact.
class WallpaperSchedule {
  const WallpaperSchedule({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
  });

  static const defaultHour = 5;
  static const defaultMinute = 0;

  static const everyDay = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  };

  static const weekdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  static const weekends = <int>{DateTime.saturday, DateTime.sunday};

  /// Sunday-first order used by the day picker and the summary text.
  static const displayOrder = <int>[
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  static const initial = WallpaperSchedule(
    enabled: false,
    hour: defaultHour,
    minute: defaultMinute,
    daysOfWeek: everyDay,
  );

  final bool enabled;
  final int hour;
  final int minute;
  final Set<int> daysOfWeek;

  WallpaperSchedule copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    Set<int>? daysOfWeek,
  }) {
    return WallpaperSchedule(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  /// Enabled schedules need a real time of day and at least one weekday.
  String? get validationError {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return 'Choose a valid time.';
    }
    if (enabled && daysOfWeek.isEmpty) {
      return 'Select at least one day.';
    }
    return null;
  }

  static String shortLabel(int weekday) {
    switch (weekday) {
      case DateTime.sunday:
        return 'S';
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
      case DateTime.thursday:
        return 'T';
      case DateTime.wednesday:
        return 'W';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'S';
      default:
        return '';
    }
  }

  static String fullName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  /// Summary of the selected weekdays, based on the days themselves.
  static String describeDays(Set<int> days) {
    final selected = days.where(everyDay.contains).toSet();
    if (selected.isEmpty) return 'No days selected';
    if (_sameDays(selected, everyDay)) return 'Every day';
    if (_sameDays(selected, weekdays)) return 'Weekdays';
    if (_sameDays(selected, weekends)) return 'Weekends';

    final names = displayOrder
        .where(selected.contains)
        .map(fullName)
        .toList(growable: false);
    if (names.length == 1) return 'Every ${names.single}';
    if (names.length == 2) return '${names[0]} and ${names[1]}';
    return '${names.sublist(0, names.length - 1).join(', ')}, and ${names.last}';
  }

  static bool _sameDays(Set<int> a, Set<int> b) {
    return a.length == b.length && a.containsAll(b);
  }
}

/// Next civil occurrence of [hour]:[minute] on [daysOfWeek].
///
/// Candidates are built with the local [DateTime] calendar constructor, then
/// converted to a delay with [DateTime.difference]. That follows clock-time
/// and daylight-saving rules for the device timezone instead of assuming
/// every day is exactly 24 hours.
class ScheduleCalculator {
  static const sameMinuteGrace = Duration(minutes: 3);
  static const graceRunDelay = Duration(seconds: 20);

  static DateTime? nextOccurrence({
    required DateTime now,
    required int hour,
    required int minute,
    required Set<int> daysOfWeek,
    bool allowSameMinuteGrace = false,
  }) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final days = daysOfWeek.where(WallpaperSchedule.everyDay.contains).toSet();
    if (days.isEmpty) return null;

    if (allowSameMinuteGrace && days.contains(now.weekday)) {
      final todayAt = DateTime(now.year, now.month, now.day, hour, minute);
      if (!todayAt.isAfter(now)) {
        final overdue = now.difference(todayAt);
        if (overdue < sameMinuteGrace) {
          return now.add(graceRunDelay);
        }
      }
    }

    for (var offset = 0; offset <= DateTime.daysPerWeek; offset++) {
      final candidate = DateTime(
        now.year,
        now.month,
        now.day + offset,
        hour,
        minute,
      );
      if (!days.contains(candidate.weekday)) continue;
      if (candidate.isAfter(now)) return candidate;
    }
    return null;
  }

  /// User-facing timing copy. Does not promise an exact minute.
  static String describeUpcoming(DateTime now, DateTime target) {
    final delay = target.difference(now);
    if (delay.inMinutes < 1) {
      return 'Next run in about a minute. Android may delay it slightly.';
    }
    if (delay.inHours < 1) {
      final minutes = delay.inMinutes;
      final unit = minutes == 1 ? 'minute' : 'minutes';
      return 'Next run in about $minutes $unit. Android may delay it.';
    }
    if (delay.inHours < 12) {
      final hours = delay.inHours;
      final unit = hours == 1 ? 'hour' : 'hours';
      return 'Next run in about $hours $unit. Android may delay it.';
    }
    final hh = target.hour.toString().padLeft(2, '0');
    final mm = target.minute.toString().padLeft(2, '0');
    final day = WallpaperSchedule.fullName(target.weekday);
    return 'Next run $day around $hh:$mm. Android may delay it.';
  }
}

/// What to do with the single wallpaper WorkManager job.
enum ScheduleWorkAction { keepExisting, replace, cancel }

/// Decides whether the saved schedule needs a new WorkManager registration.
///
/// Opening the app must not enqueue a second job for the same occurrence.
/// Replacing is reserved for a real schedule, clock, or timezone change, or
/// for recovering work that Android dropped (including after force-stop).
class ScheduleReconciler {
  static const targetTolerance = Duration(minutes: 3);

  static ScheduleWorkAction decide({
    required bool enabled,
    required bool hasSelectedDays,
    required bool workRunning,
    required bool workPending,
    required DateTime? storedTarget,
    required DateTime? computedTarget,
    required DateTime now,
    Duration tolerance = targetTolerance,
  }) {
    if (!enabled || !hasSelectedDays || computedTarget == null) {
      return ScheduleWorkAction.cancel;
    }
    if (workRunning) return ScheduleWorkAction.keepExisting;

    if (workPending && storedTarget == null) {
      // Work is already queued, but this install has not stored a target yet.
      // Leave that single job; the worker records the next target when it runs.
      return ScheduleWorkAction.keepExisting;
    }

    if (workPending && storedTarget != null && !storedTarget.isAfter(now)) {
      // The queued run is already due. Let it finish, then it schedules
      // the next selected weekday.
      return ScheduleWorkAction.keepExisting;
    }

    if (workPending &&
        storedTarget != null &&
        storedTarget.isAfter(now) &&
        storedTarget.difference(now) <= tolerance) {
      // Same-minute grace schedules a run a few seconds out. That target
      // does not match the following weekday, so keep the imminent job.
      return ScheduleWorkAction.keepExisting;
    }

    if (workPending && storedTarget != null) {
      final delta = storedTarget.difference(computedTarget).abs();
      if (delta <= tolerance) return ScheduleWorkAction.keepExisting;
    }

    return ScheduleWorkAction.replace;
  }
}
