import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/xray_service.dart';
import 'config_provider.dart';
import 'traffic_provider.dart';
import 'server_provider.dart';

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
    bool clearError = false,
    String? serverName,
    DateTime? connectedAt,
  }) {
    return VpnState(
      connectionState: connectionState ?? this.connectionState,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      serverName: serverName ?? this.serverName,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

class VpnNotifier extends Notifier<VpnState> {
  final XrayService _xrayService = XrayService();

  @override
  VpnState build() {
    _xrayService.onExit = (code) {
      if (code == -2 && state.connectionState != VpnConnectionState.disconnected) {
        state = state.copyWith(
          connectionState: VpnConnectionState.error, 
          errorMessage: 'Ошибка: Запустите программу от имени Администратора для работы TUN (Tunnel) режима'
        );
        ref.read(trafficProvider.notifier).stopTracking();
      } else if (code != 0 && code != -1 && state.connectionState != VpnConnectionState.disconnected) {
        state = state.copyWith(
          connectionState: VpnConnectionState.error, 
          errorMessage: 'Xray process exited unexpectedly (code: $code)'
        );
        ref.read(trafficProvider.notifier).stopTracking();
      } else if (state.connectionState != VpnConnectionState.disconnected) {
        state = state.copyWith(connectionState: VpnConnectionState.disconnected, clearError: true);
        ref.read(trafficProvider.notifier).stopTracking();
      }
    };
    return const VpnState();
  }

  /// Validates the VLESS link format before attempting connection.
  String? _validateVlessLink(String link) {
    if (link.isEmpty) return 'VLESS ссылка не задана';
    if (!link.startsWith('vless://')) return 'Неверный формат: ссылка должна начинаться с vless://';
    try {
      final uri = Uri.parse(link);
      if (uri.host.isEmpty) return 'Неверный адрес сервера';
      if (uri.port == 0) return 'Не указан порт сервера';
      if (uri.userInfo.isEmpty) return 'Не указан UUID пользователя';
    } catch (_) {
      return 'Не удалось распарсить VLESS ссылку';
    }
    return null; // Valid
  }

  Future<void> connect(ConfigState configState) async {
    if (state.connectionState == VpnConnectionState.connecting ||
        state.connectionState == VpnConnectionState.connected) {
      return;
    }

    // Determine which link to use
    String linkToUse = configState.vlessLink;
    String sName = "Unknown Server";

    if (configState.selectedServerId != null) {
      final servers = ref.read(serverListProvider);
      final selectedServer = servers.cast<Server?>().firstWhere(
        (s) => s?.id == configState.selectedServerId, 
        orElse: () => null
      );
      if (selectedServer != null) {
        linkToUse = selectedServer.link;
        sName = selectedServer.name;
      }
    }

    // Validate link
    final validationError = _validateVlessLink(linkToUse);
    if (validationError != null) {
      state = state.copyWith(
        connectionState: VpnConnectionState.error,
        errorMessage: validationError,
      );
      return;
    }

    state = state.copyWith(connectionState: VpnConnectionState.connecting, clearError: true);

    try {
      if (sName == "Unknown Server") {
        try {
          final uri = Uri.parse(linkToUse);
          if (uri.fragment.isNotEmpty) {
            sName = Uri.decodeComponent(uri.fragment);
          } else {
            sName = uri.host;
          }
        } catch (_) {}
      }

      // We need to pass the actual link to use to the xray service
      // The xray service uses configState, so we might need to temporary override it
      // or update XrayService to take a link directly.
      // Let's update configState temporarily for the start call or pass a modified state.
      final effectiveConfig = configState.copyWith(vlessLink: linkToUse);
      await _xrayService.start(effectiveConfig);
      state = state.copyWith(
        connectionState: VpnConnectionState.connected,
        serverName: sName,
        connectedAt: DateTime.now(),
        clearError: true,
      );
      ref.read(trafficProvider.notifier).startTracking(_xrayService);
    } catch (e) {
      state = state.copyWith(
          connectionState: VpnConnectionState.error, errorMessage: e.toString());
    }
  }

  Future<void> disconnect() async {
    ref.read(trafficProvider.notifier).stopTracking();
    await _xrayService.stop();
    state = state.copyWith(connectionState: VpnConnectionState.disconnected, clearError: true);
  }
}

final vpnProvider = NotifierProvider<VpnNotifier, VpnState>(() {
  return VpnNotifier();
});
