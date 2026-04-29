import 'package:intl/intl.dart';

DateTime parseApiDateTime(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) {
    throw const FormatException('Missing date value');
  }

  final isoParsed = DateTime.tryParse(raw);
  if (isoParsed != null) {
    return isoParsed.toLocal();
  }

  final normalized = raw.endsWith('GMT')
      ? raw.substring(0, raw.length - 3).trim()
      : raw;

  for (final pattern in const [
    'EEE, dd MMM yyyy HH:mm:ss',
    'EEE, d MMM yyyy HH:mm:ss',
  ]) {
    try {
      return DateFormat(pattern, 'en_US').parseUtc(normalized).toLocal();
    } on FormatException {
      // Try the next known API date format.
    }
  }

  throw FormatException('Unsupported date format: $raw');
}
