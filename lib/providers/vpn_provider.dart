import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/xray_service.dart';

enum VpnConnectionState { disconnected, connecting, connected, error }

class VpnState {
  final VpnConnectionState connectionState;
  final String? errorMessage;
  final String? serverName;
  final DateTime? connectedAt;

  const VpnState({
    this.connectionState = VpnConnectionState.disconnected,
    this.errorMessage,
    this.serverName,
    this.connectedAt,
  });

  VpnState copyWith({
    VpnConnectionState? connectionState,
    String? errorMessage,
    String? serverName,
    DateTime? connectedAt,
  }) {
    return VpnState(
      connectionState: connectionState ?? this.connectionState,
      errorMessage: errorMessage ?? this.errorMessage,
      serverName: serverName ?? this.serverName,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

class VpnNotifier extends Notifier<VpnState> {
  final XrayService _xrayService = XrayService();

  @override
  VpnState build() {
    return const VpnState();
  }

  Future<void> connect(ConfigState configState) async {
    if (state.connectionState == VpnConnectionState.connecting ||
        state.connectionState == VpnConnectionState.connected) {
      return;
    }

    state = state.copyWith(connectionState: VpnConnectionState.connecting);

    try {
      String sName = "Unknown Server";
      try {
        final uri = Uri.parse(configState.vlessLink);
        if (uri.fragment.isNotEmpty) {
          sName = Uri.decodeComponent(uri.fragment);
        } else {
          sName = uri.host;
        }
      } catch (_) {}

      await _xrayService.start(configState);
      state = state.copyWith(
        connectionState: VpnConnectionState.connected,
        serverName: sName,
        connectedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
          connectionState: VpnConnectionState.error, errorMessage: e.toString());
    }
  }

  Future<void> disconnect() async {
    await _xrayService.stop();
    state = state.copyWith(connectionState: VpnConnectionState.disconnected);
  }
}

final vpnProvider = NotifierProvider<VpnNotifier, VpnState>(() {
  return VpnNotifier();
});
