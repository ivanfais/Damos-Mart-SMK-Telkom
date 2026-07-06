import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String format(num number) {
    final safe = number.isNaN || number.isInfinite ? 0 : number;
    return _formatter.format(safe);
  }

  static String formatDouble(double number) {
    final safe = number.isNaN || number.isInfinite ? 0 : number;
    return _formatter.format(safe);
  }
}
