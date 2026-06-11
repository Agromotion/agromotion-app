import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Quantidade de chamadas no stacktrace
      errorMethodCount: 8, // Stacktrace em caso de erro
      lineLength: 120, // Largura da linha
      colors: true, // Cores no terminal
      printEmojis: true, // Emojis para cada nível
      dateTimeFormat: DateTimeFormat.dateAndTime, // Formato da data/hora
    ),
    // ProductionFilter garante que os logs aparecem no modo Profile/Release no Browser
    filter: ProductionFilter(),
  );

  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(String message, [dynamic error, StackTrace? stack]) =>
      _logger.e(message, error: error, stackTrace: stack);
}
