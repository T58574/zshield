import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/config_provider.dart';

class XrayService {
  Process? _xrayProcess;
  bool _isRunning = false;
  bool _proxyEnabled = false;
  bool _tunEnabled = false;
  Process? _singBoxProcess;
  String? _cachedXrayPath;
  Function(int)? onExit;

  int _apiPort = 10085;
  int _socksPort = 10808;
  int _httpPort = 10809;

  bool get isRunning => _isRunning;

  Future<Map<String, int>> getTrafficStats() async {
    if (!_isRunning) return {'uplink': 0, 'downlink': 0};
    try {
      final xrayPath = await _extractXray();
      final result = await Process.run(xrayPath, ['api', 'statsquery', '--server=127.0.0.1:$_apiPort']);
      if (result.exitCode == 0) {
        int uplink = 0;
        int downlink = 0;
        final json = jsonDecode(result.stdout as String);
        if (json['stat'] != null) {
          for (var item in json['stat']) {
            final name = item['name'] as String;
            final value = int.tryParse(item['value']?.toString() ?? '0') ?? 0;
            if (name.contains('api')) continue; // Skip api traffic
            
            if (name.endsWith('>>>downlink')) {
              downlink += value;
            } else if (name.endsWith('>>>uplink')) {
              uplink += value;
            }
          }
        }
        return {'uplink': uplink, 'downlink': downlink};
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    }
    return {'uplink': 0, 'downlink': 0};
  }

  Future<String> _extractXray() async {
    // Return cached path if available and file still exists
    if (_cachedXrayPath != null && await File(_cachedXrayPath!).exists()) {
      return _cachedXrayPath!;
    }

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

    _cachedXrayPath = xrayPath;
    return xrayPath;
  }

  Future<void> _extractSingBox() async {
    if (!Platform.isWindows) return;
    final docDir = await getApplicationSupportDirectory();
    final separator = Platform.pathSeparator;
    
    final sbPath = '${docDir.path}${separator}sing-box.exe';
    final fileSb = File(sbPath);
    if (!await fileSb.exists()) {
      try {
        final byteData = await rootBundle.load('assets/core/sing-box.exe');
        await fileSb.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      } catch (e) {
        debugPrint("Warning: sing-box.exe not found in assets.");
      }
    }
    
    final wintunPath = '${docDir.path}${separator}wintun.dll';
    final fileWintun = File(wintunPath);
    if (!await fileWintun.exists()) {
      try {
        final byteData = await rootBundle.load('assets/core/wintun.dll');
        await fileWintun.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      } catch (e) {
        debugPrint("Warning: wintun.dll not found in assets.");
      }
    }
  }

  Future<List<int>> _getAvailablePorts(int count) async {
    List<ServerSocket> sockets = [];
    List<int> ports = [];
    for (int i = 0; i < count; i++) {
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      sockets.add(socket);
      ports.add(socket.port);
    }
    for (var socket in sockets) {
      await socket.close();
    }
    return ports;
  }

  Future<void> start(ConfigState configState) async {
    if (_isRunning) return;

    try {
      final xrayPath = await _extractXray();
      final configPath = '${File(xrayPath).parent.path}${Platform.pathSeparator}config.json';
      
      // 1. Cleanup previous orphaned instance using PID file
      final docDir = await getApplicationSupportDirectory();
      final pidFile = File('${docDir.path}${Platform.pathSeparator}xray_pid.txt');
      if (await pidFile.exists()) {
        try {
          final oldPidStr = await pidFile.readAsString();
          final oldPid = int.tryParse(oldPidStr);
          if (oldPid != null) {
            if (Platform.isWindows) {
              await Process.run('taskkill', ['/F', '/PID', oldPid.toString()]);
            } else {
              await Process.run('kill', ['-9', oldPid.toString()]);
            }
          }
        } catch (_) {} // Ignore errors if process doesn't exist
      }

      // 2. Allocate dynamic ports to avoid "address already in use" errors
      final ports = await _getAvailablePorts(3);
      _apiPort = ports[0];
      _socksPort = ports[1];
      _httpPort = ports[2];

      final configJson = _generateConfig(configState);
      await File(configPath).writeAsString(configJson);

      if (configState.isProxyMode) {
        await _setSystemProxy(true);
        _proxyEnabled = true;
      } else {
        if (Platform.isWindows) {
          await _extractSingBox();
          final sbConfigPath = '${docDir.path}${Platform.pathSeparator}sb_tun.json';
          final sbConfig = {
            "log": {"level": "fatal"},
            "inbounds": [
              {
                "type": "tun",
                "tag": "tun-in",
                "interface_name": "zshield",
                "inet4_address": "172.19.0.1/30",
                "auto_route": true,
                "strict_route": true,
                "stack": "system",
                "sniff": true
              }
            ],
            "outbounds": [
              {
                "type": "socks",
                "tag": "socks-out",
                "server": "127.0.0.1",
                "server_port": _socksPort
              }
            ]
          };
          await File(sbConfigPath).writeAsString(jsonEncode(sbConfig));
          
          try {
            _singBoxProcess = await Process.start('${docDir.path}${Platform.pathSeparator}sing-box.exe', ['run', '-c', sbConfigPath]);
            _tunEnabled = true;
            
            _singBoxProcess?.exitCode.then((code) {
              if (code != 0 && _tunEnabled && _isRunning) {
                // If it exits immediately, likely admin rights missing
                stop(); // Ensure we don't leave Xray running without tunnel
                onExit?.call(-2); 
              }
            });
          } catch (e) {
            debugPrint("Failed to start sing-box: $e");
          }
        }
      }

      _xrayProcess = await Process.start(xrayPath, ['run', '-c', configPath]);
      _isRunning = true;
      
      // Save new PID for future cleanup
      await pidFile.writeAsString(_xrayProcess!.pid.toString());
      
      _xrayProcess?.stdout.transform(utf8.decoder).listen((data) => debugPrint("XRAY STDOUT: $data"));
      _xrayProcess?.stderr.transform(utf8.decoder).listen((data) => debugPrint("XRAY STDERR: $data"));

      _xrayProcess?.exitCode.then((code) {
        _isRunning = false;
        debugPrint("Xray process exited with code $code");
        if (_proxyEnabled) {
          _setSystemProxy(false);
          _proxyEnabled = false;
        }
        if (_tunEnabled) {
          _singBoxProcess?.kill();
          _tunEnabled = false;
        }
        onExit?.call(code);
      });
    } catch (e) {
      _isRunning = false;
      if (_proxyEnabled) {
        await _setSystemProxy(false);
        _proxyEnabled = false;
      }
      if (_tunEnabled) {
        _singBoxProcess?.kill();
        _tunEnabled = false;
      }
      rethrow;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    
    if (_proxyEnabled) {
      await _setSystemProxy(false);
      _proxyEnabled = false;
    }
    
    if (_tunEnabled) {
      _singBoxProcess?.kill();
      _tunEnabled = false;
    }
    
    // Graceful shutdown: try SIGTERM first, then force kill after timeout
    if (Platform.isWindows) {
      _xrayProcess?.kill();
    } else {
      _xrayProcess?.kill(ProcessSignal.sigterm);
      await Future.delayed(const Duration(seconds: 2));
      try {
        _xrayProcess?.kill(ProcessSignal.sigkill);
      } catch (_) {
        // Process may have already exited
      }
    }
    _xrayProcess = null;
    _isRunning = false;
  }

  /// Set system proxy (async to avoid blocking UI thread)
  Future<void> _setSystemProxy(bool enable) async {
    if (!Platform.isWindows) return;
    
    if (enable) {
      await Process.run('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '1', '/f']);
      await Process.run('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '127.0.0.1:$_httpPort', '/f']);
    } else {
      await Process.run('reg', ['add', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings', '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '0', '/f']);
    }
  }

  String _generateConfig(ConfigState configState) {
    // A simplified VLESS link parser
    // Format: vless://uuid@address:port?security=tls&encryption=none&type=ws&host=xyz&path=/xyz#name
    String address = "example.com";
    int port = 443;
    String id = "00000000-0000-0000-0000-000000000000";
    String flow = "";
    String security = "none";
    String type = "tcp";
    String path = "";
    String host = "";
    String sni = "";
    String pbk = "";
    String sid = "";
    String fp = "chrome";
    String spx = "/";

    try {
      final uri = Uri.parse(configState.vlessLink);
      final userInfo = uri.userInfo.split(':');
      if (userInfo.isNotEmpty && userInfo[0].isNotEmpty) {
        id = userInfo[0];
      }
      address = uri.host;
      port = uri.port;
      
      security = uri.queryParameters['security'] ?? 'none';
      type = uri.queryParameters['type'] ?? 'tcp';
      path = uri.queryParameters['path'] ?? '';
      host = uri.queryParameters['host'] ?? '';
      sni = uri.queryParameters['sni'] ?? '';
      flow = uri.queryParameters['flow'] ?? '';
      pbk = uri.queryParameters['pbk'] ?? '';
      sid = uri.queryParameters['sid'] ?? '';
      fp = uri.queryParameters['fp'] ?? 'chrome';
      spx = uri.queryParameters['spx'] ?? '/';
    } catch (e) {
      debugPrint("Error parsing VLESS link: $e");
    }

    // Both modes use SOCKS+HTTP inbounds since Xray-core does not support TUN natively.
    // In proxy mode, system proxy is set to HTTP inbound.
    // In "tunnel" mode, the same SOCKS+HTTP inbounds are used (TUN requires external tun2socks).
    final List<Map<String, dynamic>> inbounds = [
      {
        "port": _socksPort,
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
      },
      {
        "port": _httpPort,
        "listen": "127.0.0.1",
        "protocol": "http",
        "settings": {
          "allowTransparent": false
        }
      },
    ];

    // Stats API inbound
    inbounds.add({
      "port": _apiPort,
      "listen": "127.0.0.1",
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "tag": "api-inbound"
    });

    // Build outbounds
    final Map<String, dynamic> proxyOutbound = {
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
                if (flow.isNotEmpty) "flow": flow
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": type,
        "security": security,
        if (security == 'tls') "tlsSettings": {
          "serverName": sni.isNotEmpty ? sni : (host.isNotEmpty ? host : address),
          "allowInsecure": false,
        },
        if (security == 'reality') "realitySettings": {
          "serverName": sni.isNotEmpty ? sni : (host.isNotEmpty ? host : address),
          "publicKey": pbk,
          "fingerprint": fp,
          "shortId": sid,
          "spiderX": spx,
        },
        if (type == 'ws') "wsSettings": {
          "path": path,
          "headers": host.isNotEmpty ? {"Host": host} : {}
        },
      }
    };

    // Routing rules
    final List<Map<String, dynamic>> rules = [
      {
        "inboundTag": ["api-inbound"],
        "outboundTag": "api",
        "type": "field"
      },
    ];

    if (configState.lanVisibility) {
      rules.add({
        "type": "field",
        "ip": ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8", "fc00::/7", "fe80::/10"],
        "outboundTag": "direct"
      });
    }

    if (configState.isProxyMode) {
      rules.add({
        "type": "field",
        "network": "tcp,udp",
        "outboundTag": "proxy"
      });
    }

    Map<String, dynamic> config = {
      "log": {
        "loglevel": "warning"
      },
      "api": {
        "tag": "api",
        "services": [
          "HandlerService",
          "LoggerService",
          "StatsService"
        ]
      },
      "stats": {},
      "policy": {
        "system": {
          "statsInboundUplink": true,
          "statsInboundDownlink": true,
          "statsOutboundUplink": true,
          "statsOutboundDownlink": true
        }
      },
      if (configState.customDns) "dns": {
        "servers": ["1.1.1.1", "8.8.8.8", "localhost"]
      },
      "inbounds": inbounds,
      "outbounds": [
        proxyOutbound,
        {
          "protocol": "freedom",
          "tag": "direct"
        },
        {
          "protocol": "blackhole",
          "tag": "block"
        }
      ],
      "routing": {
        "domainStrategy": "AsIs",
        "rules": rules
      }
    };

    return jsonEncode(config);
  }
}
