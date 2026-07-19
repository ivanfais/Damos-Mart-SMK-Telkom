/// Utilitas tanggal relatif — konsisten untuk antrean & notifikasi.
class RelativeDateUtils {
  RelativeDateUtils._();

  static DateTime dateOnly(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static int daysAgo(DateTime dateTime) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(dateTime);
    return today.difference(target).inDays;
  }

  /// Awal minggu kalender (Senin).
  static DateTime weekStart(DateTime dateOnly) {
    final mondayOffset = dateOnly.weekday - DateTime.monday;
    return dateOnly.subtract(Duration(days: mondayOffset));
  }

  static bool isSameCalendarWeek(DateTime dateTime, DateTime reference) {
    final target = dateOnly(dateTime);
    final ref = dateOnly(reference);
    return weekStart(target) == weekStart(ref);
  }

  static bool isPreviousCalendarWeek(DateTime dateTime, DateTime reference) {
    final target = dateOnly(dateTime);
    final ref = dateOnly(reference);
    final thisWeekStart = weekStart(ref);
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    return !target.isBefore(lastWeekStart) && target.isBefore(thisWeekStart);
  }
}
