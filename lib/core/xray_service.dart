import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../providers/config_provider.dart';

class XrayService {
  Process? _xrayProcess;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<String> _extractXray() async {
    final docDir = await getApplicationSupportDirectory();
    final String binaryName = Platform.isWindows ? 'xray.exe' : (Platform.isMacOS ? 'xray_mac' : 'xray_linux');
    final String separator = Platform.pathSeparator;
    final xrayPath = '${docDir.path}$separator$binaryName';
    final file = File(xrayPath);

    if (!await file.exists()) {
      try {
        final byteData = await rootBundle.load('assets/core/$binaryName');
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        if (!Platform.isWindows) {
          await Process.run('chmod', ['+x', xrayPath]);
        }
      } catch (e) {
        throw Exception("Core executable not found for this platform. Please ensure assets/core/$binaryName exists.");
      }
    }
    return xrayPath;
  }

  Future<void> start(ConfigState configState) async {
    if (_isRunning) return;

    try {
      final xrayPath = await _extractXray();
      final configPath = '${File(xrayPath).parent.path}${Platform.pathSeparator}config.json';
      
      final configJson = _generateConfig(configState);
      await File(configPath).writeAsString(configJson);

      if (configState.isProxyMode) {
        _setSystemProxy(true);
      }

      _xrayProcess = await Process.start(xrayPath, ['run', '-c', configPath]);
      _isRunning = true;

      _xrayProcess?.exitCode.then((code) {
        _isRunning = false;
        if (configState.isProxyMode) _setSystemProxy(false);
      });
    } catch (e) {
      _isRunning = false;
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    
    _setSystemProxy(false); 
    
    _xrayProcess?.kill();
    _xrayProcess = null;
    _isRunning = false;
  }

  void _setSystemProxy(bool enable) {
    if (!Platform.isWindows) return; // Mac/Linux system proxy implementation omitted for brevity
    
    if (enable) {
      Process.runSync('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '1', '/f']);
      Process.runSync('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:10808', '/f']);
    } else {
      Process.runSync('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '0', '/f']);
    }
  }

  String _generateConfig(ConfigState configState) {
    // A simplified VLESS link parser
    // Format: vless://uuid@address:port?security=tls&encryption=none&type=ws&host=xyz&path=/xyz#name
    String address = "example.com";
    int port = 443;
    String id = "uuid";
    String flow = "";
    String security = "none";
    String type = "tcp";
    String path = "";
    String host = "";
    String sni = "";

    try {
      final uri = Uri.parse(configState.vlessLink);
      final userInfo = uri.userInfo.split(':');
      id = userInfo[0];
      address = uri.host;
      port = uri.port;
      
      security = uri.queryParameters['security'] ?? 'none';
      type = uri.queryParameters['type'] ?? 'tcp';
      path = uri.queryParameters['path'] ?? '';
      host = uri.queryParameters['host'] ?? '';
      sni = uri.queryParameters['sni'] ?? '';
      flow = uri.queryParameters['flow'] ?? '';
    } catch (e) {
      // Parse error ignored
    }

    final inbound = configState.isProxyMode 
      ? {
          "port": 10808,
          "listen": "127.0.0.1",
          "protocol": "socks",
          "settings": {
            "udp": true,
            "auth": "noauth"
          },
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls"]
          }
        }
      : {
          "port": 10808,
          "listen": "127.0.0.1",
          "protocol": "tun",
          "settings": {
            "network": "10.0.0.1/24",
            "autoRoute": true,
            "strictRoute": configState.killSwitch
          }
        };

    Map<String, dynamic> config = {
      "log": {
        "loglevel": "warning"
      },
      "dns": configState.customDns ? {
        "servers": ["1.1.1.1", "8.8.8.8", "localhost"]
      } : null,
      "inbounds": [inbound],
      "outbounds": [
        {
          "tag": "proxy",
          "protocol": "vless",
          "settings": {
            "vnext": [
              {
                "address": address,
                "port": port,
                "users": [
                  {
                    "id": id,
                    "encryption": "none",
                    "flow": flow.isNotEmpty ? flow : null
                  }
                ]
              }
            ]
          },
          "streamSettings": {
            "network": type,
            "security": security,
            "tlsSettings": security == 'tls' || security == 'reality' ? {
              "serverName": sni.isNotEmpty ? sni : (host.isNotEmpty ? host : address),
              "allowInsecure": false,
            } : null,
            "wsSettings": type == 'ws' ? {
              "path": path,
              "headers": host.isNotEmpty ? {"Host": host} : {}
            } : null,
          }
        },
        {
          "protocol": "freedom",
          "tag": "direct"
        }
      ],
      "routing": {
        "domainStrategy": "AsIs",
        "rules": [
          if (configState.lanVisibility) {
            "type": "field",
            "ip": ["geoip:private"],
            "outboundTag": "direct"
          }
        ]
      }
    };
    
    if (configState.routedApps.isNotEmpty) {
      config["routing"]["rules"].insert(0, {
        "type": "field",
        "process": configState.routedApps,
        "outboundTag": "proxy"
      });
      config["routing"]["rules"].insert(1, {
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "direct"
      });
    }

    return jsonEncode(config);
  }
}
