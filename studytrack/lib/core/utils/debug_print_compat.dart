import 'app_logger.dart';

void debugPrint(String? message, {int? wrapWidth}) {
  final text = message ?? '';
  final lower = text.toLowerCase();

  if (lower.contains('error') ||
      lower.contains('failed') ||
      text.contains('✗')) {
    AppLogger.error(text);
    return;
  }

  if (lower.contains('warning') || text.contains('!')) {
    AppLogger.warning(text);
    return;
  }

  AppLogger.info(text);
}
