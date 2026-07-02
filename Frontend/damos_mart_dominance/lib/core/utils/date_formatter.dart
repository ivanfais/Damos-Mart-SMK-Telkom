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

  static String formatOrderDetailHeader(DateTime dateTime) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final time = DateFormat('HH.mm').format(dateTime);
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} pukul $time';
  }

  static String formatOrderHistoryDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
}
