import 'package:intl/intl.dart';

class AppFormatters {
  static final DateFormat appointment = DateFormat('d MMM • HH:mm', 'ru_RU');
  static final DateFormat dateOnly = DateFormat('d MMM yyyy', 'ru_RU');
  static final DateFormat timeOnly = DateFormat('HH:mm', 'ru_RU');
}
