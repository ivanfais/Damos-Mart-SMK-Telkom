class PreorderDateUtils {
  PreorderDateUtils._();

  static int parseProductionDays(String? estimation) {
    if (estimation == null || estimation.isEmpty) return 14;
    final matches =
        RegExp(r'(\d+)').allMatches(estimation).map((m) => int.parse(m.group(1)!)).toList();
    if (matches.isEmpty) return 14;
    return matches.reduce((a, b) => a > b ? a : b);
  }

  static String formatDate(DateTime date, {bool includeYear = false}) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final base = '${date.day} ${months[date.month - 1]}';
    if (includeYear) return '$base ${date.year}';
    return base;
  }

  static DateTime addBusinessDays(DateTime start, int days) {
    var result = start;
    var added = 0;
    while (added < days) {
      result = result.add(const Duration(days: 1));
      if (result.weekday != DateTime.saturday && result.weekday != DateTime.sunday) {
        added++;
      }
    }
    return result;
  }

  static String completionRange(int productionDays) {
    final now = DateTime.now();
    return completionRangeFromBase(now, productionDays);
  }

  static String completionRangeFromBase(DateTime baseDate, int productionDays) {
    final end = addBusinessDays(baseDate, productionDays);
    final start = addBusinessDays(
      baseDate,
      productionDays > 1 ? productionDays - 1 : productionDays,
    );
    return '${formatDate(start)} - ${formatDate(end)}';
  }

  static String completionRangeFromEstimation(String? estimation) {
    return completionRange(parseProductionDays(estimation));
  }
}
