class Logger {
  static void log(String message) {
    print('[AI Radio Platform] $message');
  }

  static void error(String message) {
    print('[ERROR] $message');
  }

  static void warning(String message) {
    print('[WARNING] $message');
  }

  static void debug(String message) {
    print('[DEBUG] $message');
  }
}