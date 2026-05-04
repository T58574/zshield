import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/xray_service.dart';

class TrafficState {
  final int totalUplink;
  final int totalDownlink;
  final int uplinkSpeed;
  final int downlinkSpeed;
  final Duration uptime;

  const TrafficState({
    this.totalUplink = 0,
    this.totalDownlink = 0,
    this.uplinkSpeed = 0,
    this.downlinkSpeed = 0,
    this.uptime = Duration.zero,
  });

  TrafficState copyWith({
    int? totalUplink,
    int? totalDownlink,
    int? uplinkSpeed,
    int? downlinkSpeed,
    Duration? uptime,
  }) {
    return TrafficState(
      totalUplink: totalUplink ?? this.totalUplink,
      totalDownlink: totalDownlink ?? this.totalDownlink,
      uplinkSpeed: uplinkSpeed ?? this.uplinkSpeed,
      downlinkSpeed: downlinkSpeed ?? this.downlinkSpeed,
      uptime: uptime ?? this.uptime,
    );
  }
}

class TrafficNotifier extends Notifier<TrafficState> {
  Timer? _timer;
  DateTime? _startTime;
  int _lastUplink = 0;
  int _lastDownlink = 0;

  @override
  TrafficState build() {
    return const TrafficState();
  }

  void startTracking(XrayService xrayService) {
    stopTracking();
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final stats = await xrayService.getTrafficStats();
      
      final currentUplink = stats['uplink'] ?? 0;
      final currentDownlink = stats['downlink'] ?? 0;

      final upSpeed = currentUplink > _lastUplink ? currentUplink - _lastUplink : 0;
      final downSpeed = currentDownlink > _lastDownlink ? currentDownlink - _lastDownlink : 0;

      _lastUplink = currentUplink;
      _lastDownlink = currentDownlink;

      final currentUptime = _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

      state = state.copyWith(
        totalUplink: currentUplink,
        totalDownlink: currentDownlink,
        uplinkSpeed: upSpeed,
        downlinkSpeed: downSpeed,
        uptime: currentUptime,
      );
    });
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _lastUplink = 0;
    _lastDownlink = 0;
    state = const TrafficState();
  }
}

final trafficProvider = NotifierProvider<TrafficNotifier, TrafficState>(() {
  return TrafficNotifier();
});
