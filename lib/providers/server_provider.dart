import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config_provider.dart';

enum ServerProtocol { vless, vmess, trojan, ss }

class Server {
  final String id;
  final String name;
  final String link;
  final ServerProtocol protocol;
  final int? ping;
  final String? subscriptionId;
  final DateTime lastUsed;

  Server({
    required this.id,
    required this.name,
    required this.link,
    required this.protocol,
    this.ping,
    this.subscriptionId,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Server copyWith({
    String? name,
    String? link,
    ServerProtocol? protocol,
    int? ping,
    String? subscriptionId,
    DateTime? lastUsed,
  }) {
    return Server(
      id: id,
      name: name ?? this.name,
      link: link ?? this.link,
      protocol: protocol ?? this.protocol,
      ping: ping ?? this.ping,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'link': link,
    'protocol': protocol.index,
    'ping': ping,
    'subscriptionId': subscriptionId,
    'lastUsed': lastUsed.toIso8601String(),
  };

  factory Server.fromJson(Map<String, dynamic> json) => Server(
    id: json['id'],
    name: json['name'],
    link: json['link'],
    protocol: ServerProtocol.values[json['protocol'] ?? 0],
    ping: json['ping'],
    subscriptionId: json['subscriptionId'],
    lastUsed: DateTime.parse(json['lastUsed']),
  );
}

class ServerListNotifier extends Notifier<List<Server>> {
  late SharedPreferences _prefs;

  @override
  List<Server> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final String? serversJson = _prefs.getString('servers_list');
    if (serversJson != null) {
      final List<dynamic> decoded = jsonDecode(serversJson);
      return decoded.map((item) => Server.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> addServer(Server server) async {
    state = [...state, server];
    await _saveToPrefs();
  }

  Future<void> addServersBatch(List<Server> servers, {String? removeSubscriptionId}) async {
    var newState = List<Server>.from(state);
    if (removeSubscriptionId != null) {
      newState.removeWhere((s) => s.subscriptionId == removeSubscriptionId);
    }
    newState.addAll(servers);
    state = newState;
    await _saveToPrefs();
  }

  Future<void> removeServer(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _saveToPrefs();
  }

  Future<void> removeBySubscription(String subscriptionId) async {
    state = state.where((s) => s.subscriptionId != subscriptionId).toList();
    await _saveToPrefs();
  }

  Future<void> updateServer(Server server) async {
    state = [
      for (final s in state)
        if (s.id == server.id) server else s,
    ];
    await _saveToPrefs();
  }

  Future<void> updatePing(String id, int? ping) async {
    state = [
      for (final s in state)
        if (s.id == id) s.copyWith(ping: ping) else s,
    ];
    // Don't save to prefs for every ping update to avoid disk I/O spam
  }

  Future<void> _saveToPrefs() async {
    final String encoded = jsonEncode(state.map((s) => s.toJson()).toList());
    await _prefs.setString('servers_list', encoded);
  }
}

final serverListProvider = NotifierProvider<ServerListNotifier, List<Server>>(() {
  return ServerListNotifier();
});
