import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime dateTime) {
    final format = DateFormat("dd MMM yyyy, HH:mm 'WIB'", 'id_ID');
    return format.format(dateTime);
  }

  static String formatShort(DateTime dateTime) {
    final format = DateFormat('dd MMM yyyy', 'id_ID');
    return format.format(dateTime);
  }

  static String formatTimeOnly(DateTime dateTime) {
    final format = DateFormat('HH:mm', 'id_ID');
    return '${format.format(dateTime)} WIB';
  }

  static String formatWeekdayTime(DateTime dateTime) {
    final day = DateFormat('EEEE', 'id_ID').format(dateTime);
    return '$day, ${formatTimeOnly(dateTime)}';
  }
}
