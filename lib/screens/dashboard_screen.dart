import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../widgets/glass_panel.dart';
import '../widgets/status_glow.dart';
import '../core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/vpn_provider.dart';
import '../providers/config_provider.dart';
import '../providers/traffic_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/premium_server_provider.dart';
import '../providers/subscription_provider.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final TextEditingController _vlessLinkController;

  @override
  void initState() {
    super.initState();
    _vlessLinkController = TextEditingController(text: ref.read(configProvider).vlessLink);
  }

  @override
  void dispose() {
    _vlessLinkController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final vpnState = ref.watch(vpnProvider);
    final isConnected = vpnState.connectionState == VpnConnectionState.connected;
    final isConnecting = vpnState.connectionState == VpnConnectionState.connecting;
    
    final configState = ref.watch(configProvider);
    final configNotifier = ref.read(configProvider.notifier);
    
    final trafficState = ref.watch(trafficProvider);
    ref.watch(premiumServerProvider);

    // Compute display values from real traffic data
    final totalTraffic = _formatBytes(trafficState.totalUplink + trafficState.totalDownlink);
    final tParts = totalTraffic.split(' ');
    final tValue = tParts[0];
    final tUnit = tParts.length > 1 ? tParts[1] : '';
    final uptimeStr = _formatDuration(trafficState.uptime);
    final upSpeedStr = _formatBytes(trafficState.uplinkSpeed);
    final downSpeedStr = _formatBytes(trafficState.downlinkSpeed);

    // Show error snackbar when VPN error occurs
    ref.listen<VpnState>(vpnProvider, (prev, next) {
      if (next.connectionState == VpnConnectionState.error && next.errorMessage != null) {
        if (prev?.connectionState != VpnConnectionState.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    // Sync controller text if provider state changed externally
    if (_vlessLinkController.text != configState.vlessLink) {
      _vlessLinkController.text = configState.vlessLink;
    }

    // Attempt to extract validity or set mock
    String validUntil = 'Нет ссылки';
    bool isSubscription = configState.vlessLink.startsWith('http');

    if (configState.vlessLink.isNotEmpty && (configState.vlessLink.startsWith('vless://') || configState.vlessLink.startsWith('vmess://'))) {
      validUntil = 'Активно (Конфиг)';
    } else if (isSubscription) {
      validUntil = 'Активно (Подписка)';
    } else if (configState.vlessLink.isNotEmpty) {
      validUntil = 'Неверный формат ссылки';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Dashboard',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(width: 16),
                        if (ref.watch(authProvider).isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.accent.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 12, color: AppTheme.accent),
                                const SizedBox(width: 4),
                                Text(
                                  'PREMIUM',
                                  style: TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Real-time secure connection monitoring.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.1),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (ref.read(authProvider).isAuthenticated) {
                          // Show profile / sign out
                          _showProfileDialog(context, ref);
                        } else {
                          context.push('/auth');
                        }
                      },
                      icon: Icon(
                        ref.watch(authProvider).isAuthenticated 
                          ? Icons.person_outline 
                          : Icons.login_outlined,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      tooltip: ref.watch(authProvider).isAuthenticated ? 'Profile' : 'Sign In',
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        configNotifier.setRoutingMode(!configState.isProxyMode);
                      },
                      child: GlassPanel(
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
                              child: Text('TUNNEL', style: TextStyle(color: !configState.isProxyMode ? Colors.black : Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                color: configState.isProxyMode ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text('PROXY', style: TextStyle(color: configState.isProxyMode ? Colors.black : Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      borderRadius: BorderRadius.circular(30),
                      child: Row(
                        children: [
                          Icon(Symbols.sensors, color: Colors.white.withValues(alpha: 0.6), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            vpnState.serverName ?? 'No Server Selected',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideX(begin: 0.1),
              ],
            ),
            const SizedBox(height: 40),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          child: _ConnectButton(
                            isConnected: isConnected,
                            isConnecting: isConnecting,
                            onTap: isConnecting ? null : () {
                              if (isConnected) {
                                ref.read(vpnProvider.notifier).disconnect();
                              } else {
                                ref.read(vpnProvider.notifier).connect(configState);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Symbols.event_available, size: 14, color: Colors.white54),
                            const SizedBox(width: 8),
                            Text('Ссылка действует до: $validUntil', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GlassPanel(
                          padding: const EdgeInsets.all(12),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                              Icon(Symbols.link, color: Colors.white.withValues(alpha: 0.3), size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _vlessLinkController,
                                  onChanged: (val) {
                                    configNotifier.setVlessLink(val);
                                    // Auto-add to subscriptions if it's a URL
                                    if (val.startsWith('http')) {
                                      ref.read(subscriptionProvider.notifier).addSubscription(
                                        'Main Subscription', 
                                        val.trim()
                                      );
                                    }
                                  },
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white, 
                                    fontSize: 11
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Вставьте VLESS ссылку сюда...',
                                    hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white30, fontSize: 11),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              Icon(Symbols.content_paste, color: Colors.white.withValues(alpha: 0.3), size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(width: 16),
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
                      _buildStatCard(context, 'Traffic (Session)', Symbols.data_usage, tValue, tUnit, isProgress: isConnected),
                      _buildStatCard(context, 'Session Uptime', Symbols.timer, uptimeStr, isConnected ? 'ENCRYPTED CHANNEL ACTIVE' : 'ENCRYPTED CHANNEL IDLE'),
                      _buildStatCard(context, 'Active Tunnel', Symbols.security, isConnected ? 'VLESS' : 'NONE', isConnected ? 'AES-256-GCM READY' : 'WAITING FOR CONNECTION'),
                    ],
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.05),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            Row(
              children: [
                _buildFooterStat(context, 'UPSTREAM', isConnected ? '$upSpeedStr/s' : '0.0 B/s', Symbols.speed),
                const SizedBox(width: 16),
                _buildFooterStat(context, 'DOWNSTREAM', isConnected ? '$downSpeedStr/s' : '0.0 B/s', Symbols.download),
                const SizedBox(width: 16),
                _buildFooterStat(context, 'LATENCY', isConnected ? '— ms' : '-- ms', Symbols.timer),
                const SizedBox(width: 16),
                _buildFooterStat(context, 'ENCRYPTION', isConnected ? 'AES-256-GCM' : 'DISABLED', null, showDot: true),
              ],
            ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, IconData icon, String value, String subtitle, {bool isProgress = false}) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall, overflow: TextOverflow.ellipsis),
              ),
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
                  Flexible(
                    child: Text(
                      value, 
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isProgress) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        subtitle, 
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, color: Colors.white54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (isProgress) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 30,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 10,
                      minY: 0,
                      maxY: 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            const FlSpot(0, 3),
                            const FlSpot(1, 4),
                            const FlSpot(2, 3.5),
                            const FlSpot(3, 5),
                            const FlSpot(4, 4),
                            const FlSpot(5, 7),
                            const FlSpot(6, 6),
                            const FlSpot(7, 8),
                            const FlSpot(8, 7.5),
                            const FlSpot(9, 9),
                            const FlSpot(10, 8.5),
                          ],
                          isCurved: true,
                          color: AppTheme.accent.withValues(alpha: 0.5),
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.accent.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
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
  
  void _showProfileDialog(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${authState.profile?.email ?? authState.authUser?.email}', 
              style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Status: ${authState.isPremium ? "Premium" : "Free"}', 
              style: TextStyle(color: authState.isPremium ? Colors.amber : Colors.white54)),
            if (authState.profile?.expiryDate != null) ...[
              const SizedBox(height: 8),
              Text('Expires: ${authState.profile!.expiryDate!.toLocal().toString().split(' ')[0]}', 
                style: const TextStyle(color: Colors.white54)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.pop(context);
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ConnectButton extends StatefulWidget {
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback? onTap;

  const _ConnectButton({
    required this.isConnected,
    required this.isConnecting,
    this.onTap,
  });

  @override
  State<_ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<_ConnectButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(100),
        child: StatusGlow(
          animate: widget.isConnected || widget.isConnecting,
          color: widget.isConnected ? AppTheme.accent : (widget.isConnecting ? Colors.white : Colors.white24),
          child: AnimatedScale(
            scale: _isHovered ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isConnected ? AppTheme.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: widget.isConnected ? AppTheme.accent.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  widget.isConnecting
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Icon(
                        widget.isConnected ? Symbols.shield_with_heart : Symbols.power_settings_new,
                        size: 48,
                        color: widget.isConnected ? AppTheme.accent : Colors.white.withValues(alpha: 0.4),
                        weight: 300,
                        fill: widget.isConnected ? 1 : 0,
                      ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isConnected ? 'SECURED' : (widget.isConnecting ? 'CONNECTING' : 'DISCONNECTED'),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 14,
                      letterSpacing: 4,
                      color: widget.isConnected ? AppTheme.accent : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
