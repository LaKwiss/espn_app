import 'package:intl/intl.dart';

class DateFormatterService {
  String formatDate(DateTime date, {String format = 'dd MMMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  String formatTime(DateTime date, {String format = 'HH:mm'}) {
    return DateFormat(format).format(date);
  }

  String formatMatchDate(DateTime date) {
    return DateFormat('d MMMM').format(date);
  }

  String formatMatchTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String formatYYYYMMDD(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}
