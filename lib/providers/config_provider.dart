import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class ConfigState {
  final String vlessLink;
  final bool isProxyMode; // true = Proxy, false = Tunnel
  final List<String> routedApps;
  final bool killSwitch;
  final bool autoConnect;
  final bool lanVisibility;
  final bool customDns;

  const ConfigState({
    this.vlessLink = '',
    this.isProxyMode = false,
    this.routedApps = const [],
    this.killSwitch = true,
    this.autoConnect = true,
    this.lanVisibility = false,
    this.customDns = true,
  });

  ConfigState copyWith({
    String? vlessLink,
    bool? isProxyMode,
    List<String>? routedApps,
    bool? killSwitch,
    bool? autoConnect,
    bool? lanVisibility,
    bool? customDns,
  }) {
    return ConfigState(
      vlessLink: vlessLink ?? this.vlessLink,
      isProxyMode: isProxyMode ?? this.isProxyMode,
      routedApps: routedApps ?? this.routedApps,
      killSwitch: killSwitch ?? this.killSwitch,
      autoConnect: autoConnect ?? this.autoConnect,
      lanVisibility: lanVisibility ?? this.lanVisibility,
      customDns: customDns ?? this.customDns,
    );
  }
}

class ConfigNotifier extends Notifier<ConfigState> {
  late SharedPreferences _prefs;

  @override
  ConfigState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    
    return ConfigState(
      vlessLink: _prefs.getString('vlessLink') ?? '',
      isProxyMode: _prefs.getBool('isProxyMode') ?? false,
      routedApps: _prefs.getStringList('routedApps') ?? [],
      killSwitch: _prefs.getBool('killSwitch') ?? true,
      autoConnect: _prefs.getBool('autoConnect') ?? true,
      lanVisibility: _prefs.getBool('lanVisibility') ?? false,
      customDns: _prefs.getBool('customDns') ?? true,
    );
  }

  void setVlessLink(String link) {
    state = state.copyWith(vlessLink: link);
    _prefs.setString('vlessLink', link);
  }

  void setRoutingMode(bool isProxy) {
    state = state.copyWith(isProxyMode: isProxy);
    _prefs.setBool('isProxyMode', isProxy);
  }

  void toggleAppRouting(String appName) {
    final apps = List<String>.from(state.routedApps);
    if (apps.contains(appName)) {
      apps.remove(appName);
    } else {
      apps.add(appName);
    }
    state = state.copyWith(routedApps: apps);
    _prefs.setStringList('routedApps', apps);
  }

  void updateSettings({bool? killSwitch, bool? autoConnect, bool? lanVisibility, bool? customDns}) {
    state = state.copyWith(
      killSwitch: killSwitch,
      autoConnect: autoConnect,
      lanVisibility: lanVisibility,
      customDns: customDns,
    );
    if (killSwitch != null) _prefs.setBool('killSwitch', killSwitch);
    if (autoConnect != null) _prefs.setBool('autoConnect', autoConnect);
    if (lanVisibility != null) _prefs.setBool('lanVisibility', lanVisibility);
    if (customDns != null) _prefs.setBool('customDns', customDns);
  }

  void resetSettings() {
    state = const ConfigState();
    _prefs.clear();
  }
}

final configProvider = NotifierProvider<ConfigNotifier, ConfigState>(() {
  return ConfigNotifier();
});
