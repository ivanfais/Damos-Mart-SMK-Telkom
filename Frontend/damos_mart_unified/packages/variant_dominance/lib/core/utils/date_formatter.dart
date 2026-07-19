import 'package:intl/intl.dart';

class DateFormatter {
  static DateTime _toLocal(DateTime dateTime) {
    return dateTime.isUtc ? dateTime.toLocal() : dateTime;
  }

  static String format(DateTime dateTime) {
    final local = _toLocal(dateTime);
    final format = DateFormat("dd MMM yyyy, HH:mm 'WIB'", 'id_ID');
    return format.format(local);
  }

  static String formatShort(DateTime dateTime) {
    final local = _toLocal(dateTime);
    final format = DateFormat('dd MMM yyyy', 'id_ID');
    return format.format(local);
  }

  static String formatTimeOnly(DateTime dateTime) {
    final local = _toLocal(dateTime);
    final format = DateFormat('HH:mm', 'id_ID');
    return '${format.format(local)} WIB';
  }

  static String formatWeekdayTime(DateTime dateTime) {
    final local = _toLocal(dateTime);
    final day = DateFormat('EEEE', 'id_ID').format(local);
    return '$day, ${formatTimeOnly(local)}';
  }

  /// Format detail pesanan: `4 Juli 2026 pukul 19.13`
  static String formatOrderDetailHeader(DateTime dateTime) {
    final local = _toLocal(dateTime);
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final time = DateFormat('HH.mm').format(local);
    return '${local.day} ${months[local.month - 1]} ${local.year} pukul $time';
  }

  /// Format daftar pesanan, selaras admin: `05/07/2026, 19.13`
  static String formatOrderHistoryDate(DateTime dateTime) {
    final local = _toLocal(dateTime);
    return DateFormat('dd/MM/yyyy, HH.mm', 'id_ID').format(local);
  }

  /// Format datetime admin panel: `05/07/2026, 19.13`
  static String formatOrderAdminDateTime(DateTime dateTime) {
    return formatOrderHistoryDate(dateTime);
  }
}
