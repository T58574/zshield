import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'server_provider.dart';

class PremiumServerNotifier extends Notifier<void> {
  @override
  void build() {
    // Listen to auth changes to trigger fetch
    ref.listen(authProvider, (previous, next) {
      if (next.isPremium && next.profile?.premiumSubscriptionUrl != null) {
        _fetchPremiumServers(next.profile!.premiumSubscriptionUrl!);
      }
    });

    // Initial check
    final authState = ref.read(authProvider);
    if (authState.isPremium && authState.profile?.premiumSubscriptionUrl != null) {
      _fetchPremiumServers(authState.profile!.premiumSubscriptionUrl!);
    }
  }

  Future<void> _fetchPremiumServers(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        String content = response.body.trim();
        
        // Handle Base64 encoded subscription content
        try {
          content = utf8.decode(base64.decode(_normalizeBase64(content)));
        } catch (e) {
          // Content might be plain text
        }

        final lines = content.split(RegExp(r'[\n\r]+'));
        final List<Server> servers = [];
        
        for (var line in lines) {
          line = line.trim();
          if (line.isEmpty) continue;
          
          if (line.startsWith('vless://')) {
            String name = "Premium Server";
            try {
              final uri = Uri.parse(line);
              if (uri.fragment.isNotEmpty) {
                name = Uri.decodeComponent(uri.fragment);
              }
            } catch (_) {}

            servers.add(Server(
              id: 'premium_${servers.length}_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              link: line,
              protocol: ServerProtocol.vless,
              subscriptionId: 'premium_sub',
            ));
          }
        }

        if (servers.isNotEmpty) {
          await ref.read(serverListProvider.notifier).addServersBatch(
            servers, 
            removeSubscriptionId: 'premium_sub'
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching premium servers: $e");
    }
  }

  String _normalizeBase64(String b64) {
    b64 = b64.replaceAll('\n', '').replaceAll('\r', '').trim();
    while (b64.length % 4 != 0) {
      b64 += '=';
    }
    return b64;
  }
}

final premiumServerProvider = NotifierProvider<PremiumServerNotifier, void>(() {
  return PremiumServerNotifier();
});
