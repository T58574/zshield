import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../widgets/glass_panel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vpn_provider.dart';
import '../providers/config_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _uptimeTimer;
  String _uptime = '00:00:00';
  double _mockTraffic = 0.0;
  
  @override
  void initState() {
    super.initState();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = ref.read(vpnProvider);
      if (state.connectionState == VpnConnectionState.connected && state.connectedAt != null) {
        final duration = DateTime.now().difference(state.connectedAt!);
        final hours = duration.inHours.toString().padLeft(2, '0');
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        
        setState(() {
          _uptime = '$hours:$minutes:$seconds';
          _mockTraffic += 0.01; // Fake 10MB per second roughly
        });
      } else if (_uptime != '00:00:00') {
        setState(() {
          _uptime = '00:00:00';
        });
      }
    });
  }

  @override
  void dispose() {
    _uptimeTimer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final vpnState = ref.watch(vpnProvider);
    final isConnected = vpnState.connectionState == VpnConnectionState.connected;
    final isConnecting = vpnState.connectionState == VpnConnectionState.connecting;
    
    final configState = ref.watch(configProvider);
    final configNotifier = ref.read(configProvider.notifier);
    
    final vlessLinkController = TextEditingController(text: configState.vlessLink);
    
    // Attempt to extract validity or set mock
    String validUntil = 'Нет ссылки';
    if (configState.vlessLink.isNotEmpty && (configState.vlessLink.startsWith('vless://') || configState.vlessLink.startsWith('vmess://'))) {
      validUntil = 'Активно (Токен валиден)';
    } else if (configState.vlessLink.isNotEmpty) {
      validUntil = 'Неверный формат ссылки';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0), // lg padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time secure connection monitoring.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Toggle (Read-only visual on Dashboard, managed in Routing)
                    GlassPanel(
                      padding: const EdgeInsets.all(4),
                      borderRadius: BorderRadius.circular(30),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            decoration: BoxDecoration(
                              color: !configState.isProxyMode ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text('TUNNEL', style: TextStyle(color: !configState.isProxyMode ? Colors.black : Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            decoration: BoxDecoration(
                              color: configState.isProxyMode ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text('PROXY', style: TextStyle(color: configState.isProxyMode ? Colors.black : Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Chip
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      borderRadius: BorderRadius.circular(30),
                      child: Row(
                        children: [
                          Icon(Symbols.sensors, color: Colors.white.withOpacity(0.6), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            vpnState.serverName ?? 'No Server Selected',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Main Content Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Connect Panel
                Expanded(
                  child: GlassPanel(
                    highIntensity: true,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Symbols.lock, size: 14, color: Colors.white54),
                            const SizedBox(width: 8),
                            Text('SECURITY LEVEL: MAXIMUM', style: Theme.of(context).textTheme.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Protocol: VLESS Handshake Ready', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.white24)),
                        const SizedBox(height: 40),
                        Center(
                          child: InkWell(
                            onTap: () {
                              if (isConnected) {
                                ref.read(vpnProvider.notifier).disconnect();
                              } else {
                                ref.read(vpnProvider.notifier).connect(configState);
                              }
                            },
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              width: 176,
                              height: 176,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                border: Border.all(color: Colors.white.withOpacity(isConnected ? 0.8 : 0.2)),
                                boxShadow: [
                                  BoxShadow(
                                    color: isConnected ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                    blurRadius: isConnected ? 80 : 50,
                                    spreadRadius: isConnected ? 20 : 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  isConnecting 
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Icon(
                                        Symbols.power_settings_new, 
                                        size: 48, 
                                        color: isConnected ? Colors.white : Colors.white.withOpacity(0.4), 
                                        weight: 300,
                                      ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isConnected ? 'CONNECTED' : (isConnecting ? 'CONNECTING' : 'CONNECT'), 
                                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                      fontSize: 16, 
                                      letterSpacing: 4,
                                      color: isConnected ? Colors.white : Colors.white.withOpacity(0.6),
                                    )
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const SizedBox(height: 24),
                        // Link Valid Until Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Symbols.event_available, size: 14, color: Colors.white54),
                            const SizedBox(width: 8),
                            Text('Ссылка действует до: $validUntil', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // VLESS URL Field
                        GlassPanel(
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Icon(Symbols.link, color: Colors.white.withOpacity(0.3), size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: vlessLinkController,
                                  onChanged: (val) => configNotifier.setVlessLink(val),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontSize: 11),
                                  decoration: InputDecoration(
                                    hintText: 'Вставьте VLESS ссылку сюда...',
                                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white30, fontSize: 11),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Icon(Symbols.content_paste, color: Colors.white.withOpacity(0.3), size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right Column - Stats Cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(context, 'Public Gateway', Symbols.public, vpnState.serverName ?? 'OFFLINE', 'ISP: DIRECT CONNECTION'),
                      _buildStatCard(context, 'Traffic (Session)', Symbols.data_usage, _mockTraffic.toStringAsFixed(2), 'MB', isProgress: isConnected),
                      _buildStatCard(context, 'Session Uptime', Symbols.timer, _uptime, isConnected ? 'ENCRYPTED CHANNEL ACTIVE' : 'ENCRYPTED CHANNEL IDLE'),
                      _buildStatCard(context, 'Active Tunnel', Symbols.security, isConnected ? 'VLESS' : 'NONE', isConnected ? 'AES-256-GCM READY' : 'WAITING FOR CONNECTION'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // Footer Stats Bar
            Row(
              children: [
                _buildFooterStat(context, 'UPSTREAM', isConnected ? '1.2 MB/s' : '0.0 B/s', Symbols.speed),
                const SizedBox(width: 16),
                _buildFooterStat(context, 'DOWNSTREAM', isConnected ? '4.5 MB/s' : '0.0 B/s', Symbols.download),
                const SizedBox(width: 16),
                _buildFooterStat(context, 'LATENCY', isConnected ? '42 ms' : '-- ms', Symbols.timer),
                const SizedBox(width: 16),
                _buildFooterStat(context, 'ENCRYPTION', isConnected ? 'AES-256-GCM' : 'DISABLED', null, showDot: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, IconData icon, String value, String subtitle, {bool isProgress = false}) {
    return GlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
              Icon(icon, color: Colors.white24, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32)),
                  if (isProgress) ...[
                    const SizedBox(width: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.white54)),
                  ],
                ],
              ),
              if (isProgress) ...[
                const SizedBox(height: 12),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.33,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.white24)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterStat(BuildContext context, String title, String value, IconData? icon, {bool showDot = false}) {
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: Center(
                child: showDot
                    ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle))
                    : Icon(icon, color: Colors.white54, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
