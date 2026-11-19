class WebNotifier {
  WebNotifier._();
  static bool get supported => false;
  static Future<bool> requestPermission() async => false;
  static void show(int id, String title, String body) {}
  static void schedule(int id, DateTime when, String title, String body) {}
  static void cancel(int id) {}
  static int get pending => 0;
}
