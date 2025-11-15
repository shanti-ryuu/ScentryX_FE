import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('MMM dd, yyyy').format(date);
}

String formatTime(DateTime date) {
  return DateFormat('hh:mm a').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('MMM dd, yyyy hh:mm a').format(date);
}
