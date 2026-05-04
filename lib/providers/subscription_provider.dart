import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'config_provider.dart';
import 'server_provider.dart';

class Subscription {
  final String id;
  final String name;
  final String url;
  final DateTime lastUpdated;

  Subscription({
    required this.id,
    required this.name,
    required this.url,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'],
    name: json['name'],
    url: json['url'],
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}

class SubscriptionNotifier extends Notifier<List<Subscription>> {
  late SharedPreferences _prefs;

  @override
  List<Subscription> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final String? json = _prefs.getString('subscriptions_list');
    if (json != null) {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((item) => Subscription.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> addSubscription(String name, String url) async {
    final sub = Subscription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      url: url,
      lastUpdated: DateTime.now(),
    );
    state = [...state, sub];
    await _saveToPrefs();
    await fetchSubscription(sub.id);
  }

  Future<void> removeSubscription(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _saveToPrefs();
    // Also remove servers associated with this sub
    await ref.read(serverListProvider.notifier).removeBySubscription(id);
  }

  Future<void> fetchSubscription(String id) async {
    final sub = state.firstWhere((s) => s.id == id);
    try {
      final response = await http.get(Uri.parse(sub.url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        String content = response.body.trim();
        // Base64 decode
        try {
          content = utf8.decode(base64.decode(_normalizeBase64(content)));
        } catch (e) {
          // If not base64, maybe it's plain text (rare for subscriptions but happens)
        }

        final lines = content.split(RegExp(r'[\n\r]+'));
        final List<Server> servers = [];
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          
          // Only support VLESS as requested
          if (line.startsWith('vless://')) {
            String sName = "Server";
            try {
              final uri = Uri.parse(line);
              if (uri.fragment.isNotEmpty) {
                sName = Uri.decodeComponent(uri.fragment);
              } else {
                sName = uri.host;
              }
            } catch (_) {}

            servers.add(Server(
              id: '${sub.id}_${servers.length}_${DateTime.now().millisecondsSinceEpoch}',
              name: sName,
              link: line,
              protocol: ServerProtocol.vless,
              subscriptionId: sub.id,
            ));
          }
        }

        if (servers.isNotEmpty) {
          await ref.read(serverListProvider.notifier).addServersBatch(servers, removeSubscriptionId: sub.id);
          // Update lastUpdated
          state = [
            for (final s in state)
              if (s.id == id) Subscription(id: s.id, name: s.name, url: s.url, lastUpdated: DateTime.now()) else s,
          ];
          await _saveToPrefs();
        }
      }
    } catch (e) {
      print("Error fetching subscription: $e");
    }
  }

  String _normalizeBase64(String b64) {
    b64 = b64.replaceAll('\n', '').replaceAll('\r', '').trim();
    while (b64.length % 4 != 0) {
      b64 += '=';
    }
    return b64;
  }

  Future<void> _saveToPrefs() async {
    final String encoded = jsonEncode(state.map((s) => s.toJson()).toList());
    await _prefs.setString('subscriptions_list', encoded);
  }
}

final subscriptionProvider = NotifierProvider<SubscriptionNotifier, List<Subscription>>(() {
  return SubscriptionNotifier();
});
