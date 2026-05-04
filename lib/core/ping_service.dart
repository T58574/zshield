import 'dart:io';
import 'dart:async';

class PingService {
  static Future<int?> getTcpPing(String host, int port) async {
    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      stopwatch.stop();
      socket.destroy();
      return stopwatch.elapsedMilliseconds;
    } catch (e) {
      return null;
    }
  }
}
